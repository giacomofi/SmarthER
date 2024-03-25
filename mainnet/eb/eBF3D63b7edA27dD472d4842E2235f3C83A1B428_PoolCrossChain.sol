// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/DSMath.sol";
import "../interfaces/IPriceOracleGetter.sol";
import "../asset/Asset.sol";
import "./Core.sol";
import "../interfaces/IPoolCrossChain.sol";
import "../interfaces/IFeeCollector.sol";

import ".././interfaces/ICSMCrossChainRouter.sol";

/**
 * @title Pool
 * @notice Manages deposits, withdrawals and swaps. Holds a mapping of assets and parameters.
 * @dev The main entry-point of Cashmere protocol
 *
 * Note The Pool is ownable and the owner wields power.
 * Note The ownership will be transferred to a governance contract once Cashmere community can show to govern itself.
 *
 * The unique features of the Cashmere make it an important subject in the study of evolutionary biology.
 * + Added recover user funds (for funds mistakingly sent to this contract)
 * + Added view function for eqCovRatio
 */
contract PoolCrossChain is Ownable, ReentrancyGuard, Pausable, Core, IPoolCrossChain {
    using DSMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Asset Map struct holds assets
    struct AssetMap {
        address[] keys;
        mapping(address => IAsset) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    /// @notice Wei in 1 ether
    uint256 private constant ETH_UNIT = 10**18;

    /// @notice Slippage parameters K, N, C1 and xThreshold
    uint256 public slippageParamK;
    uint256 public slippageParamN;
    uint256 public c1;
    uint256 public xThreshold;

    /// @notice Haircut rate
    uint256 public haircutRate;

    /// @notice Retention ratio
    uint256 public retentionRatio;

    /// @notice Maximum price deviation
    /// @dev states the maximum price deviation allowed between assets
    uint256 public maxPriceDeviation;

    /// @notice Dev address
    address public dev;

    /// @notice The price oracle interface used in swaps
    IPriceOracleGetter public priceOracle;

    /// @notice Fee collector
    IFeeCollector public feeCollector;

    /// @notice A record of assets inside Pool
    AssetMap private _assets;

    /// @notice Router for cross-chain swaps
    ICSMCrossChainRouter public router;

    /// @notice Chain id of deployed contract
    uint256 public immutable chainId;

    mapping(uint256 => uint256) private _noncePerChain;

    /// @notice An event emitted when an asset is added to Pool
    event AssetAdded(address indexed token, address indexed asset);

    /// @notice An event emitted when a deposit is made to Pool
    event Deposit(address indexed sender, address token, uint256 amount, uint256 liquidity, address indexed to);

    /// @notice An event emitted when a withdrawal is made from Pool
    event Withdraw(address indexed sender, address token, uint256 amount, uint256 liquidity, address indexed to);

    /// @notice An event emitted when dev is updated
    event DevUpdated(address indexed previousDev, address indexed newDev);

    /// @notice An event emitted when oracle is updated
    event OracleUpdated(address indexed previousOracle, address indexed newOracle);

    /// @notice An event emitted when fee collector is updated
    event FeeCollectorUpdated(address indexed previousCollector, address indexed newCollector);

    /// @notice An event emitted when price deviation is updated
    event PriceDeviationUpdated(uint256 previousPriceDeviation, uint256 newPriceDeviation);

    /// @notice An event emitted when router is updated
    event RouterUpdated(ICSMCrossChainRouter oldRouter, ICSMCrossChainRouter newRouter);

    /// @notice An event emitted when slippage params are updated
    event SlippageParamsUpdated(
        uint256 previousK,
        uint256 newK,
        uint256 previousN,
        uint256 newN,
        uint256 previousC1,
        uint256 newC1,
        uint256 previousXThreshold,
        uint256 newXThreshold
    );

    /// @notice An event emitted when haircut is updated
    event HaircutRateUpdated(uint256 previousHaircut, uint256 newHaircut);

    /// @notice An event emitted when retention ratio is updated
    event RetentionRatioUpdated(uint256 previousRetentionRatio, uint256 newRetentionRatio);

    /// @notice An event emitted when a swap is made in Pool
    event Swap(
        address indexed sender,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address indexed to
    );

    /// @notice An event emitted when a swap crosschain is made in Pool
    event CrossChainSwap(
        address indexed sender,
        address srcAsset,
        address dstAsset,
        uint256 chainId,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 nonce
    );

    /// @dev Modifier ensuring that certain function can only be called by developer
    modifier onlyDev() {
        require(dev == msg.sender, "FORBIDDEN");
        _;
    }

    /// @dev Modifier ensuring a certain deadline for a function to complete execution
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == address(router), "NOT_AUTHORIZED");
        _;
    }

    /**
     * @notice Initializes pool. Dev is set to be the account calling this function.
     */
    constructor() {
        // constructor(uint256 chainId_) {
        // set variables
        slippageParamK = 0.00002e18; //2 * 10**13 == 0.00002 * WETH
        slippageParamN = 7; // 7
        c1 = 376927610599998308; // ((k**(1/(n+1))) / (n**((n)/(n+1)))) + (k*n)**(1/(n+1))
        xThreshold = 329811659274998519; // (k*n)**(1/(n+1))
        haircutRate = 0.0004e18; // 4 * 10**14 == 0.0004 == 0.04% for intra-aggregate account swap
        retentionRatio = ETH_UNIT; // 1
        maxPriceDeviation = 0.02e18; // 2 * 10**16 == 2% = 0.02 in ETH_UNIT.

        // set dev
        dev = msg.sender;

        // chainId = chainId_;
        chainId = block.chainid;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyDev {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyDev {
        _unpause();
    }

    // Setters //
    /**
     * @notice Changes the contract dev. Can only be set by the contract owner.
     * @param dev_ new contract dev address
     */
    function setDev(address dev_) external onlyOwner {
        require(dev_ != address(0), "ZERO");
        emit DevUpdated(dev, dev_);
        dev = dev_;
    }

    function setRouter(ICSMCrossChainRouter router_) external onlyOwner {
        require(address(router_) != address(0), "ZERO");
        emit RouterUpdated(router, router_);
        router = router_;
    }

    /**
     * @notice Changes the pools slippage params. Can only be set by the contract owner.
     * @param k_ new pool's slippage param K
     * @param n_ new pool's slippage param N
     * @param c1_ new pool's slippage param C1
     * @param xThreshold_ new pool's slippage param xThreshold
     */
    function setSlippageParams(
        uint256 k_,
        uint256 n_,
        uint256 c1_,
        uint256 xThreshold_
    ) external onlyOwner {
        require(k_ <= ETH_UNIT); // k should not be set bigger than 1
        require(n_ > 0); // n should be bigger than 0

        emit SlippageParamsUpdated(slippageParamK, k_, slippageParamN, n_, c1, c1_, xThreshold, xThreshold_);

        slippageParamK = k_;
        slippageParamN = n_;
        c1 = c1_;
        xThreshold = xThreshold_;
    }

    /**
     * @notice Changes the pools haircutRate. Can only be set by the contract owner.
     * @param haircutRate_ new pool's haircutRate_
     */
    function setHaircutRate(uint256 haircutRate_) external onlyOwner {
        require(haircutRate_ <= ETH_UNIT); // haircutRate_ should not be set bigger than 1
        emit HaircutRateUpdated(haircutRate, haircutRate_);
        haircutRate = haircutRate_;
    }

    /**
     * @notice Changes the pools retentionRatio. Can only be set by the contract owner.
     * @param retentionRatio_ new pool's retentionRatio
     */
    function setRetentionRatio(uint256 retentionRatio_) external onlyOwner {
        require(retentionRatio_ <= ETH_UNIT); // retentionRatio_ should not be set bigger than 1
        emit RetentionRatioUpdated(retentionRatio, retentionRatio_);
        retentionRatio = retentionRatio_;
    }

    /**
     * @notice Changes the pools maxPriceDeviation. Can only be set by the contract owner.
     * @param maxPriceDeviation_ new pool's maxPriceDeviation
     */
    function setMaxPriceDeviation(uint256 maxPriceDeviation_) external onlyOwner {
        require(maxPriceDeviation_ <= ETH_UNIT); // maxPriceDeviation_ should not be set bigger than 1
        emit PriceDeviationUpdated(maxPriceDeviation, maxPriceDeviation_);
        maxPriceDeviation = maxPriceDeviation_;
    }

    /**
     * @notice Changes the pools priceOracle. Can only be set by the contract owner.
     * @param priceOracle_ new pool's priceOracle address
     */
    function setPriceOracle(address priceOracle_) external onlyOwner {
        require(priceOracle_ != address(0), "ZERO");
        emit OracleUpdated(address(priceOracle), priceOracle_);
        priceOracle = IPriceOracleGetter(priceOracle_);
    }

    /**
     * @notice Changes the pools feeCollector. Can only be set by the contract owner.
     * @param feeCollector_ new pool's feeCollector address
     */
    function setFeeCollector(address feeCollector_) external onlyOwner {
        require(feeCollector_ != address(0), "ZERO");
        emit FeeCollectorUpdated(address(feeCollector), feeCollector_);
        feeCollector = IFeeCollector(feeCollector_);
    }

    // Asset struct functions //

    /**
     * @notice Gets asset with token address key
     * @param key The address of token
     * @return the corresponding asset in state
     */
    function _getAsset(address key) private view returns (IAsset) {
        return _assets.values[key];
    }

    /**
     * @notice Gets key (address) at index
     * @param index the index
     * @return the key of index
     */
    function _getKeyAtIndex(uint256 index) private view returns (address) {
        return _assets.keys[index];
    }

    /**
     * @notice get length of asset list
     * @return the size of the asset list
     */
    function _sizeOfAssetList() private view returns (uint256) {
        return _assets.keys.length;
    }

    /**
     * @notice Looks if the asset is contained by the list
     * @param key The address of token to look for
     * @return bool true if the asset is in asset list, false otherwise
     */
    function _containsAsset(address key) private view returns (bool) {
        return _assets.inserted[key];
    }

    /**
     * @notice Looks if the asset is contained by the list
     * @param key The address of token to look for
     * @return bool true if the asset is in asset list, false otherwise
     */
    function containsAsset(address key) external view returns (bool) {
        return _containsAsset(key);
    }

    /**
     * @notice Adds asset to the list
     * @param key The address of token to look for
     * @param val The asset to add
     */
    function _addAsset(address key, IAsset val) private {
        if (_assets.inserted[key]) {
            _assets.values[key] = val;
        } else {
            _assets.inserted[key] = true;
            _assets.values[key] = val;
            _assets.indexOf[key] = _assets.keys.length;
            _assets.keys.push(key);
        }
    }

    /**
     * @notice Removes asset from asset struct
     * @dev Can only be called by owner
     * @param key The address of token to remove
     */
    function removeAsset(address key) external onlyOwner {
        if (!_assets.inserted[key]) {
            return;
        }

        delete _assets.inserted[key];
        delete _assets.values[key];

        uint256 index = _assets.indexOf[key];
        uint256 lastIndex = _assets.keys.length - 1;
        address lastKey = _assets.keys[lastIndex];

        _assets.indexOf[lastKey] = index;
        delete _assets.indexOf[key];

        _assets.keys[index] = lastKey;
        _assets.keys.pop();
    }

    // Pool Functions //
    /**
     * @notice Checks deviation is not higher than specified amount
     * @dev Reverts if deviation is higher than maxPriceDeviation
     * @param tokenA First token
     * @param tokenB Second token
     */
    function _checkPriceDeviation(address tokenA, address tokenB) private view {
        uint256 tokenAPrice = priceOracle.getAssetPrice(tokenA);
        uint256 tokenBPrice = priceOracle.getAssetPrice(tokenB);

        // check if prices respect their maximum deviation for a > b : (a - b) / a < maxDeviation
        if (tokenBPrice > tokenAPrice) {
            require((((tokenBPrice - tokenAPrice) * ETH_UNIT) / tokenBPrice) <= maxPriceDeviation, "PRICE_DEV");
        } else {
            require((((tokenAPrice - tokenBPrice) * ETH_UNIT) / tokenAPrice) <= maxPriceDeviation, "PRICE_DEV");
        }
    }

    /**
     * @notice gets system equilibrium coverage ratio
     * @dev [ sum of Ai * fi / sum Li * fi ]
     * @return equilibriumCoverageRatio system equilibrium coverage ratio
     */
    function getEquilibriumCoverageRatio() external view returns (uint256) {
        return _getEquilibriumCoverageRatio();
    }

    /**
     * @notice gets system equilibrium coverage ratio
     * @dev [ sum of Ai * fi / sum Li * fi ]
     * @return equilibriumCoverageRatio system equilibrium coverage ratio
     */
    function _getEquilibriumCoverageRatio() private view returns (uint256) {
        uint256 totalCash = 0;
        uint256 totalLiability = 0;

        // loop on assets
        for (uint256 i; i < _sizeOfAssetList(); ++i) {
            // get token address
            address assetAddress = _getKeyAtIndex(i);

            // get token oracle price
            uint256 tokenPrice = priceOracle.getAssetPrice(assetAddress);

            // used to convert cash and liabilities into ETH_UNIT to have equal decimals accross all assets
            uint256 offset = 10**(18 - _getAsset(assetAddress).decimals());

            totalCash += (_getAsset(assetAddress).cash() * offset * tokenPrice);
            totalLiability += (_getAsset(assetAddress).liability() * offset * tokenPrice);
        }

        // if there are no liabilities or no assets in the pool, return equilibrium state = 1
        if (totalLiability == 0 || totalCash == 0) {
            return ETH_UNIT;
        }

        return totalCash.wdiv(totalLiability);
    }

    /**
     * @notice Adds asset to pool, reverts if asset already exists in pool
     * @param token The address of token
     * @param asset The address of the cashmere Asset contract
     */
    function addAsset(address token, address asset) external onlyOwner {
        require(token != address(0), "ZERO");
        require(asset != address(0), "ZERO");
        require(!_containsAsset(token), "ASSET_EXISTS");

        _addAsset(token, IAsset(asset));

        emit AssetAdded(token, asset);
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Pool.
     * @param token The address of ERC20 token
     */
    function _assetOf(address token) private view returns (IAsset) {
        require(_containsAsset(token), "ASSET_NOT_EXIST");
        return _getAsset(token);
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Pool.
     * @dev to be used externally
     * @param token The address of ERC20 token
     */
    function assetOf(address token) external view override returns (address) {
        return address(_assetOf(token));
    }

    /**
     * @notice Deposits asset in Pool
     * @param asset The asset to be deposited
     * @param amount The amount to be deposited
     * @param to The user accountable for deposit, receiving the cashmere assets (lp)
     * @return liquidity Total asset liquidity minted
     */
    function _deposit(
        IAsset asset,
        uint256 amount,
        address to
    ) private returns (uint256 liquidity) {
        uint256 totalSupply = asset.totalSupply();
        uint256 liability = asset.liability();

        uint256 fee = _depositFee(slippageParamK, slippageParamN, c1, xThreshold, asset.cash(), liability, amount);

        // Calculate amount of LP to mint : ( deposit - fee ) * TotalAssetSupply / Liability
        if (liability == 0) {
            liquidity = amount - fee;
        } else {
            liquidity = ((amount - fee) * totalSupply) / liability;
        }

        // get equilibrium coverage ratio
        uint256 eqCov = _getEquilibriumCoverageRatio();

        // apply impairment gain if eqCov < 1
        if (eqCov < ETH_UNIT) {
            liquidity = liquidity.wdiv(eqCov);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQ_MINT");

        asset.addCash(amount);
        asset.addLiability(amount - fee);
        asset.mint(to, liquidity);

        if (fee > 0 && address(feeCollector) != address(0)) {
            feeCollector.collectFees(asset, fee);
        }
    }

    /**
     * @notice Deposits amount of tokens into pool ensuring deadline
     * @dev Asset needs to be created and added to pool before any operation
     * @param token The token address to be deposited
     * @param amount The amount to be deposited
     * @param to The user accountable for deposit, receiving the cashmere assets (lp)
     * @param deadline The deadline to be respected
     * @return liquidity Total asset liquidity minted
     */
    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant whenNotPaused returns (uint256 liquidity) {
        require(amount > 0, "ZERO_AMOUNT");
        require(token != address(0), "ZERO");
        require(to != address(0), "ZERO");

        IERC20 erc20 = IERC20(token);
        IAsset asset = _assetOf(token);

        liquidity = _deposit(asset, amount, to);
        erc20.safeTransferFrom(address(msg.sender), address(asset), amount);

        emit Deposit(msg.sender, token, amount, liquidity, to);
    }

    /**
     * @notice Calculates fee and liability to burn in case of withdrawal
     * @param asset The asset willing to be withdrawn
     * @param liquidity The liquidity willing to be withdrawn
     * @return amount Total amount to be withdrawn from Pool
     * @return liabilityToBurn Total liability to be burned by Pool
     * @return fee The fee of the withdraw operation
     */
    function _withdrawFrom(IAsset asset, uint256 liquidity)
        private
        view
        returns (
            uint256 amount,
            uint256 liabilityToBurn,
            uint256 fee,
            bool enoughCash
        )
    {
        liabilityToBurn = (asset.liability() * liquidity) / asset.totalSupply();
        require(liabilityToBurn > 0, "INSUFFICIENT_LIQ_BURN");

        fee = _withdrawalFee(
            slippageParamK,
            slippageParamN,
            c1,
            xThreshold,
            asset.cash(),
            asset.liability(),
            liabilityToBurn
        );

        // Get equilibrium coverage ratio before withdraw
        uint256 eqCov = _getEquilibriumCoverageRatio();

        // Init enoughCash to true
        enoughCash = true;

        // Apply impairment in the case eqCov < 1
        uint256 amountAfterImpairment;
        if (eqCov < ETH_UNIT) {
            amountAfterImpairment = (liabilityToBurn).wmul(eqCov);
        } else {
            amountAfterImpairment = liabilityToBurn;
        }

        // Prevent underflow in case withdrawal fees >= liabilityToBurn, user would only burn his underlying liability
        if (amountAfterImpairment > fee) {
            amount = amountAfterImpairment - fee;

            // If not enough cash
            if (asset.cash() < amount) {
                amount = asset.cash(); // When asset does not contain enough cash, just withdraw the remaining cash
                fee = 0;
                enoughCash = false;
            }
        } else {
            fee = amountAfterImpairment; // fee overcomes the amount to withdraw. User would be just burning liability
            amount = 0;
            enoughCash = false;
        }
    }

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param asset The asset to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @return amount The total amount withdrawn
     */
    function _withdraw(
        IAsset asset,
        uint256 liquidity,
        uint256 minimumAmount,
        address to
    ) private returns (uint256 amount) {
        // calculate liabilityToBurn and Fee
        uint256 liabilityToBurn;
        uint256 fee;
        (amount, liabilityToBurn, fee, ) = _withdrawFrom(asset, liquidity);

        require(minimumAmount <= amount, "AMOUNT_TOO_LOW");

        asset.burn(msg.sender, liquidity);
        asset.removeCash(amount);
        asset.removeLiability(liabilityToBurn);
        asset.transferUnderlyingToken(to, amount);

        if (fee > 0 && address(feeCollector) != address(0)) {
            feeCollector.collectFees(asset, fee);
        }
    }

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param token The token to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @return amount The total amount withdrawn
     */
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant whenNotPaused returns (uint256 amount) {
        require(liquidity > 0, "ZERO_ASSET_AMOUNT");
        require(token != address(0), "ZERO");
        require(to != address(0), "ZERO");

        IAsset asset = _assetOf(token);

        amount = _withdraw(asset, liquidity, minimumAmount, to);

        emit Withdraw(msg.sender, token, amount, liquidity, to);
    }

    /**
     * @notice Enables withdrawing liquidity from an asset using LP from a different asset in the same aggregate
     * @param initialToken The corresponding token user holds the LP (Asset) from
     * @param wantedToken The token wanting to be withdrawn (needs to be well covered)
     * @param liquidity The liquidity to be withdrawn (in wanted token d.p.)
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @dev initialToken and wantedToken assets' must be in the same aggregate
     * @dev Also, cov of wantedAsset must be higher than 1 after withdrawal for this to be accepted
     * @return amount The total amount withdrawn
     */
    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external override ensure(deadline) nonReentrant whenNotPaused returns (uint256 amount) {
        require(liquidity > 0, "ZERO_ASSET_AMOUNT");
        require(wantedToken != address(0), "ZERO");
        require(initialToken != address(0), "ZERO");
        require(to != address(0), "ZERO");

        // get corresponding assets
        IAsset initialAsset = _assetOf(initialToken);
        IAsset wantedAsset = _assetOf(wantedToken);

        // assets need to be in the same aggregate in order to allow for withdrawing other assets
        require(wantedAsset.aggregateAccount() == initialAsset.aggregateAccount(), "DIFF_AGG_ACC");

        // check if price deviation is OK between assets
        _checkPriceDeviation(initialToken, wantedToken);

        // Convert liquidity to d.p of initial asset
        uint256 liquidityInInitialAssetDP = (liquidity * 10**initialAsset.decimals()) / (10**wantedAsset.decimals());

        // require liquidity in initial asset dp to be > 0
        require(liquidityInInitialAssetDP > 0, "DUST?");

        // request lp token from user
        IERC20(initialAsset).safeTransferFrom(address(msg.sender), address(initialAsset), liquidityInInitialAssetDP);

        // calculate liabilityToBurn and amount
        bool enoughCash;
        uint256 fee;
        (amount, , fee, enoughCash) = _withdrawFrom(wantedAsset, liquidity);

        // If not enough cash in wanted asset, revert
        require(enoughCash, "NOT_ENOUGH_CASH");

        // require after withdrawal coverage to >= 1
        require((wantedAsset.cash() - amount).wdiv(wantedAsset.liability()) >= ETH_UNIT, "COV_RATIO_LOW");

        // require amount to be higher than the amount specified
        require(minimumAmount <= amount, "AMOUNT_TOO_LOW");

        // calculate liability to burn in initialAsset
        uint256 liabilityToBurn = (initialAsset.liability() * liquidityInInitialAssetDP) / initialAsset.totalSupply();

        // burn initial asset recovered liquidity
        initialAsset.burn(address(initialAsset), liquidityInInitialAssetDP);
        initialAsset.removeLiability(liabilityToBurn); // remove liability from initial asset
        wantedAsset.removeCash(amount); // remove cash from wanted asset
        wantedAsset.transferUnderlyingToken(to, amount); // transfer wanted token to user

        if (fee > 0 && address(feeCollector) != address(0)) {
            feeCollector.collectFees(wantedAsset, fee);
        }

        emit Withdraw(msg.sender, wantedToken, amount, liquidityInInitialAssetDP, to);
    }

    function swapCrossChain(
        address fromToken_,
        uint256 fromAmount_,
        uint256 minimumToAmount_,
        uint256 dstAssetId_,
        uint256 dstChain_,
        uint256 deadline_,
        uint256 executionFee_
    )
        external
        payable
        override
        ensure(deadline_)
        nonReentrant
        whenNotPaused
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(fromToken_ != address(0), "ZERO");
        require(fromAmount_ > 0, "ZERO_FROM_AMOUNT");
        require(router.isApprovedAsset(dstChain_, dstAssetId_), "DEST_CHAIN_NOT_APPROVED");

        ICSMCrossChainRouter.CrossChainParams memory params = _settleBalances(
            fromToken_,
            fromAmount_,
            dstAssetId_,
            dstChain_
        );

        require(minimumToAmount_ <= params.actualToAmount, "AMOUNT_TOO_LOW");

        router.modifyCrossChainParams(dstChain_, dstAssetId_, params.toAsset.cash, params.toAsset.liability);
        params.nonce = _noncePerChain[dstChain_]++;

        params.payload = abi.encodeWithSelector(
            ICSMCrossChainRouter.routerReceive.selector,
            msg.sender,
            params.fromAsset.nativeAssetAddress,
            params.toAsset.nativeAssetAddress,
            params.actualToAmount,
            params.haircut,
            params.nonce
        );

        router.route{ value: msg.value }(dstChain_, params.toAsset.nativeAssetAddress, params.payload, executionFee_);

        emit CrossChainSwap(
            msg.sender,
            params.fromAsset.nativeAssetAddress,
            params.toAsset.nativeAssetAddress,
            dstChain_,
            fromAmount_,
            params.actualToAmount,
            params.nonce
        );
        return (params.actualToAmount, params.haircut, params.nonce);
    }

    function receiveSwapCrossChain(
        address sender_,
        uint256 srcChainId_,
        address srcAsset_,
        address dstAsset_,
        uint256 amount_,
        uint256 haircut_,
        uint256 nonce_
    ) external override onlyRouter {
        require(srcAsset_ != address(0), "ZERO_SRC_ADDR");
        require(dstAsset_ != address(0), "ZERO_DST_ADDR");
        require(amount_ > 0, "ZERO_FROM_AMOUNT");
        require(router.isApprovedAsset(chainId, dstAsset_), "DST_ASSET_NOT_APPROVED");

        ICSMCrossChainRouter.CrossChainAsset memory srcAsset = router.getAssetData(srcChainId_, srcAsset_);
        IAsset dstAsset = IAsset(dstAsset_);

        srcAsset.cash += amount_;
        router.modifyCrossChainParams(
            srcChainId_,
            router.getApprovedAssetId(srcAsset_, srcChainId_),
            srcAsset.cash,
            srcAsset.liability
        );

        dstAsset.removeCash(amount_);
        dstAsset.addLiability(_dividend(haircut_, retentionRatio));
        dstAsset.transferUnderlyingToken(sender_, amount_);

        if (haircut_ > 0) {
            feeCollector.collectFees(dstAsset, haircut_);
        }

        emit CrossChainSwap(sender_, srcAsset_, dstAsset_, srcChainId_, amount_, amount_, nonce_);
    }

    function _settleBalances(
        address fromToken_,
        uint256 fromAmount_,
        uint256 dstAssetId_,
        uint256 dstChain_
    ) private returns (ICSMCrossChainRouter.CrossChainParams memory) {
        IERC20 fromERC20 = IERC20(fromToken_);
        IAsset fromAsset = _assetOf(fromToken_);

        require(router.isApprovedAsset(chainId, address(fromAsset)), "SRC_CHAIN_NOT_APPROVED");

        ICSMCrossChainRouter.CrossChainParams memory params;

        params.fromAsset = router.getAssetData(chainId, address(fromAsset));
        params.toAsset = router.getAssetData(dstChain_, dstAssetId_);

        (params.actualToAmount, params.haircut) = _quoteFrom(fromAsset, params.toAsset, fromAmount_);
        fromERC20.safeTransferFrom(address(msg.sender), address(fromAsset), fromAmount_);
        fromAsset.addCash(fromAmount_);

        params.toAsset.cash -= params.actualToAmount;
        params.toAsset.liability -= _dividend(params.haircut, retentionRatio);
        return params;
    }

    /**
     * @notice Quotes the actual amount user would receive in a swap, taking in account slippage and haircut
     * @param fromAsset The initial asset
     * @param toAsset The asset wanted by user
     * @param fromAmount The amount to quote
     * @return actualToAmount The actual amount user would receive
     * @return haircut The haircut that will be applied
     */
    function _quoteFrom(
        IAsset fromAsset,
        ICSMCrossChainRouter.CrossChainAsset memory toAsset,
        uint256 fromAmount
    ) private view returns (uint256 actualToAmount, uint256 haircut) {
        uint256 idealToAmount = _quoteIdealToAmount(fromAsset, toAsset, fromAmount);

        require(toAsset.cash >= idealToAmount, "INSUFFICIENT_CASH");

        uint256 slippageFrom = _slippage(
            slippageParamK,
            slippageParamN,
            c1,
            xThreshold,
            fromAsset.cash(),
            fromAsset.liability(),
            fromAmount,
            true
        );
        uint256 slippageTo = _slippage(
            slippageParamK,
            slippageParamN,
            c1,
            xThreshold,
            toAsset.cash,
            toAsset.liability,
            idealToAmount,
            false
        );
        uint256 swappingSlippage = _swappingSlippage(slippageFrom, slippageTo);
        uint256 toAmount = idealToAmount.wmul(swappingSlippage);
        haircut = _haircut(toAmount, haircutRate);
        actualToAmount = toAmount - haircut;
    }

    /**
     * @notice Quotes the ideal amount in case of swap
     * @dev Does not take into account slippage parameters nor haircut
     * @param fromAsset The initial asset
     * @param toCrossChainAsset The crosschain asset wanted by user
     * @param fromAmount The amount to quote
     * @return idealToAmount The ideal amount user would receive
     */
    function _quoteIdealToAmount(
        IAsset fromAsset,
        ICSMCrossChainRouter.CrossChainAsset memory toCrossChainAsset,
        uint256 fromAmount
    ) private view returns (uint256 idealToAmount) {
        // check deviation is not higher than specified amount
        _checkPriceDeviation(fromAsset.underlyingToken(), toCrossChainAsset.nativeTokenAddress);

        // assume perfect peg between assets
        idealToAmount = ((fromAmount * 10**toCrossChainAsset.decimals) / 10**fromAsset.decimals());
    }

    /**
     * @notice Quotes potential outcome of a swap given current state, taking in account slippage and haircut
     * @dev To be used by frontend
     * @param fromToken The initial ERC20 token
     * @param toToken The token wanted by user
     * @param fromAmount The amount to quote
     * @return potentialOutcome The potential amount user would receive
     * @return haircut The haircut that would be applied
     */
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 destinationAsset,
        uint256 destinationChain
    ) external view override whenNotPaused returns (uint256 potentialOutcome, uint256 haircut) {
        require(fromToken != address(0), "ZERO");
        require(toToken != address(0), "ZERO");
        require(fromToken != toToken, "SAME_ADDRESS");
        require(fromAmount > 0, "ZERO_FROM_AMOUNT");

        IAsset fromAsset = _assetOf(fromToken);
        ICSMCrossChainRouter.CrossChainAsset memory crossChainAsset = router.getAssetData(
            destinationChain,
            destinationAsset
        );

        (potentialOutcome, haircut) = _quoteFrom(fromAsset, crossChainAsset, fromAmount);
    }

    /**
     * @notice Quotes potential withdrawal from pool
     * @dev To be used by frontend
     * @param token The token to be withdrawn by user
     * @param liquidity The liquidity (amount of lp assets) to be withdrawn
     * @return amount The potential amount user would receive
     * @return fee The fee that would be applied
     * @return enoughCash does the pool have enough cash? (cash >= liabilityToBurn - fee)
     */
    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        override
        whenNotPaused
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        )
    {
        require(token != address(0), "ZERO");
        require(liquidity > 0, "LIQ=0");

        IAsset asset = _assetOf(token);
        (amount, , fee, enoughCash) = _withdrawFrom(asset, liquidity);
    }

    /**
     * @notice Quotes potential withdrawal from other asset in the same aggregate
     * @dev To be used by frontend. Reverts if not possible
     * @param initialToken The users holds LP corresponding to this initial token
     * @param wantedToken The token to be withdrawn by user
     * @param liquidity The liquidity (amount of lp assets) to be withdrawn (in wanted token dp).
     * @return amount The potential amount user would receive
     * @return fee The fee that would be applied
     */
    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view whenNotPaused returns (uint256 amount, uint256 fee) {
        require(initialToken != address(0), "ZERO");
        require(wantedToken != address(0), "ZERO");
        require(liquidity > 0, "LIQ=0");

        IAsset initialAsset = _assetOf(initialToken);
        IAsset wantedAsset = _assetOf(wantedToken);

        require(wantedAsset.aggregateAccount() == initialAsset.aggregateAccount(), "DIFF_AGG_ACC");

        bool enoughCash;
        (amount, , fee, enoughCash) = _withdrawFrom(wantedAsset, liquidity);

        require(enoughCash, "NOT_ENOUGH_CASH");

        // require after withdrawal coverage to >= 1
        require((wantedAsset.cash() - amount).wdiv(wantedAsset.liability()) >= ETH_UNIT, "COV_RATIO_LOW");
    }

    /// @notice Gets max withdrawable amount in initial token
    /// @notice Taking into account that coverage must be over > 1 in wantedAsset
    /// @param initialToken the initial token to be evaluated
    /// @param wantedToken the wanted token to withdraw in
    /// @return maxInitialAssetAmount the maximum amount of initial asset that can be used to withdraw
    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        whenNotPaused
        returns (uint256 maxInitialAssetAmount)
    {
        _checkPriceDeviation(initialToken, wantedToken);

        IAsset initialAsset = _assetOf(initialToken);
        IAsset wantedAsset = _assetOf(wantedToken);

        uint256 wantedAssetCov = (wantedAsset.cash()).wdiv(wantedAsset.liability());

        if (wantedAssetCov > ETH_UNIT) {
            maxInitialAssetAmount =
                ((wantedAssetCov - ETH_UNIT).wmul(wantedAsset.totalSupply()) * 10**initialAsset.decimals()) /
                10**wantedAsset.decimals();
        } else {
            maxInitialAssetAmount = 0;
        }
    }

    /**
     * @notice Gets addresses of underlying token in pool
     * @dev To be used externally
     * @return addresses of assets in the pool
     */
    function getTokenAddresses() external view override returns (address[] memory) {
        return _assets.keys;
    }

    /**
     * @notice Recover any funds mistakingly sent to this contract
     * @param token the address of the token to retrieve
     */
    function recoverUserFunds(address token) external onlyDev {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, currentBalance);
    }

    function getNoncePerChain(uint256 chainId_) external view override returns (uint256) {
        return _noncePerChain[chainId_];
    }
}

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library DSMath {
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    function reciprocal(uint256 x) internal pure returns (uint256) {
        return wdiv(WAD, x);
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (RAY / 2)) / RAY;
    }
}

