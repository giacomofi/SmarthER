// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IStargateFeeLibrary.sol";
import "../Pool.sol";
import "../Factory.sol";
import "../interfaces/IStargateLPStaking.sol";
import "../chainlink/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StargateFeeLibraryV04 is IStargateFeeLibrary, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // VARIABLES

    // equilibrium func params. all in BPs * 10 ^ 2, i.e. 1 % = 10 ^ 6 units
    uint256 public constant DENOMINATOR = 1e18;
    uint256 public constant DELTA_1 = 6000 * 1e14;
    uint256 public constant DELTA_2 = 500 * 1e14;
    uint256 public constant LAMBDA_1 = 40 * 1e14;
    uint256 public constant LAMBDA_2 = 9960 * 1e14;
    uint256 public constant LP_FEE = 10 * 1e13;
    uint256 public constant PROTOCOL_FEE = 50 * 1e13;
    uint256 public constant PROTOCOL_SUBSIDY = 3 * 1e13;

    uint256 public constant FIFTY_PERCENT = 5 * 1e17;
    uint256 public constant SIXTY_PERCENT = 6 * 1e17;

    int256 public depegThreshold; // threshold for considering an asset depegged

    mapping(address => bool) public whitelist;
    mapping(uint256 => uint256) public poolIdToLpId; // poolId -> index of the pool in the lpStaking contract
    mapping(uint256 => address) public poolIdToPriceFeed; // maps the poolId to Chainlink priceFeedAddress

    Factory public immutable factory;
    IStargateLPStaking public immutable lpStaking;

    modifier notDepegged(uint256 _srcPoolId, uint256 _dstPoolId) {
        address priceFeedAddress = poolIdToPriceFeed[_srcPoolId];
        if (_srcPoolId != _dstPoolId && priceFeedAddress != address(0x0)) {
            (, int256 price, , , ) = AggregatorV3Interface(priceFeedAddress).latestRoundData();
            require(price >= depegThreshold, "FeeLibrary: _srcPoolId is depegged");
        }
        _;
    }

    constructor(
        address _factory,
        address _lpStakingContract,
        int256 _depegThreshold
    ) {
        require(_factory != address(0x0), "FeeLibrary: Factory cannot be 0x0");
        require(_lpStakingContract != address(0x0), "FeeLibrary: LPStaking cannot be 0x0");
        require(_depegThreshold > 0, "FeeLibrary: _depegThreshold must be > 0");

        factory = Factory(_factory);
        lpStaking = IStargateLPStaking(_lpStakingContract);
        depegThreshold = _depegThreshold;
    }

    function whiteList(address _from, bool _whiteListed) public onlyOwner {
        whitelist[_from] = _whiteListed;
    }

    function setPoolToLpId(uint256 _poolId, uint256 _lpId) public onlyOwner {
        poolIdToLpId[_poolId] = _lpId;
    }

    function setPoolIdToPriceFeedAddress(uint256 _poolId, address _priceFeedAddress) public onlyOwner {
        poolIdToPriceFeed[_poolId] = _priceFeedAddress;
    }

    function setDepegThreshold(int256 _depegThreshold) public onlyOwner {
        require(_depegThreshold > 0, "FeeLibrary: _depegThreshold must be > 0");
        depegThreshold = _depegThreshold;
    }

    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external view override notDepegged(_srcPoolId, _dstPoolId) returns (Pool.SwapObj memory s) {
        uint256 srcPoolId = _srcPoolId; // stack too deep

        Pool pool = factory.getPool(srcPoolId);
        Pool.ChainPath memory chainPath = pool.getChainPath(_dstChainId, _dstPoolId);
        address tokenAddress = pool.token();
        uint256 currentAssetSD = IERC20(tokenAddress).balanceOf(address(pool)).div(pool.convertRate());
        uint256 lpAsset = pool.totalLiquidity();

        // calculate the equilibrium reward
        s.eqReward = _getEqReward(_amountSD, currentAssetSD, lpAsset, pool.eqFeePool());

        // calculate the equilibrium fee
        uint256 protocolSubsidy;
        (s.eqFee, protocolSubsidy) = _getEquilibriumFee(chainPath.idealBalance, chainPath.balance, _amountSD);

        // return no protocol/lp fees for addresses in this mapping
        if (whitelist[_from]) {
            return s;
        }

        // calculate protocol and lp fee
        (s.protocolFee, s.lpFee) = _getProtocolAndLpFee(_amountSD, currentAssetSD, lpAsset, protocolSubsidy, srcPoolId, chainPath);

        return s;
    }

    function getEqReward(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _rewardPoolSize
    ) external pure returns (uint256 eqReward) {
        return _getEqReward(_amountSD, _currentAssetSD, _lpAsset, _rewardPoolSize);
    }

    function getEquilibriumFee(
        uint256 idealBalance,
        uint256 beforeBalance,
        uint256 amountSD
    ) external pure returns (uint256, uint256) {
        return _getEquilibriumFee(idealBalance, beforeBalance, amountSD);
    }

    function getProtocolAndLpFee(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _protocolSubsidy,
        uint256 _srcPoolId,
        Pool.ChainPath memory _chainPath
    ) external view returns (uint256 protocolFee, uint256 lpFee) {
        return _getProtocolAndLpFee(_amountSD, _currentAssetSD, _lpAsset, _protocolSubsidy, _srcPoolId, _chainPath);
    }

    function getTrapezoidArea(
        uint256 lambda,
        uint256 yOffset,
        uint256 xUpperBound,
        uint256 xLowerBound,
        uint256 xStart,
        uint256 xEnd
    ) external pure returns (uint256) {
        return _getTrapezoidArea(lambda, yOffset, xUpperBound, xLowerBound, xStart, xEnd);
    }

    function _getEqReward(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _rewardPoolSize
    ) internal pure returns (uint256 eqReward) {
        if (_lpAsset <= _currentAssetSD) {
            return 0;
        }

        uint256 poolDeficit = _lpAsset.sub(_currentAssetSD);
        // assets in pool are < 75% of liquidity provided & amount transferred > 2% of pool deficit
        if (_currentAssetSD.mul(100).div(_lpAsset) < 75 && _amountSD.mul(100) > poolDeficit.mul(2)) {
            // reward capped at rewardPoolSize
            eqReward = _rewardPoolSize.mul(_amountSD).div(poolDeficit);
            if (eqReward > _rewardPoolSize) {
                eqReward = _rewardPoolSize;
            }
        } else {
            eqReward = 0;
        }
    }

    function _getEquilibriumFee(
        uint256 idealBalance,
        uint256 beforeBalance,
        uint256 amountSD
    ) internal pure returns (uint256, uint256) {
        require(beforeBalance >= amountSD, "Stargate: not enough balance");
        uint256 afterBalance = beforeBalance.sub(amountSD);

        uint256 safeZoneMax = idealBalance.mul(DELTA_1).div(DENOMINATOR);
        uint256 safeZoneMin = idealBalance.mul(DELTA_2).div(DENOMINATOR);

        uint256 eqFee = 0;
        uint256 protocolSubsidy = 0;

        if (afterBalance >= safeZoneMax) {
            // no fee zone, protocol subsidize it.
            eqFee = amountSD.mul(PROTOCOL_SUBSIDY).div(DENOMINATOR);
            protocolSubsidy = eqFee;
        } else if (afterBalance >= safeZoneMin) {
            // safe zone
            uint256 proxyBeforeBalance = beforeBalance < safeZoneMax ? beforeBalance : safeZoneMax;
            eqFee = _getTrapezoidArea(LAMBDA_1, 0, safeZoneMax, safeZoneMin, proxyBeforeBalance, afterBalance);
        } else {
            // danger zone
            if (beforeBalance >= safeZoneMin) {
                // across 2 or 3 zones
                // part 1
                uint256 proxyBeforeBalance = beforeBalance < safeZoneMax ? beforeBalance : safeZoneMax;
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_1, 0, safeZoneMax, safeZoneMin, proxyBeforeBalance, safeZoneMin));
                // part 2
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_2, LAMBDA_1, safeZoneMin, 0, safeZoneMin, afterBalance));
            } else {
                // only in danger zone
                // part 2 only
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_2, LAMBDA_1, safeZoneMin, 0, beforeBalance, afterBalance));
            }
        }
        return (eqFee, protocolSubsidy);
    }

    function _getProtocolAndLpFee(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _protocolSubsidy,
        uint256 _srcPoolId,
        Pool.ChainPath memory _chainPath
    ) internal view returns (uint256 protocolFee, uint256 lpFee) {
        protocolFee = _amountSD.mul(PROTOCOL_FEE).div(DENOMINATOR).sub(_protocolSubsidy);
        lpFee = _amountSD.mul(LP_FEE).div(DENOMINATOR);

        // when there are active emissions, give the lp fee to the protocol
        (, uint256 allocPoint, , ) = lpStaking.poolInfo(poolIdToLpId[_srcPoolId]);
        if (allocPoint > 0) {
            protocolFee = protocolFee.add(lpFee);
            lpFee = 0;
        }

        if (_lpAsset == 0) {
            return (protocolFee, lpFee);
        }

        uint256 currentAssetNumerated = _currentAssetSD.mul(DENOMINATOR).div(_lpAsset);
        if (currentAssetNumerated <= FIFTY_PERCENT) {
            // x <= 50% => no fees
            protocolFee = 0;
            lpFee = 0;
        } else if (
            currentAssetNumerated < SIXTY_PERCENT &&
            _chainPath.balance.sub(_amountSD) > _chainPath.idealBalance.mul(SIXTY_PERCENT).div(DENOMINATOR)
        ) {
            // 50% > x < 60% => scaled fees &&
            // the resulting transfer does not drain the pathway below 60% of the ideal balance,

            // reduce the protocol and lp fee linearly
            // Examples:
            // currentAsset == 101, lpAsset == 200 -> haircut == 5%
            // currentAsset == 115, lpAsset == 200 -> haircut == 75%
            // currentAsset == 119, lpAsset == 200 -> haircut == 95%
            uint256 haircut = currentAssetNumerated.sub(FIFTY_PERCENT).mul(10); // scale the percentage by 10
            protocolFee = protocolFee.mul(haircut).div(DENOMINATOR);
            lpFee = lpFee.mul(haircut).div(DENOMINATOR);
        }

        // x > 60% => full fees
    }

    function _getTrapezoidArea(
        uint256 lambda,
        uint256 yOffset,
        uint256 xUpperBound,
        uint256 xLowerBound,
        uint256 xStart,
        uint256 xEnd
    ) internal pure returns (uint256) {
        require(xEnd >= xLowerBound && xStart <= xUpperBound, "Stargate: balance out of bound");
        uint256 xBoundWidth = xUpperBound.sub(xLowerBound);

        // xStartDrift = xUpperBound.sub(xStart);
        uint256 yStart = xUpperBound.sub(xStart).mul(lambda).div(xBoundWidth).add(yOffset);

        // xEndDrift = xUpperBound.sub(xEnd)
        uint256 yEnd = xUpperBound.sub(xEnd).mul(lambda).div(xBoundWidth).add(yOffset);

        // compute the area
        uint256 deltaX = xStart.sub(xEnd);
        return yStart.add(yEnd).mul(deltaX).div(2).div(DENOMINATOR);
    }

    function getVersion() external pure override returns (string memory) {
        return "4.0.0";
    }

    // Override the renounce ownership inherited by zeppelin ownable
    function renounceOwnership() public override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;
