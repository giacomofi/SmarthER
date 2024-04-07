// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IBUSDC.sol";
import "./IVault.sol";
import "../token/BUMPToken.sol";
import "../access/BumperAccessControl.sol";
import "../treasury/Treasury.sol";

///@title Bumper Protocol Liquidity Provision Program (LPP) - Main Contract
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021
contract BumpMarketV2 is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    BumperAccessControl
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///@dev Interest rate not used
    struct Deposit {
        uint256 interest;
        uint256 balance;
        uint256 timestamp;
    }

    struct StableCoinDetail {
        address contractAddress;
        AggregatorV3Interface priceFeed;
    }

    struct TimePeriod {
        uint256 start;
        uint256 end;
    }

    enum StableCoins {USDC}

    ///@dev This maps an address to cumulative details of deposit made by an LP
    mapping(address => Deposit) public depositDetails;

    ///@dev This maps an address to number of USDC used to purchase BUMP tokens
    mapping(address => uint256) public usdcForBumpPurchase;

    ///@dev This map contains StableCoins enum in bytes form to the respective address
    mapping(bytes32 => StableCoinDetail) internal stableCoinsDetail;

    uint256 public currentTVL;

    ///@dev Represents the maximum percentage of their total deposit that an LP can use to buy BUMP
    ///@dev Decimal precision will be up to 2 decimals
    uint256 public maxBumpPercent;

    ///@dev Stores number of BUMP tokens available to be distributed as rewards during the LPP
    uint256 public bumpRewardAllocation;

    ///@dev Stores maximum number of BUMP tokens that can be purchased during the LPP
    uint256 public bumpPurchaseAllocation;

    ///@dev Address of USDC yearn vault where deposits will be sent to
    address public usdcVault;

    ///@dev 1a BUMP token address
    ///@notice To be replaced in future
    address public bumpTokenAddress;

    ///@dev 1a bUSDC token address
    ///@notice To be replaced in future
    address public busdcTokenAddress;

    ///@dev These will be constants used in TVL and BUMP price formulas
    ///@notice These constants have been carefully selected to calibrate BUMP price and reward rates
    uint256 public constant BUMP_INITAL_PRICE = 6000;
    uint256 public constant SWAP_RATE_CONSTANT = 8;
    uint256 public constant BUMP_REWARDS_BONUS_DRAG = 68;
    uint256 public constant BUMP_REWARDS_BONUS_DRAG_DIVIDER = 11000;
    uint256 public constant BUMP_REWARDS_FORMULA_CONSTANT = 6 * (10**7);

    ///@dev ---------------------- Below are the state variables added in version 2 ------------------------------

    ///@dev This is the percentage of withdrawal amount that is deducted as fees during withdrawal.
    uint256 public fee;

    ///@dev This is the percentage of withdrawal amount that is deducted as levy during withdrawal.
    uint256 public levy;

    ///@dev This is used for bump token price calculations.
    ///@dev swapRateParameter1 has decimal precision of 18.
    uint256 public swapRateParameter1;

    ///@dev This is used for bump token price calculations.
    ///@dev swapRateParameter2 has decimal precision of 4.
    uint256 public swapRateParameter2;

    ///@dev This stores total number of deposits made into the protocol.
    uint256 public totalDeposits;

    ///@dev This stores allowed period for swap BUSDC to BUMP
    TimePeriod public swapAllowedPeriod;

    ///@dev This is the percentage of reward has decimal precision of 2.
    uint256 public rewardPercent;

    address payable public treasuryAddress;

    ///@dev ------------------------ Here version 2 state variables ends -----------------------------------------

    ///@dev Emitted after an LP deposit is made
    event DepositMade(
        address indexed depositor,
        uint256 amount,
        uint256 interestRate
    );

    ///@dev Emitted when rewards are issued to the LP at the time of deposit
    event RewardIssued(address indexed rewardee, uint256 amount, uint256 price);

    ///@dev Emitted when BUMP is swapped for USDC during LPP
    event BumpPurchased(
        address indexed depositor,
        uint256 amount,
        uint256 price
    );

    ///@dev These events will be emitted when yearn related methods will be called by governance.
    event ApprovedAmountToYearnVault(
        string description,
        address sender,
        uint256 amount
    );
    event DepositedAmountToYearnVault(
        string description,
        address sender,
        uint256 amount
    );
    event AmountWithdrawnFromYearn(
        string description,
        address sender,
        uint256 burnedYearnTokens,
        uint256 amountWithdrawn
    );

    ///@dev These events will be emitted when respective governance parameters will change.
    event UpdatedMaxBumpPercent(
        string description,
        address sender,
        uint256 newMaxBumpPercent
    );
    event UpdatedBumpRewardAllocation(
        string description,
        address sender,
        uint256 newBumpRewardAllocation
    );
    event UpdatedBumpPurchaseAllocation(
        string description,
        address sender,
        uint256 newBumpPurchaseAllocation
    );

    ///@dev --------------------------- Below are the events added in version 2 --------------------------------
    event WithdrawUsdc(
        uint256 tokensBurnt,
        uint256 usdcWithdrawn,
        address indexed receiver
    );

    event UpdatedFee(
        string description,
        address indexed sender,
        uint256 newFee
    );

    event UpdatedLevy(
        string description,
        address indexed sender,
        uint256 newLevy
    );

    event UpdateSwapRateParameter1(
        string description,
        address indexed sender,
        uint256 newSwapRateParameter1
    );

    event UpdateSwapRateParameter2(
        string description,
        address indexed sender,
        uint256 newSwapRateParameter2
    );

    event UpdateTotalDeposits(
        string description,
        address indexed sender,
        uint256 newTotalDeposits
    );

    event UpdatedSwapAllowedPeriod(
        address indexed sender,
        uint256 start,
        uint256 end
    );

    event SwappedBUSDCToBUMP(address sender, uint256 amount);

    event PermittedForTransfer(
        address indexed owner,
        address indexed spender,
        uint256 value,
        uint256 deadline
    );

    event TransferUsdc(address indexed receiver, uint256 amount);

    event DepositType(
        address indexed sender,
        uint256 amount,
        uint256 depositType
    );

    event UpdatedRewardPercent(address indexed sender, uint256 percent);

    modifier lockWithdrawal {
        require(
            block.timestamp >= IBUSDC(busdcTokenAddress).unlockTimestamp(),
            "Withdrawal functionality can't be accessed before it's unlocked"
        );
        _;
    }

    modifier onlyTimestampPeriod(TimePeriod storage period) {
        uint256 curentTime = block.timestamp;
        require(
            curentTime >= period.start && curentTime <= period.end,
            "Forbidden time"
        );
        _;
    }

    ///@dev ------------------------------- Here version 2 events and modifier ends ------------------------------------
    ///@dev initialize function is removed from V2 , as there is no need to define it here again. It is called only once when deployng contracts for first time.

    ///@notice Swap BUSDC to BUMP.
    ///@param _amount Amount of BUSDC you want to swap to BUMP.
    function swap(uint256 _amount)
        external
        virtual
        whenNotPaused
        onlyTimestampPeriod(swapAllowedPeriod)
        returns (bool)
    {
        uint256 currBalance = depositDetails[msg.sender].balance;
        uint256 bumpTokensAsRewards;
        uint256 bumpTokensPurchased;
        require(_amount <= currBalance, "Not enough balance to swap");
        depositDetails[msg.sender].balance -= _amount;
        usdcForBumpPurchase[msg.sender] += _amount;

        IBUSDC(busdcTokenAddress).burn(msg.sender, _amount);

        (bumpTokensAsRewards, bumpTokensPurchased) = getBumpAllocation(
            0,
            _amount
        );

        if (bumpTokensAsRewards + bumpTokensPurchased > 0) {
            Treasury(treasuryAddress).withdraw(
                msg.sender,
                bumpTokenAddress,
                bumpTokensAsRewards + bumpTokensPurchased
            );
        }
        emit RewardIssued(
            msg.sender,
            bumpTokensAsRewards,
            getSwapRateBumpUsdc()
        );
        emit BumpPurchased(
            msg.sender,
            bumpTokensPurchased,
            getSwapRateBumpUsdc()
        );

        emit SwappedBUSDCToBUMP(msg.sender, bumpTokensPurchased);
        return true;
    }

    ///@notice This method pauses bUSDC token and can only be called by governance.
    function pauseProtocol() external virtual onlyGovernance {
        IBUSDC(busdcTokenAddress).pause();
        _pause();
    }

    ///@notice This method un-pauses bUSDC token and can only be called by governance.
    function unpauseProtocol() external virtual onlyGovernance {
        IBUSDC(busdcTokenAddress).unpause();
        _unpause();
    }

    ///@notice This returns a number of yUSDC tokens issued on the name of BumpMarket contract.
    ///@return amount returns the amount of yUSDC issued to BumpMarket by yearn vault.
    function getyUSDCIssuedToReserve()
        external
        view
        virtual
        returns (uint256 amount)
    {
        amount = IERC20Upgradeable(usdcVault).balanceOf(address(this));
    }

    ///@notice Transfers approved amount of asset ERC20 Tokens from user wallet to Reserve contract and further to yearn for yield farming. Mints bUSDC for netDeposit made to reserve and mints rewarded and purchased BUMP tokens
    ///@param _amount Amount of ERC20 tokens that need to be transfered.
    ///@param _amountForBumpPurchase Amount of deposit that user allocates for bump purchase.
    ///@param _coin Type of token.
    ///@param _depositType Type of deposit
    ///@dev This function was modified in version 2.
    function depositAmount(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin,
        uint256 _depositType
    ) external virtual nonReentrant whenNotPaused {
        _depositAmount(_amount, _amountForBumpPurchase, _coin, _depositType);
    }

    ///@notice Transfers approved amount of asset ERC20 Tokens from user wallet to Reserve contract and further to yearn for yield farming. Mints bUSDC for netDeposit made to reserve and mints rewarded and purchased BUMP tokens
    ///@param _amount Amount of ERC20 tokens that need to be transfered.
    ///@param _amountForBumpPurchase Amount of deposit that user allocates for bump purchase.
    ///@param _coin Type of token.
    ///@param deadline Permit deadline.
    ///@param _depositType Type of deposit
    ///@param v Permit v.
    ///@param r Permit r.
    ///@param s Permit s.
    function depositAmountWithPermit(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin,
        uint256 _depositType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual nonReentrant whenNotPaused {
        IERC20Permit(
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))]
                .contractAddress
        )
            .permit(msg.sender, address(this), _amount, deadline, v, r, s);

        _depositAmount(_amount, _amountForBumpPurchase, _coin, _depositType);

        emit PermittedForTransfer(msg.sender, address(this), _amount, deadline);
    }

    function _depositAmount(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin,
        uint256 _depositType
    ) private {
        uint256 bumpPurchasePercent =
            (_amountForBumpPurchase * 10000) / _amount;
        uint256 amountToDeposit = _amount - _amountForBumpPurchase;
        uint256 bumpTokensAsRewards;
        uint256 bumpTokensPurchased;
        require(
            bumpPurchasePercent <= maxBumpPercent,
            "Exceeded maximum deposit percentage that can be allocated for BUMP pruchase"
        );

        if (depositDetails[msg.sender].timestamp == 0) {
            depositDetails[msg.sender] = Deposit(
                0,
                amountToDeposit,
                block.timestamp
            );
        } else {
            depositDetails[msg.sender].balance =
                depositDetails[msg.sender].balance +
                amountToDeposit;
        }
        usdcForBumpPurchase[msg.sender] =
            usdcForBumpPurchase[msg.sender] +
            _amountForBumpPurchase;
        currentTVL = currentTVL + _amount;
        totalDeposits = totalDeposits + _amount;
        (bumpTokensAsRewards, bumpTokensPurchased) = getBumpAllocation(
            amountToDeposit,
            _amountForBumpPurchase
        );
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))]
                .contractAddress
        )
            .safeTransferFrom(msg.sender, address(this), _amount);
        ///Mint busdc tokens in user's name
        IBUSDC(busdcTokenAddress).mint(msg.sender, amountToDeposit);
        ///Mint BUMP tokens in user's name
        if (bumpTokensAsRewards + bumpTokensPurchased > 0) {
            Treasury(treasuryAddress).withdraw(
                msg.sender,
                bumpTokenAddress,
                bumpTokensAsRewards + bumpTokensPurchased
            );
        }
        _approveUSDCToYearnVault(_amount);
        _depositUSDCInYearnVault(_amount);
        emit DepositMade(msg.sender, amountToDeposit, 0);
        emit RewardIssued(
            msg.sender,
            bumpTokensAsRewards,
            getSwapRateBumpUsdc()
        );
        emit BumpPurchased(
            msg.sender,
            bumpTokensPurchased,
            getSwapRateBumpUsdc()
        );
        emit DepositType(msg.sender, _amount, _depositType);
    }

    ///@notice This acts like an external onlyGovernance interface for internal method _approveUSDCToYearnVault.
    ///@param _amount Amount of USDC you want to approve to yearn vault.
    function approveUSDCToYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        whenNotPaused
    {
        _approveUSDCToYearnVault(_amount);
        emit ApprovedAmountToYearnVault(
            "BUMPER ApprovedAmountToYearnVault",
            msg.sender,
            _amount
        );
    }

    //////@notice This acts like an external onlyGovernance interface for internal method _depositUSDCInYearnVault.
    ///@param _amount Amount of USDC you want to deposit to the yearn vault.
    function depositUSDCInYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        nonReentrant
        whenNotPaused
    {
        _depositUSDCInYearnVault(_amount);
        emit DepositedAmountToYearnVault(
            "BUMPER DepositedAmountToYearnVault",
            msg.sender,
            _amount
        );
    }

    ///@notice Withdraws USDC from yearn vault and burns yUSDC tokens
    ///@param _amount Amount of yUSDC tokens you want to burn
    ///@return Returns the amount of USDC redeemed.
    function withdrawUSDCFromYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        returns (uint256)
    {
        uint256 tokensRedeemed = IVault(usdcVault).withdraw(_amount);
        emit AmountWithdrawnFromYearn(
            "BUMPER AmountWithdrawnFromYearnVault",
            msg.sender,
            _amount,
            tokensRedeemed
        );
        return tokensRedeemed;
    }

    ///@notice This function in introduced in V2
    ///@notice Withdraws USDC from yearn vault, sends to address and burns yUSDC tokens
    ///@param _amount Amount of yUSDC tokens you want to withdraw
    ///@return Returns the amount of USDC redeemed.
    function withdrawUSDCFromYearnVaultToAddress(uint256 _amount)
        external
        virtual
        onlyGovernance
        nonReentrant
        returns (uint256)
    {
        uint256 tokensWithdrawn = IVault(usdcVault).withdraw(_amount);

        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeTransfer(msg.sender, tokensWithdrawn);

        emit AmountWithdrawnFromYearn(
            "BUMPER withdrawUSDCFromYearnVaultToAddress",
            msg.sender,
            _amount,
            tokensWithdrawn
        );
        emit TransferUsdc(msg.sender, tokensWithdrawn);
        return tokensWithdrawn;
    }

    ///@notice This function is used to update maxBumpPercent state variable by governance.
    ///@param _maxBumpPercent New value of maxBumpPercent state variable.
    ///@dev Decimal precision is 2
    function updateMaxBumpPercent(uint256 _maxBumpPercent)
        external
        virtual
        onlyGovernance
    {
        maxBumpPercent = _maxBumpPercent;
        emit UpdatedMaxBumpPercent(
            "BUMPER UpdatedMaxBUMPPercent",
            msg.sender,
            _maxBumpPercent
        );
    }

    ///@notice This function is used to update bumpRewardAllocation state variable by governance.
    ///@param _bumpRewardAllocation New value of bumpRewardAllocation state variable.
    ///@dev Decimal precision should be 18
    function updateBumpRewardAllocation(uint256 _bumpRewardAllocation)
        external
        virtual
        onlyGovernance
    {
        bumpRewardAllocation = _bumpRewardAllocation;
        emit UpdatedBumpRewardAllocation(
            "BUMPER UpdatedBUMPRewardAllocation",
            msg.sender,
            _bumpRewardAllocation
        );
    }

    ///@notice This function is used to update bumpPurchaseAllocation state variable by governance.
    ///@param _bumpPurchaseAllocation New value of bumpPurchaseAllocation state variable
    ///@dev Decimal precision should be 18
    function updateBumpPurchaseAllocation(uint256 _bumpPurchaseAllocation)
        external
        virtual
        onlyGovernance
    {
        bumpPurchaseAllocation = _bumpPurchaseAllocation;
        emit UpdatedBumpPurchaseAllocation(
            "BUMPER UpdatedBumpPurchaseAllocation",
            msg.sender,
            _bumpPurchaseAllocation
        );
    }

    ///@notice This function is used to update swap period.
    ///@param _start Beginning of the period
    ///@param _end End of period
    function updateSwapAllowedPeriod(uint256 _start, uint256 _end)
        external
        virtual
        onlyGovernance
    {
        require(
            _end >= _start,
            "The end of the period must be larger than the start"
        );
        swapAllowedPeriod = TimePeriod(_start, _end);
        emit UpdatedSwapAllowedPeriod(msg.sender, _start, _end);
    }

    ///@notice This function is used to update rewardPercent.
    ///@param percent Percent
    function updateRrewardPercent(uint256 percent)
        external
        virtual
        onlyGovernance
    {
        rewardPercent = percent;
        emit UpdatedRewardPercent(msg.sender, percent);
    }

    ///@notice This function returns a predicted swap rate for BUMP/USDC after a given deposit is made.
    ///@param _deposit It is the deposit amount for which it calculates swap rate.
    ///@return Returns swap rate for BUMP/USDC.
    ///@dev This function was modified in version 2.
    function estimateSwapRateBumpUsdc(uint256 _deposit)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 totalDepositsAfterDeposit = totalDeposits + _deposit;
        return
            ((totalDepositsAfterDeposit * swapRateParameter1) /
                (10**18 * 10**2)) + swapRateParameter2;
    }

    ///@notice This returns current price of stablecoin passed as an param.
    ///@param _coin Coin of which current price user wants to know.
    ///@return Returns price that it got from aggregator address provided.
    ///@dev Decimal precision of 8 decimals
    function getCurrentPrice(StableCoins _coin)
        public
        view
        virtual
        returns (int256)
    {
        AggregatorV3Interface priceFeed =
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))].priceFeed;
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    ///@notice This calculates what is the latest swap rate of BUMP/USDC
    ///@return Returns what is the swap rate of BUMP/USDC
    ///@dev This function was modified in version 2.
    /// 8215759267 * 8000000000000000000 / 10 ** 20 + 60000000 =  717260741,36
    /// 8215759267 * 8 / 10**11 + 6000 = 6000,65726074136
    /// 717260741,36 / 6000,65726074136 = 119530,3631241529981991136
    function getSwapRateBumpUsdc() public view virtual returns (uint256) {
        return
            ((totalDeposits * swapRateParameter1) / (10**18 * 10**2)) +
            swapRateParameter2;
    }

    ///@notice Calculates BUMP rewards that is issued to user
    ///@param _totalDeposit total deposit made by user
    ///@param _amountForPurchase Amount of usdc spent to buy BUMP tokens
    ///@return BUMP rewards that need to be transferred
    ///@dev This function was modified in version 2.
    function getBumpRewards(uint256 _totalDeposit, uint256 _amountForPurchase)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 currentTimestamp = block.timestamp;
        if (
            currentTimestamp < swapAllowedPeriod.start ||
            currentTimestamp > swapAllowedPeriod.end
        ) {
            return 0;
        }
        if (
            depositDetails[msg.sender].timestamp == 0 ||
            depositDetails[msg.sender].timestamp >= swapAllowedPeriod.start
        ) {
            return 0;
        }
        uint256 bumpRewards =
            (getBumpPurchaseAmount(_amountForPurchase) * rewardPercent) /
                (100 * 10**2);
        return bumpRewards;
    }

    ///@notice This function returns amount of BUMP tokens you will get for amount of usdc you want to use for purchase.
    ///@param _amountForPurchase Amount of USDC for BUMP purchase.
    ///@return Amount of BUMP tokens user will get.
    function getBumpPurchaseAmount(uint256 _amountForPurchase)
        internal
        view
        virtual
        returns (uint256)
    {
        //The reason we have multiplied numerator by 10**12 because decimal precision of BUMP token is 18
        //Given precision of _amountForPurchase is 6 , we need 12 more
        //And we have again multiplied it by 10**4 because , below swap rate is of precision 4
        uint256 bumpPurchaseAmount =
            (_amountForPurchase * 10**12 * 10**4) / (getSwapRateBumpUsdc());
        return bumpPurchaseAmount;
    }

    ///@notice Calculates amount of BUMP tokens that need to be transferred as rewards and as purchased amount
    ///@param _amountForDeposit Amount of USDC tokens deposited for which BUMP rewards need to be issued
    ///@param _amountForPurchase Amount of USDC tokens sent for the purchase of BUMP tokens
    ///@return Returns amount of BUMP tokens as rewards and amount of BUMP tokens purchased
    function getBumpAllocation(
        uint256 _amountForDeposit,
        uint256 _amountForPurchase
    ) internal virtual returns (uint256, uint256) {
        uint256 bumpRewards =
            getBumpRewards(
                (_amountForDeposit + _amountForPurchase),
                _amountForPurchase
            );
        require(
            bumpRewards <= bumpRewardAllocation,
            "Not enough BUMP Rewards left!"
        );
        bumpRewardAllocation = bumpRewardAllocation - bumpRewards;
        uint256 bumpPurchased = getBumpPurchaseAmount(_amountForPurchase);
        require(
            bumpPurchased <= bumpPurchaseAllocation,
            "Not enough BUMP left to purchase!"
        );
        bumpPurchaseAllocation = bumpPurchaseAllocation - bumpPurchased;
        return (bumpRewards, bumpPurchased);
    }

    ///@notice Approves USDC to yearn vault.
    ///@param _amount Amount of USDC you want to approve to yearn vault.
    function _approveUSDCToYearnVault(uint256 _amount)
        internal
        virtual
        whenNotPaused
    {
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeApprove(usdcVault, _amount);
    }

    ///@notice Deposits provided amount of USDC to yearn vault.
    ///@param _amount Amount of USDC you want to deposit to yearn vault.
    function _depositUSDCInYearnVault(uint256 _amount)
        internal
        virtual
        whenNotPaused
    {
        IVault(usdcVault).deposit(_amount);
    }

    ///@dev ----------------------- Below mentioned functions are the newly added functions in version 2. ------------------------

    ///@notice This function is used  by governance to update fee state variable.
    ///@param _fee New value for fee state variable.
    ///@dev It has a decimal precision of 2 decimals.
    function updateFee(uint256 _fee) external virtual onlyGovernance {
        fee = _fee;
        emit UpdatedFee("BUMPER UpdateFee", msg.sender, fee);
    }

    ///@notice This function is used by governance to update levy state variable.
    ///@param _levy New value for levy state variable.
    ///@dev It has a decimal precision of 2 decimals.
    function updateLevy(uint256 _levy) external virtual onlyGovernance {
        levy = _levy;
        emit UpdatedLevy("BUMPER UpdateLevy", msg.sender, levy);
    }

    ///@notice This function is used by governance to update swapRateParameter1 state variable.
    ///@param _swapRateParameter1 New value for swapRateParameter1 state variable.
    ///@dev swapRateParameter1 has a decimal precision of 18.
    function updateSwapRateParameter1(uint256 _swapRateParameter1)
        external
        virtual
        onlyGovernance
    {
        swapRateParameter1 = _swapRateParameter1;
        emit UpdateSwapRateParameter1(
            "BUMPER UpdateSwapRateParameter1",
            msg.sender,
            swapRateParameter1
        );
    }

    ///@notice This function is used by governance to update swapRateParameter2 state variable.
    ///@param _swapRateParameter2 New value for swapRateParameter2 state variable.
    ///@dev swapRateParameter2 have a decimal precision of 4.
    function updateSwapRateParameter2(uint256 _swapRateParameter2)
        external
        virtual
        onlyGovernance
    {
        swapRateParameter2 = _swapRateParameter2;
        emit UpdateSwapRateParameter2(
            "BUMPER UpdateSwapRateParameter2",
            msg.sender,
            swapRateParameter2
        );
    }

    function setTreasuryAddress(address payable _newTreasury) external onlyGovernance { 
        treasuryAddress= _newTreasury;
    }

    ///@notice This function is used by governance to initalize totalDeposits state variable.
    function totalDepositsInit() external virtual onlyGovernance {
        require(
            totalDeposits == 0,
            "TotalDeposits can only be initialized once"
        );
        totalDeposits = currentTVL;
        emit UpdateTotalDeposits(
            "BUMPER UpdateTotalDeposits",
            msg.sender,
            totalDeposits
        );
    }

    ///@notice Burn bUSDC tokens and calculate number of USDC tokens to transfer to user's account.
    ///@param amount Number of bUSDC tokens user wants to burn.
    ///@return true if everything is successful.
    function withdrawLiquidity(uint256 amount)
        external
        virtual
        lockWithdrawal
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(
            IBUSDC(busdcTokenAddress).balanceOf(msg.sender) >= amount,
            "User doesn't have enough bUSDC to burn"
        );
        return _withdrawLiquidity(msg.sender, amount);
    }

    ///@notice Burn bUSDC tokens and calculate number of USDC tokens to transfer to user's account.
    ///@param receiver This is the person whose tokens need to be burned.
    ///@param amount Number of bUSDC tokens user wants to burn.
    ///@return true if everything is successful.
    function withdrawLiquidity(address receiver, uint256 amount)
        public
        virtual
        lockWithdrawal
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(
            msg.sender == busdcTokenAddress,
            "This method is only callable by bUSDC token contract"
        );
        require(
            IBUSDC(busdcTokenAddress).balanceOf(receiver) >= amount,
            "User doesn't have enough bUSDC to burn"
        );
        return _withdrawLiquidity(receiver, amount);
    }

    function _withdrawLiquidity(address receiver, uint256 amount)
        internal
        returns (bool)
    {
        uint256 feeCalculated;
        uint256 levyCalculated;
        uint256 pricePerShare;
        uint256 yUSDCTokensBurn;
        uint256 tokensWithdrawn;
        uint256 amountAfterDeduduction;
        //calculate fees and levy and deduct it from USDC amount that will be transfered to user.
        feeCalculated = (fee * amount) / 10000;
        levyCalculated = (levy * amount) / 10000;
        amountAfterDeduduction = amount - (feeCalculated + levyCalculated);
        //calculate amount of yUSDC that need to be burn to get USDC.
        pricePerShare = IVault(usdcVault).pricePerShare();
        // Number of bUSDC tokens is equal to the number of USDC tokens deposited.
        // That's the reason for dividing by pricePerShare.
        yUSDCTokensBurn = ((amountAfterDeduduction * 1000000) / pricePerShare);
        // Deduct amount from depositDetails variable.
        depositDetails[receiver].balance =
            depositDetails[receiver].balance -
            amount;
        currentTVL = currentTVL - amountAfterDeduduction;
        //Burn user's bUSDC tokens
        IBUSDC(busdcTokenAddress).burn(receiver, amount);
        // Burn calculated amount of yUSDC tokens and withdraw USDC.
        tokensWithdrawn = IVault(usdcVault).withdraw(yUSDCTokensBurn);
        // Transfer withdrawn amount to user's account.
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeTransfer(receiver, tokensWithdrawn);
        emit WithdrawUsdc(amount, tokensWithdrawn, receiver);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

///@title  Bumper Liquidity Provision Program (LPP) - bUSDC ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUSDC will be BumpMarket
interface IBUSDC is IERC20Upgradeable {
    function unlockTimestamp() external returns (uint256);

    function pause() external;

    function unpause() external;

    function mint(address account, uint256 amount) external;

    function decimals() external returns (uint8);

    function updateUnlockTimestamp(uint256 _unlockTimestamp) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external returns (uint256);

    function withdrawAll() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../TimeLockMechanism.sol";
import "../access/BumperAccessControl.sol";

///@title  Bumper Liquidity Provision Program (LPP) - BUMP ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUMPToken is BumpMarket
contract BUMPToken is
    Initializable,
    ERC20PausableUpgradeable,
    TimeLockMechanism,
    BumperAccessControl
{
    ///@notice Will initialize state variables of this contract
    ///@param name_- Name of ERC20 token.
    ///@param symbol_- Symbol to be used for ERC20 token.
    ///@param _unlockTimestamp- Amount of duration for which certain functions are locked
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 _unlockTimestamp,
        uint256 bumpSupply,
        address[] memory _whitelistAddresses
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();
        _TimeLockMechanism_init(_unlockTimestamp);
        _BumperAccessControl_init(_whitelistAddresses);
        _mint(address(this), bumpSupply);
        _pause();
    }

    ///@notice This function is used by governance to pause BUMP token contract.
    function pause() external whenNotPaused onlyGovernance {
        _pause();
    }

    ///@notice This function is used by governance to un-pause BUMP token contract.
    function unpause() external whenPaused onlyGovernance {
        _unpause();
    }

    ///@notice This function is used by governance to increase supply of BUMP tokens.
    ///@param _increaseSupply Amount by which supply will increase.
    ///@dev So this basically mints new tokens in the name of protocol.
    function mint(uint256 _increaseSupply) external virtual onlyGovernance {
        _mint(address(this), _increaseSupply);
    }

    ///@notice This function updates unlockTimestamp variable
    ///@param _unlockTimestamp New deadline for lock in period
    function updateUnlockTimestamp(uint256 _unlockTimestamp)
        external
        virtual
        onlyGovernance
    {
        unlockTimestamp = _unlockTimestamp;
        emit UpdateUnlockTimestamp("", msg.sender, _unlockTimestamp);
    }

    ///@notice Called when distributing BUMP tokens from the protocol
    ///@param account- Account to which tokens are transferred
    ///@param amount- Amount of tokens transferred
    ///@dev Only governance or owner will be able to transfer these tokens
    function distributeToAddress(address account, uint256 amount)
        external
        virtual
        onlyGovernanceOrOwner
    {
        _transfer(address(this), account, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param recipient- Account to which tokens are transferred
    ///@param amount- Amount of tokens transferred
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param spender- Account to which tokens are approved
    ///@param amount- Amount of tokens approved
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param sender- Account which is transferring tokens
    ///@param recipient- Account which is receiving tokens
    ///@param amount- Amount of tokens being transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override timeLocked returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        require(whitelist[_msgSender()], "!whitelist");
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "!ownerOrWhitelist"
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../access/BumperAccessControl.sol";

contract Treasury is Initializable, BumperAccessControl {
  using SafeERC20 for IERC20;
  
  function initialize(address[] calldata _whitelist) 
    public 
    initializer 
  {
    _BumperAccessControl_init(_whitelist);
  }

  /// @notice Transfer tokens from the contract to the address.
  function withdraw(
      address to,
      address token,
      uint256 amount
  ) 
    external 
    onlyGovernanceOrOwner 
  {
      IERC20(token).safeTransfer(to, amount);
  }

  /// @notice Transfer ETH from the contract to the address.
  function withdrawETH(
      address payable to,
      uint256 amount
  ) 
    external 
    payable
    onlyGovernanceOrOwner 
  {
      to.transfer(amount);
  }

  /// @notice Execute transactions
  /// @param to Destination address of transaction.
  /// @param value Ether value of transaction.
  /// @param data Data payload of transaction.
  function execute(
      address to,
      uint256 value,
      bytes calldata data
  ) 
    external
    payable
    onlyGovernanceOrOwner
    returns (bytes memory)
  {
    require(AddressUpgradeable.isContract(to), "call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = to.call{value: value}(data);
    return AddressUpgradeable.verifyCallResult(success, returndata, "call failed");
  }

  /// @notice Receive Ether
  receive() external payable { }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

///@title TimeLockMechanism contains mechanism to lock functions for a specific period of time.
///@notice This contains modifier that can be used to lock functions for a certain period of time.
contract TimeLockMechanism is Initializable {
    uint256 public unlockTimestamp;

    event UpdateUnlockTimestamp(
        string description,
        address sender,
        uint256 newUnlockTimestamp
    );

    modifier timeLocked {
        require(
            block.timestamp >= unlockTimestamp,
            "Cannot access before token unlock"
        );
        _;
    }

    function _TimeLockMechanism_init(uint256 _unlockTimestamp)
        internal
        initializer
    {
        unlockTimestamp = _unlockTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}