// Based on AAVE protocol
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IPriceOracleGetter interface
interface IPriceOracleGetter {
    /// @dev returns the asset price in ETH
    function getAssetPrice(address _asset) external view returns (uint256);

    /// @dev returns the reciprocal of asset price
    function getAssetPriceReciprocal(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../libraries/DSMath.sol";

/**
 * @title Core
 * @notice Handles math operations of Cashmere protocol.
 * @dev Uses DSMath to compute using WAD and RAY.
 */
contract Core {
    using DSMath for uint256;

    /// @notice WAD unit. Used to handle most numbers.
    uint256 internal constant WAD = 10**18;

    /// @notice RAY unit. Used for rpow function.
    uint256 internal constant RAY = 10**27;

    /// @notice Accommodates unforeseen upgrades to Core.
    bytes32[64] internal emptyArray;

    /**
     * @notice Yellow Paper Def. 2.4 (Price Slippage Curve)
     * @dev Calculates g(xr,i) or g(xr,j). This function always returns >= 0
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param x coverage ratio of asset in WAD
     * @return The result of price slippage curve
     */
    function _slippageFunc(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 x
    ) internal pure returns (uint256) {
        if (x < xThreshold) {
            return c1 - x;
        } else {
            return k.wdiv((((x * RAY) / WAD).rpow(n) * WAD) / RAY); // k / (x ** n)
        }
    }

    /**
     * @notice Yellow Paper Def. 2.4 (Asset Slippage)
     * @dev Calculates -Si or -Sj (slippage from and slippage to)
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param cash cash position of asset in WAD
     * @param cashChange cashChange of asset in WAD
     * @param addCash true if we are adding cash, false otherwise
     * @return The result of one-sided asset slippage
     */
    function _slippage(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 cashChange,
        bool addCash
    ) internal pure returns (uint256) {
        uint256 covBefore = cash.wdiv(liability);
        uint256 covAfter;
        if (addCash) {
            covAfter = (cash + cashChange).wdiv(liability);
        } else {
            covAfter = (cash - cashChange).wdiv(liability);
        }

        // if cov stays unchanged, slippage is 0
        if (covBefore == covAfter) {
            return 0;
        }

        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);

        if (covBefore > covAfter) {
            return (slippageAfter - slippageBefore).wdiv(covBefore - covAfter);
        } else {
            return (slippageBefore - slippageAfter).wdiv(covAfter - covBefore);
        }
    }

    /**
     * @notice Yellow Paper Def. 2.5 (Swapping Slippage). Calculates 1 - (Si - Sj).
     * Uses the formula 1 + (-Si) - (-Sj), with the -Si, -Sj returned from _slippage
     * @dev Adjusted to prevent dealing with underflow of uint256
     * @param si -si slippage parameter in WAD
     * @param sj -sj slippage parameter
     * @return The result of swapping slippage (1 - Si->j)
     */
    function _swappingSlippage(uint256 si, uint256 sj) internal pure returns (uint256) {
        return WAD + si - sj;
    }

    /**
     * @notice Yellow Paper Def. 4.0 (Haircut).
     * @dev Applies haircut rate to amount
     * @param amount The amount that will receive the discount
     * @param rate The rate to be applied
     * @return The result of operation.
     */
    function _haircut(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return amount.wmul(rate);
    }

    /**
     * @notice Applies dividend to amount
     * @param amount The amount that will receive the discount
     * @param ratio The ratio to be applied in dividend
     * @return The result of operation.
     */
    function _dividend(uint256 amount, uint256 ratio) internal pure returns (uint256) {
        return amount.wmul(WAD - ratio);
    }

    /**
     * @notice Yellow Paper Def. 5.2 (Withdrawal Fee)
     * @dev When covBefore >= 1, fee is 0
     * @dev When covBefore < 1, we apply a fee to prevent withdrawal arbitrage
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param cash cash position of asset in WAD
     * @param liability liability position of asset in WAD
     * @param amount amount to be withdrawn in WAD
     * @return The final fee to be applied
     */
    function _withdrawalFee(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 amount
    ) internal pure returns (uint256) {
        uint256 covBefore = cash.wdiv(liability);
        if (covBefore >= WAD) {
            return 0;
        }

        if (liability <= amount) {
            return 0;
        }

        uint256 cashAfter;
        // Cover case where cash <= amount
        if (cash > amount) {
            cashAfter = cash - amount;
        } else {
            cashAfter = 0;
        }

        uint256 covAfter = (cashAfter).wdiv(liability - amount);
        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);
        uint256 slippageNeutral = _slippageFunc(k, n, c1, xThreshold, WAD); // slippage on cov = 1

        // calculate fee
        // fee = a - b
        // fee = [(Li - Di) * SlippageAfter] + [g(1) * Di] - [Li * SlippageBefore]
        uint256 a = ((liability - amount).wmul(slippageAfter) + slippageNeutral.wmul(amount));
        uint256 b = liability.wmul(slippageBefore);

        // handle underflow case
        if (a > b) {
            return a - b;
        }
        return 0;
    }