import "../Pool.sol";

interface IStargateFeeLibrary {
    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external returns (Pool.SwapObj memory s);

    function getVersion() external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

// imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./LPTokenERC20.sol";
import "./interfaces/IStargateFeeLibrary.sol";

// libraries
import "@openzeppelin/contracts/math/SafeMath.sol";

/// Pool contracts on other chains and managed by the Stargate protocol.
contract Pool is LPTokenERC20, ReentrancyGuard {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // CONSTANTS
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint256 public constant BP_DENOMINATOR = 10000;

    //---------------------------------------------------------------------------
    // STRUCTS
    struct ChainPath {
        bool ready; // indicate if the counter chainPath has been created.
        uint16 dstChainId;
        uint256 dstPoolId;
        uint256 weight;
        uint256 balance;
        uint256 lkb;
        uint256 credits;
        uint256 idealBalance;
    }

    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    struct CreditObj {
        uint256 credits;
        uint256 idealBalance;
    }

    //---------------------------------------------------------------------------
    // VARIABLES

    // chainPath
    ChainPath[] public chainPaths; // list of connected chains with shared pools
    mapping(uint16 => mapping(uint256 => uint256)) public chainPathIndexLookup; // lookup for chainPath by chainId => poolId =>index

    // metadata
    uint256 public immutable poolId; // shared id between chains to represent same pool
    uint256 public sharedDecimals; // the shared decimals (lowest common decimals between chains)
    uint256 public localDecimals; // the decimals for the token
    uint256 public immutable convertRate; // the decimals for the token
    address public immutable token; // the token for the pool
    address public immutable router; // the token for the pool

    bool public stopSwap; // flag to stop swapping in extreme cases

    // Fee and Liquidity
    uint256 public totalLiquidity; // the total amount of tokens added on this side of the chain (fees + deposits - withdrawals)
    uint256 public totalWeight; // total weight for pool percentages
    uint256 public mintFeeBP; // fee basis points for the mint/deposit
    uint256 public protocolFeeBalance; // fee balance created from dao fee
    uint256 public mintFeeBalance; // fee balance created from mint fee
    uint256 public eqFeePool; // pool rewards in Shared Decimal format. indicate the total budget for reverse swap incentive
    address public feeLibrary; // address for retrieving fee params for swaps

    // Delta related
    uint256 public deltaCredit; // credits accumulated from txn
    bool public batched; // flag to indicate if we want batch processing.
    bool public defaultSwapMode; // flag for the default mode for swap
    bool public defaultLPMode; // flag for the default mode for lp
    uint256 public swapDeltaBP; // basis points of poolCredits to activate Delta in swap
    uint256 public lpDeltaBP; // basis points of poolCredits to activate Delta in liquidity events

    //---------------------------------------------------------------------------
    // EVENTS
    event Mint(address to, uint256 amountLP, uint256 amountSD, uint256 mintFeeAmountSD);
    event Burn(address from, uint256 amountLP, uint256 amountSD);
    event RedeemLocalCallback(address _to, uint256 _amountSD, uint256 _amountToMintSD);
    event Swap(
        uint16 chainId,
        uint256 dstPoolId,
        address from,
        uint256 amountSD,
        uint256 eqReward,
        uint256 eqFee,
        uint256 protocolFee,
        uint256 lpFee
    );
    event SendCredits(uint16 dstChainId, uint256 dstPoolId, uint256 credits, uint256 idealBalance);
    event RedeemRemote(uint16 chainId, uint256 dstPoolId, address from, uint256 amountLP, uint256 amountSD);
    event RedeemLocal(address from, uint256 amountLP, uint256 amountSD, uint16 chainId, uint256 dstPoolId, bytes to);
    event InstantRedeemLocal(address from, uint256 amountLP, uint256 amountSD, address to);
    event CreditChainPath(uint16 chainId, uint256 srcPoolId, uint256 amountSD, uint256 idealBalance);
    event SwapRemote(address to, uint256 amountSD, uint256 protocolFee, uint256 dstFee);
    event WithdrawRemote(uint16 srcChainId, uint256 srcPoolId, uint256 swapAmount, uint256 mintAmount);
    event ChainPathUpdate(uint16 dstChainId, uint256 dstPoolId, uint256 weight);
    event FeesUpdated(uint256 mintFeeBP);
    event FeeLibraryUpdated(address feeLibraryAddr);
    event StopSwapUpdated(bool swapStop);
    event WithdrawProtocolFeeBalance(address to, uint256 amountSD);
    event WithdrawMintFeeBalance(address to, uint256 amountSD);
    event DeltaParamUpdated(bool batched, uint256 swapDeltaBP, uint256 lpDeltaBP, bool defaultSwapMode, bool defaultLPMode);

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyRouter() {
        require(msg.sender == router, "Stargate: only the router can call this method");
        _;
    }

    constructor(
        uint256 _poolId,
        address _router,
        address _token,
        uint256 _sharedDecimals,
        uint256 _localDecimals,
        address _feeLibrary,
        string memory _name,
        string memory _symbol
    ) LPTokenERC20(_name, _symbol) {
        require(_token != address(0x0), "Stargate: _token cannot be 0x0");
        require(_router != address(0x0), "Stargate: _router cannot be 0x0");
        poolId = _poolId;
        router = _router;
        token = _token;
        sharedDecimals = _sharedDecimals;
        decimals = uint8(_sharedDecimals);
        localDecimals = _localDecimals;
        convertRate = 10**(uint256(localDecimals).sub(sharedDecimals));
        totalWeight = 0;
        feeLibrary = _feeLibrary;

        //delta algo related
        batched = false;
        defaultSwapMode = true;
        defaultLPMode = true;
    }

    function getChainPathsLength() public view returns (uint256) {
        return chainPaths.length;
    }

    //---------------------------------------------------------------------------
    // LOCAL CHAIN FUNCTIONS

    function mint(address _to, uint256 _amountLD) external nonReentrant onlyRouter returns (uint256) {
        return _mintLocal(_to, _amountLD, true, true);
    }

    // Local                                    Remote
    // -------                                  ---------
    // swap             ->                      swapRemote
    function swap(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        bool newLiquidity
    ) external nonReentrant onlyRouter returns (SwapObj memory) {
        require(!stopSwap, "Stargate: swap func stopped");
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        require(cp.ready == true, "Stargate: counter chainPath is not ready");

        uint256 amountSD = amountLDtoSD(_amountLD);
        uint256 minAmountSD = amountLDtoSD(_minAmountLD);

        // request fee params from library
        SwapObj memory s = IStargateFeeLibrary(feeLibrary).getFees(poolId, _dstPoolId, _dstChainId, _from, amountSD);

        // equilibrium fee and reward. note eqFee/eqReward are separated from swap liquidity
        eqFeePool = eqFeePool.sub(s.eqReward);
        // update the new amount the user gets minus the fees
        s.amount = amountSD.sub(s.eqFee).sub(s.protocolFee).sub(s.lpFee);
        // users will also get the eqReward
        require(s.amount.add(s.eqReward) >= minAmountSD, "Stargate: slippage too high");

        // behaviours
        //     - protocolFee: booked, stayed and withdrawn at remote.
        //     - eqFee: booked, stayed and withdrawn at remote.
        //     - lpFee: booked and stayed at remote, can be withdrawn anywhere

        s.lkbRemove = amountSD.sub(s.lpFee).add(s.eqReward);
        // check for transfer solvency.
        require(cp.balance >= s.lkbRemove, "Stargate: dst balance too low");
        cp.balance = cp.balance.sub(s.lkbRemove);

        if (newLiquidity) {
            deltaCredit = deltaCredit.add(amountSD).add(s.eqReward);
        } else if (s.eqReward > 0) {
            deltaCredit = deltaCredit.add(s.eqReward);
        }

        // distribute credits on condition.
        if (!batched || deltaCredit >= totalLiquidity.mul(swapDeltaBP).div(BP_DENOMINATOR)) {
            _delta(defaultSwapMode);
        }

        emit Swap(_dstChainId, _dstPoolId, _from, s.amount, s.eqReward, s.eqFee, s.protocolFee, s.lpFee);
        return s;
    }

    // Local                                    Remote
    // -------                                  ---------
    // sendCredits      ->                      creditChainPath
    function sendCredits(uint16 _dstChainId, uint256 _dstPoolId) external nonReentrant onlyRouter returns (CreditObj memory c) {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        require(cp.ready == true, "Stargate: counter chainPath is not ready");
        cp.lkb = cp.lkb.add(cp.credits);
        c.idealBalance = totalLiquidity.mul(cp.weight).div(totalWeight);
        c.credits = cp.credits;
        cp.credits = 0;
        emit SendCredits(_dstChainId, _dstPoolId, c.credits, c.idealBalance);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemRemote   ->                        swapRemote
    function redeemRemote(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        address _from,
        uint256 _amountLP
    ) external nonReentrant onlyRouter {
        require(_from != address(0x0), "Stargate: _from cannot be 0x0");
        uint256 amountSD = _burnLocal(_from, _amountLP);
        //run Delta
        if (!batched || deltaCredit > totalLiquidity.mul(lpDeltaBP).div(BP_DENOMINATOR)) {
            _delta(defaultLPMode);
        }
        uint256 amountLD = amountSDtoLD(amountSD);
        emit RedeemRemote(_dstChainId, _dstPoolId, _from, _amountLP, amountLD);
    }

    function instantRedeemLocal(
        address _from,
        uint256 _amountLP,
        address _to
    ) external nonReentrant onlyRouter returns (uint256 amountSD) {
        require(_from != address(0x0), "Stargate: _from cannot be 0x0");
        uint256 _deltaCredit = deltaCredit; // sload optimization.
        uint256 _capAmountLP = _amountSDtoLP(_deltaCredit);

        if (_amountLP > _capAmountLP) _amountLP = _capAmountLP;

        amountSD = _burnLocal(_from, _amountLP);
        deltaCredit = _deltaCredit.sub(amountSD);
        uint256 amountLD = amountSDtoLD(amountSD);
        _safeTransfer(token, _to, amountLD);
        emit InstantRedeemLocal(_from, _amountLP, amountSD, _to);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemLocal   ->                         redeemLocalCheckOnRemote
    // redeemLocalCallback             <-
    function redeemLocal(
        address _from,
        uint256 _amountLP,
        uint16 _dstChainId,
        uint256 _dstPoolId,
        bytes calldata _to
    ) external nonReentrant onlyRouter returns (uint256 amountSD) {
        require(_from != address(0x0), "Stargate: _from cannot be 0x0");

        // safeguard.
        require(chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]].ready == true, "Stargate: counter chainPath is not ready");
        amountSD = _burnLocal(_from, _amountLP);

        // run Delta
        if (!batched || deltaCredit > totalLiquidity.mul(lpDeltaBP).div(BP_DENOMINATOR)) {
            _delta(false);
        }
        emit RedeemLocal(_from, _amountLP, amountSD, _dstChainId, _dstPoolId, _to);
    }

    //---------------------------------------------------------------------------
    // REMOTE CHAIN FUNCTIONS

    // Local                                    Remote
    // -------                                  ---------
    // sendCredits      ->                      creditChainPath
    function creditChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        CreditObj memory _c
    ) external nonReentrant onlyRouter {
        ChainPath storage cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]];
        cp.balance = cp.balance.add(_c.credits);
        if (cp.idealBalance != _c.idealBalance) {
            cp.idealBalance = _c.idealBalance;
        }
        emit CreditChainPath(_dstChainId, _dstPoolId, _c.credits, _c.idealBalance);
    }

    // Local                                    Remote
    // -------                                  ---------
    // swap             ->                      swapRemote
    function swapRemote(
        uint16 _srcChainId,
        uint256 _srcPoolId,
        address _to,
        SwapObj memory _s
    ) external nonReentrant onlyRouter returns (uint256 amountLD) {
        // booking lpFee
        totalLiquidity = totalLiquidity.add(_s.lpFee);
        // booking eqFee
        eqFeePool = eqFeePool.add(_s.eqFee);
        // booking stargateFee
        protocolFeeBalance = protocolFeeBalance.add(_s.protocolFee);

        // update LKB
        uint256 chainPathIndex = chainPathIndexLookup[_srcChainId][_srcPoolId];
        chainPaths[chainPathIndex].lkb = chainPaths[chainPathIndex].lkb.sub(_s.lkbRemove);

        // user receives the amount + the srcReward
        amountLD = amountSDtoLD(_s.amount.add(_s.eqReward));
        _safeTransfer(token, _to, amountLD);
        emit SwapRemote(_to, _s.amount.add(_s.eqReward), _s.protocolFee, _s.eqFee);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemLocal   ->                         redeemLocalCheckOnRemote
    // redeemLocalCallback             <-
    function redeemLocalCallback(
        uint16 _srcChainId,
        uint256 _srcPoolId,
        address _to,
        uint256 _amountSD,
        uint256 _amountToMintSD
    ) external nonReentrant onlyRouter {
        if (_amountToMintSD > 0) {
            _mintLocal(_to, amountSDtoLD(_amountToMintSD), false, false);
        }

        ChainPath storage cp = getAndCheckCP(_srcChainId, _srcPoolId);
        cp.lkb = cp.lkb.sub(_amountSD);

        uint256 amountLD = amountSDtoLD(_amountSD);
        _safeTransfer(token, _to, amountLD);
        emit RedeemLocalCallback(_to, _amountSD, _amountToMintSD);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemLocal(amount)   ->               redeemLocalCheckOnRemote
    // redeemLocalCallback             <-
    function redeemLocalCheckOnRemote(
        uint16 _srcChainId,
        uint256 _srcPoolId,
        uint256 _amountSD
    ) external nonReentrant onlyRouter returns (uint256 swapAmount, uint256 mintAmount) {
        ChainPath storage cp = getAndCheckCP(_srcChainId, _srcPoolId);
        if (_amountSD > cp.balance) {
            mintAmount = _amountSD - cp.balance;
            swapAmount = cp.balance;
            cp.balance = 0;
        } else {
            cp.balance = cp.balance.sub(_amountSD);
            swapAmount = _amountSD;
            mintAmount = 0;
        }
        emit WithdrawRemote(_srcChainId, _srcPoolId, swapAmount, mintAmount);
    }

    //---------------------------------------------------------------------------
    // DAO Calls
    function createChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _weight
    ) external onlyRouter {
        for (uint256 i = 0; i < chainPaths.length; ++i) {
            ChainPath memory cp = chainPaths[i];
            bool exists = cp.dstChainId == _dstChainId && cp.dstPoolId == _dstPoolId;
            require(!exists, "Stargate: cant createChainPath of existing dstChainId and _dstPoolId");
        }
        totalWeight = totalWeight.add(_weight);
        chainPathIndexLookup[_dstChainId][_dstPoolId] = chainPaths.length;
        chainPaths.push(ChainPath(false, _dstChainId, _dstPoolId, _weight, 0, 0, 0, 0));
        emit ChainPathUpdate(_dstChainId, _dstPoolId, _weight);
    }

    function setWeightForChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint16 _weight
    ) external onlyRouter {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        totalWeight = totalWeight.sub(cp.weight).add(_weight);
        cp.weight = _weight;
        emit ChainPathUpdate(_dstChainId, _dstPoolId, _weight);
    }

    function setFee(uint256 _mintFeeBP) external onlyRouter {
        require(_mintFeeBP <= BP_DENOMINATOR, "Bridge: cum fees > 100%");
        mintFeeBP = _mintFeeBP;
        emit FeesUpdated(mintFeeBP);
    }

    function setFeeLibrary(address _feeLibraryAddr) external onlyRouter {
        require(_feeLibraryAddr != address(0x0), "Stargate: fee library cant be 0x0");
        feeLibrary = _feeLibraryAddr;
        emit FeeLibraryUpdated(_feeLibraryAddr);
    }

    function setSwapStop(bool _swapStop) external onlyRouter {
        stopSwap = _swapStop;
        emit StopSwapUpdated(_swapStop);
    }

    function setDeltaParam(
        bool _batched,
        uint256 _swapDeltaBP,
        uint256 _lpDeltaBP,
        bool _defaultSwapMode,
        bool _defaultLPMode
    ) external onlyRouter {
        require(_swapDeltaBP <= BP_DENOMINATOR && _lpDeltaBP <= BP_DENOMINATOR, "Stargate: wrong Delta param");
        batched = _batched;
        swapDeltaBP = _swapDeltaBP;
        lpDeltaBP = _lpDeltaBP;
        defaultSwapMode = _defaultSwapMode;
        defaultLPMode = _defaultLPMode;
        emit DeltaParamUpdated(_batched, _swapDeltaBP, _lpDeltaBP, _defaultSwapMode, _defaultLPMode);
    }

    function callDelta(bool _fullMode) external onlyRouter {
        _delta(_fullMode);
    }

    function activateChainPath(uint16 _dstChainId, uint256 _dstPoolId) external onlyRouter {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        require(cp.ready == false, "Stargate: chainPath is already active");
        // this func will only be called once
        cp.ready = true;
    }

    function withdrawProtocolFeeBalance(address _to) external onlyRouter {
        if (protocolFeeBalance > 0) {
            uint256 amountOfLD = amountSDtoLD(protocolFeeBalance);
            protocolFeeBalance = 0;
            _safeTransfer(token, _to, amountOfLD);
            emit WithdrawProtocolFeeBalance(_to, amountOfLD);
        }
    }

    function withdrawMintFeeBalance(address _to) external onlyRouter {
        if (mintFeeBalance > 0) {
            uint256 amountOfLD = amountSDtoLD(mintFeeBalance);
            mintFeeBalance = 0;
            _safeTransfer(token, _to, amountOfLD);
            emit WithdrawMintFeeBalance(_to, amountOfLD);
        }
    }

    //---------------------------------------------------------------------------
    // INTERNAL
    // Conversion Helpers
    //---------------------------------------------------------------------------
    function amountLPtoLD(uint256 _amountLP) external view returns (uint256) {
        return amountSDtoLD(_amountLPtoSD(_amountLP));
    }

    function _amountLPtoSD(uint256 _amountLP) internal view returns (uint256) {
        require(totalSupply > 0, "Stargate: cant convert LPtoSD when totalSupply == 0");
        return _amountLP.mul(totalLiquidity).div(totalSupply);
    }

    function _amountSDtoLP(uint256 _amountSD) internal view returns (uint256) {
        require(totalLiquidity > 0, "Stargate: cant convert SDtoLP when totalLiq == 0");
        return _amountSD.mul(totalSupply).div(totalLiquidity);
    }

    function amountSDtoLD(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(convertRate);
    }

    function amountLDtoSD(uint256 _amount) internal view returns (uint256) {
        return _amount.div(convertRate);
    }

    function getAndCheckCP(uint16 _dstChainId, uint256 _dstPoolId) internal view returns (ChainPath storage) {
        require(chainPaths.length > 0, "Stargate: no chainpaths exist");
        ChainPath storage cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]];
        require(cp.dstChainId == _dstChainId && cp.dstPoolId == _dstPoolId, "Stargate: local chainPath does not exist");
        return cp;
    }

    function getChainPath(uint16 _dstChainId, uint256 _dstPoolId) external view returns (ChainPath memory) {
        ChainPath memory cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]];
        require(cp.dstChainId == _dstChainId && cp.dstPoolId == _dstPoolId, "Stargate: local chainPath does not exist");
        return cp;
    }

    function _burnLocal(address _from, uint256 _amountLP) internal returns (uint256) {
        require(totalSupply > 0, "Stargate: cant burn when totalSupply == 0");
        uint256 amountOfLPTokens = balanceOf[_from];
        require(amountOfLPTokens >= _amountLP, "Stargate: not enough LP tokens to burn");

        uint256 amountSD = _amountLP.mul(totalLiquidity).div(totalSupply);
        //subtract totalLiquidity accordingly
        totalLiquidity = totalLiquidity.sub(amountSD);

        _burn(_from, _amountLP);
        emit Burn(_from, _amountLP, amountSD);
        return amountSD;
    }

    function _delta(bool fullMode) internal {
        if (deltaCredit > 0 && totalWeight > 0) {
            uint256 cpLength = chainPaths.length;
            uint256[] memory deficit = new uint256[](cpLength);
            uint256 totalDeficit = 0;

            // algorithm steps 6-9: calculate the total and the amounts required to get to balance state
            for (uint256 i = 0; i < cpLength; ++i) {
                ChainPath storage cp = chainPaths[i];
                // (liquidity * (weight/totalWeight)) - (lkb+credits)
                uint256 balLiq = totalLiquidity.mul(cp.weight).div(totalWeight);
                uint256 currLiq = cp.lkb.add(cp.credits);
                if (balLiq > currLiq) {
                    // save gas since we know balLiq > currLiq and we know deficit[i] > 0
                    deficit[i] = balLiq - currLiq;
                    totalDeficit = totalDeficit.add(deficit[i]);
                }
            }

            // indicates how much delta credit is distributed
            uint256 spent;

            // handle credits with 2 tranches. the [ < totalDeficit] [excessCredit]
            // run full Delta, allocate all credits
            if (totalDeficit == 0) {
                // only fullMode delta will allocate excess credits
                if (fullMode && deltaCredit > 0) {
                    // credit ChainPath by weights
                    for (uint256 i = 0; i < cpLength; ++i) {
                        ChainPath storage cp = chainPaths[i];
                        // credits = credits + toBalanceChange + remaining allocation based on weight
                        uint256 amtToCredit = deltaCredit.mul(cp.weight).div(totalWeight);
                        spent = spent.add(amtToCredit);
                        cp.credits = cp.credits.add(amtToCredit);
                    }
                } // else do nth
            } else if (totalDeficit <= deltaCredit) {
                if (fullMode) {
                    // algorithm step 13: calculate amount to disperse to bring to balance state or as close as possible
                    uint256 excessCredit = deltaCredit - totalDeficit;
                    // algorithm steps 14-16: calculate credits
                    for (uint256 i = 0; i < cpLength; ++i) {
                        if (deficit[i] > 0) {
                            ChainPath storage cp = chainPaths[i];
                            // credits = credits + deficit + remaining allocation based on weight
                            uint256 amtToCredit = deficit[i].add(excessCredit.mul(cp.weight).div(totalWeight));
                            spent = spent.add(amtToCredit);
                            cp.credits = cp.credits.add(amtToCredit);
                        }
                    }
                } else {
                    // totalDeficit <= deltaCredit but not running fullMode
                    // credit chainPaths as is if any deficit, not using all deltaCredit
                    for (uint256 i = 0; i < cpLength; ++i) {
                        if (deficit[i] > 0) {
                            ChainPath storage cp = chainPaths[i];
                            uint256 amtToCredit = deficit[i];
                            spent = spent.add(amtToCredit);
                            cp.credits = cp.credits.add(amtToCredit);
                        }
                    }
                }
            } else {
                // totalDeficit > deltaCredit, fullMode or not, normalize the deficit by deltaCredit
                for (uint256 i = 0; i < cpLength; ++i) {
                    if (deficit[i] > 0) {
                        ChainPath storage cp = chainPaths[i];
                        uint256 proportionalDeficit = deficit[i].mul(deltaCredit).div(totalDeficit);
                        spent = spent.add(proportionalDeficit);
                        cp.credits = cp.credits.add(proportionalDeficit);
                    }
                }
            }

            // deduct the amount of credit sent
            deltaCredit = deltaCredit.sub(spent);
        }
    }

    function _mintLocal(
        address _to,
        uint256 _amountLD,
        bool _feesEnabled,
        bool _creditDelta
    ) internal returns (uint256 amountSD) {
        require(totalWeight > 0, "Stargate: No ChainPaths exist");
        amountSD = amountLDtoSD(_amountLD);

        uint256 mintFeeSD = 0;
        if (_feesEnabled) {
            mintFeeSD = amountSD.mul(mintFeeBP).div(BP_DENOMINATOR);
            amountSD = amountSD.sub(mintFeeSD);
            mintFeeBalance = mintFeeBalance.add(mintFeeSD);
        }

        if (_creditDelta) {
            deltaCredit = deltaCredit.add(amountSD);
        }

        uint256 amountLPTokens = amountSD;
        if (totalSupply != 0) {
            amountLPTokens = amountSD.mul(totalSupply).div(totalLiquidity);
        }
        totalLiquidity = totalLiquidity.add(amountSD);

        _mint(_to, amountLPTokens);
        emit Mint(_to, amountLPTokens, amountSD, mintFeeSD);

        // add to credits and call delta. short circuit to save gas
        if (!batched || deltaCredit > totalLiquidity.mul(lpDeltaBP).div(BP_DENOMINATOR)) {
            _delta(defaultLPMode);
        }
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Stargate: TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pool.sol";

contract Factory is Ownable {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // VARIABLES
    mapping(uint256 => Pool) public getPool; // poolId -> PoolInfo
    address[] public allPools;
    address public immutable router;
    address public defaultFeeLibrary; // address for retrieving fee params for swaps

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyRouter() {
        require(msg.sender == router, "Stargate: caller must be Router.");
        _;
    }

    constructor(address _router) {
        require(_router != address(0x0), "Stargate: _router cant be 0x0"); // 1 time only
        router = _router;
    }

    function setDefaultFeeLibrary(address _defaultFeeLibrary) external onlyOwner {
        require(_defaultFeeLibrary != address(0x0), "Stargate: fee library cant be 0x0");
        defaultFeeLibrary = _defaultFeeLibrary;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(
        uint256 _poolId,
        address _token,
        uint8 _sharedDecimals,
        uint8 _localDecimals,
        string memory _name,
        string memory _symbol
    ) public onlyRouter returns (address poolAddress) {
        require(address(getPool[_poolId]) == address(0x0), "Stargate: Pool already created");

        Pool pool = new Pool(_poolId, router, _token, _sharedDecimals, _localDecimals, defaultFeeLibrary, _name, _symbol);
        getPool[_poolId] = pool;
        poolAddress = address(pool);
        allPools.push(poolAddress);
    }

    function renounceOwnership() public override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStargateLPStaking {
    function poolInfo(uint256 _poolIndex) external view returns (address, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

// libraries
import "@openzeppelin/contracts/math/SafeMath.sol";

contract LPTokenERC20 {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // CONSTANTS
    string public name;
    string public symbol;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // set in constructor
    bytes32 public DOMAIN_SEPARATOR;

    //---------------------------------------------------------------------------
    // VARIABLES
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    //---------------------------------------------------------------------------
    // EVENTS
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Bridge: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Bridge: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}