    /**
     * @notice Yellow Paper Def. 6.2 (Arbitrage Fee) / Deposit fee
     * @dev When covBefore <= 1, fee is 0
     * @dev When covBefore > 1, we apply a fee to prevent deposit arbitrage
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param cash cash position of asset in WAD
     * @param liability liability position of asset in WAD
     * @param amount amount to be deposited in WAD
     * @return The final fee to be applied
     */
    function _depositFee(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 amount
    ) internal pure returns (uint256) {
        // cover case where the asset has no liquidity yet
        if (liability == 0) {
            return 0;
        }

        uint256 covBefore = cash.wdiv(liability);
        if (covBefore <= WAD) {
            return 0;
        }

        uint256 covAfter = (cash + amount).wdiv(liability + amount);
        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);

        // (Li + Di) * g(cov_after) - Li * g(cov_before)
        return ((liability + amount).wmul(slippageAfter)) - (liability.wmul(slippageBefore));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface IPoolCrossChain {
    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swapCrossChain(
        address fromToken_,
        uint256 fromAmount_,
        uint256 minimumToAmount_,
        uint256 dstAssetId_,
        uint256 destinationChain_,
        uint256 deadline_,
        uint256 executionFee_
    )
        external
        payable
        returns (
            uint256 actualToAmount,
            uint256 haircut,
            uint256 nonce
        );

    function receiveSwapCrossChain(
        address sender_,
        uint256 srcChainId_,
        address srcAsset_,
        address dstAsset_,
        uint256 amount_,
        uint256 haircut_,
        uint256 nonce_
    ) external;

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 destinationAsset,
        uint256 destinationChain
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function getTokenAddresses() external view returns (address[] memory);

    function getNoncePerChain(uint256 chainId_) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IAsset.sol";
import "../libraries/Math.sol";

/**
 * @title Asset
 * @notice Contract presenting an asset in a pool
 * @dev Expect to be owned by Timelock for management, and _pool links to Pool for coordination
 */
contract Asset is Ownable, ERC20 {
    using SafeERC20 for IERC20; // underlying token is ERC20

    /// @notice The underlying underlyingToken represented by this asset
    address private _underlyingToken;
    /// @notice The Pool
    address private _pool;
    /// @notice The Pool
    address private _crossChainPool;
    /// @notice The Fee Collector
    address private _feeCollector;
    /// @notice Cash balance, normally it should align with IERC20(_underlyingToken).balanceOf(address(this))
    uint256 private _cash;
    /// @notice Total liability, equals to the sum of deposit and dividend
    uint256 private _liability;
    /// @notice Owner
    address private _owner;
    /// @notice Name of the asset
    string public _name;
    /// @notice Symbol of the asset
    string public _symbol;
    /// @notice Aggregate Account of the asset
    address private _aggregateAccount;
    /// @notice _maxSupply the maximum amount of asset the pool is allowed to mint.
    /// @dev if 0, means asset has no max
    uint256 private _maxSupply;

    /// @notice An event thats emitted when pool is updated
    event PoolUpdated(address indexed previousPool, address indexed newPool);

    /// @notice An event thats emitted when fee collector is updated
    event FeeCollectorUpdated(address indexed previousFeeCollector, address indexed newFeeCollector);

    /// @notice An event thats emitted when max supply is updated
    event MaxSupplyUpdated(uint256 previousMaxSupply, uint256 newMaxSupply);

    /// @notice An event thats emitted when cash is addedd
    event CashAdded(uint256 previousCashPosition, uint256 cashBeingAdded);

    /// @notice An event thats emitted when cash is removed
    event CashRemoved(uint256 previousCashPosition, uint256 cashBeingRemoved);

    /// @notice An event thats emitted when liability is added
    event LiabilityAdded(uint256 previousLiabilityPosition, uint256 liabilityBeingAdded);

    /// @notice An event thats emitted when liability is removed
    event LiabilityRemoved(uint256 previousLiabilityPosition, uint256 liabilityBeingRemoved);

    /**
     * @notice Initializer.
     * @dev _ suffix to avoid shadowing underlyingToken() name and  symbol
     * @param underlyingToken_ The token represented by the asset
     * @param name_ The name of the asset
     * @param symbol_ The symbol of the asset
     * @param aggregateAccount_ The aggregate account to which the the asset belongs
     */
    constructor(
        address underlyingToken_,
        string memory name_,
        string memory symbol_,
        address aggregateAccount_
    ) ERC20(name_, symbol_) {
        require(underlyingToken_ != address(0), "!underlying");
        require(aggregateAccount_ != address(0), "!aggregate");

        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _underlyingToken = underlyingToken_;
        _aggregateAccount = aggregateAccount_;
    }

    /// @dev Modifier ensuring that certain function can only be called by pool or crosschain pool
    modifier onlyPool() {
        require(msg.sender == _pool || msg.sender == _crossChainPool, "!pool");
        _;
    }

    /// @dev Modifier ensuring that certain function can only be called by fee collector or pool
    modifier onlyFeeCollectorOrPool() {
        require(msg.sender == _feeCollector || msg.sender == _pool || msg.sender == _crossChainPool, "!permission");
        _;
    }

    /**
     * @notice Gets current asset max supply
     * @return The current max supply of asset
     */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Changes asset max supply. Can only be set by the contract owner.
     * @param maxSupply_ the new asset's max supply
     */
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        uint256 oldMaxSupply = _maxSupply;
        _maxSupply = maxSupply_;
        emit MaxSupplyUpdated(oldMaxSupply, maxSupply_);
    }

    /**
     * @notice Gets current Pool address
     * @return The current Pool address for Asset
     */
    function pool() external view returns (address) {
        return _pool;
    }

    /**
     * @notice Gets current CrossChain Pool address
     * @return The current CrossChain Pool address for Asset
     */
    function crossChainPool() external view returns (address) {
        return _crossChainPool;
    }

    /**
     * @notice Changes the pool or crosschain pool. Can only be set by the contract owner.
     * @param pool_ new pool's address
     */
    function setPool(address pool_, bool isCrossChain_) external onlyOwner {
        require(pool_ != address(0), "ADDRESS_ZERO");
        if (isCrossChain_) {
            emit PoolUpdated(_crossChainPool, pool_);
            _crossChainPool = pool_;
        } else {
            emit PoolUpdated(_pool, pool_);
            _pool = pool_;
        }
    }

    /**
     * @notice Gets current Fee Collector address
     * @return The current Fee Collector address for Asset
     */
    function feeCollector() external view returns (address) {
        return _feeCollector;
    }

    /**
     * @notice Changes the fee collector. Can only be set by the contract owner.
     * @param feeCollector_ new fee collector's address
     */
    function setFeeCollector(address feeCollector_) external onlyOwner {
        require(feeCollector_ != address(0), "!feeCollector");
        address oldFeeCollector = feeCollector_;
        _feeCollector = feeCollector_;
        emit FeeCollectorUpdated(oldFeeCollector, feeCollector_);
    }

    /**
     * @notice Changes the aggregate account. Can only be set by the contract owner.
     * @param aggregateAccount_ new aggregate account address
     */
    function setAggregateAccount(address aggregateAccount_) external onlyOwner {
        require(aggregateAccount_ != address(0), "!aggregate");
        _aggregateAccount = aggregateAccount_;
    }

    /**
     * @notice Returns the address of the Aggregate Account 'holding' this asset
     * @return The current Aggregate Account address for Asset
     */
    function aggregateAccount() external view returns (address) {
        return _aggregateAccount;
    }

    /**
     * @notice Returns the address of ERC20 underlyingToken represented by this asset
     * @return The current address of ERC20 underlyingToken for Asset
     */
    function underlyingToken() external view returns (address) {
        return _underlyingToken;
    }

    /**
     * @notice Returns the decimals of ERC20 underlyingToken
     * @return The current decimals for underlying token
     */
    function decimals() public view virtual override returns (uint8) {
        // `decimals` not in IERC20
        return ERC20(_underlyingToken).decimals();
    }

    /**
     * @notice Get underlying Token Balance
     * @return Returns the actual balance of ERC20 underlyingToken
     */
    function underlyingTokenBalance() external view returns (uint256) {
        return IERC20(_underlyingToken).balanceOf(address(this));
    }

    /**
     * @notice Transfers ERC20 underlyingToken from this contract to another account. Can only be called by Pool.
     * @dev Not to be confused with transferring cashmere Assets.
     * @param to address to transfer the token to
     * @param amount amount to transfer
     */
    function transferUnderlyingToken(address to, uint256 amount) external onlyFeeCollectorOrPool {
        IERC20(_underlyingToken).safeTransfer(to, amount);
    }

    /**
     * @notice Mint Asset Token, expect pool coordinates other state updates. Can only be called by Pool.
     * @param to address to transfer the token to
     * @param amount amount to transfer
     */
    function mint(address to, uint256 amount) external onlyPool {
        if (this.maxSupply() != 0) {
            // if maxSupply == 0, asset is uncapped.
            require(amount + this.totalSupply() <= this.maxSupply(), "maxSupply");
        }
        return _mint(to, amount);
    }

    /**
     * @notice Burn Asset Token, expect pool coordinates other state updates. Can only be called by Pool.
     * @param to address holding the tokens
     * @param amount amount to burn
     */
    function burn(address to, uint256 amount) external onlyPool {
        return _burn(to, amount);
    }

    /**
     * @notice Returns the amount of underlyingToken transferrable, expect to match underlyingTokenBalance()
     */
    function cash() external view returns (uint256) {
        return _cash;
    }

    /**
     * @notice Adds cash, expects actual ERC20 underlyingToken got transferred in. Can only be called by Pool.
     * @param amount amount to add
     */
    function addCash(uint256 amount) external onlyPool {
        _cash += amount;
        emit CashAdded(this.cash() - amount, amount);
    }

    /**
     * @notice Deducts cash, expect actual ERC20 got transferred out (by transferUnderlyingToken()).
     * Can only be called by Pool.
     * @param amount amount to remove
     */
    function removeCash(uint256 amount) external onlyPool {
        require(_cash >= amount, "!cash");
        _cash -= amount;
        emit CashRemoved(this.cash() + amount, amount);
    }

    /**
     * @notice Returns the amount of liability, the total deposit and dividend
     */
    function liability() external view returns (uint256) {
        return _liability;
    }

    /**
     * @notice Adds deposit or dividend, expect LP underlyingToken minted in case of deposit.
     * Can only be called by Pool.
     * @param amount amount to add
     */
    function addLiability(uint256 amount) external onlyPool {
        _liability += amount;
        emit LiabilityAdded(this.liability() - amount, amount);
    }

    /**
     * @notice Removes deposit and dividend earned, expect LP underlyingToken burnt.
     * Can only be called by Pool.
     * @param amount amount to remove
     */
    function removeLiability(uint256 amount) external onlyPool {
        require(_liability >= amount, "!liability");
        _liability -= amount;
        emit LiabilityRemoved(this.liability() + amount, amount);
    }

    /**
     * @notice Calculates compensation ratio, value is 1e18.
     */
    function getCompensationRatio() external view returns (uint256) {
        uint256 liability = _liability;
        uint256 cash = _cash;
        if (liability == 0 || cash == 0) {
            return 1e18;
        }
        return Math.wdiv(_cash, liability);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/IAsset.sol";

interface IFeeCollector {
    function collectFees(IAsset asset_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICSMCrossChainRouter {
    struct CrossChainAsset {
        uint256 cash;
        uint256 liability;
        uint256 decimals;
        uint64 assetId;
        address nativeAssetAddress; // address of the IAsset on the native chain
        address nativeTokenAddress; // address of the underlying token on the native chain
    }

    struct CrossChainParams {
        CrossChainAsset fromAsset;
        CrossChainAsset toAsset;
        uint256 actualToAmount;
        uint256 haircut;
        bytes payload;
        uint256 nonce;
    }

    function isApprovedAsset(uint256 chainId_, uint256 assetId_) external view returns (bool);

    function isApprovedAsset(uint256 chainId_, address assetAddress_) external view returns (bool);

    function isApprovedRouter(uint256 chainId_, address router_) external view returns (bool);

    function getAssetData(uint256 chainId_, uint256 assetId_) external view returns (CrossChainAsset memory);

    function getAssetData(uint256 chainId_, address assetAddress_) external view returns (CrossChainAsset memory);

    function getApprovedAssetId(address assetAddress_, uint256 chainId_) external view returns (uint256);

    function getCrossChainAssetParams(uint256 chainId_, uint256 assetId_) external view returns (uint256, uint256);

    function estimateFee() external view returns (uint256);

    function route(
        uint256 dstChain_,
        address dstAddress_,
        bytes calldata payload_,
        uint256 executionFee_
    ) external payable;

    function routerReceive(
        address sender_,
        address srcAsset_,
        address dstAsset_,
        uint256 amount_,
        uint256 haircut_,
        uint256 nonce_
    ) external;

    function modifyCrossChainParams(
        uint256 chainId_,
        uint256 assetId_,
        uint256 cash_,
        uint256 liability_
    ) external;

    function toggleAssetAndChain(
        uint256 chainId_,
        address assetAddress_,
        address tokenAddress_,
        uint256 assetId_,
        uint256 decimals_,
        bool add_
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of Asset
 */
interface IAsset is IERC20Metadata {
    function aggregateAccount() external view returns (address);

    function cash() external view returns (uint256);

    function liability() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;

    function getCompensationRatio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// a library for performing various math operations

library Math {
    uint256 public constant WAD = 10**18;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}