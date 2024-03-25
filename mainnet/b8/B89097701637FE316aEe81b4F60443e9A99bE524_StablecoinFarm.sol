//SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IConversionPool.sol";

contract StablecoinFarm is Ownable, ReentrancyGuard {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    uint24 constant HUNDRED_PERCENT = 1e6;
    uint24 constant MIN_SLIPPAGE = 9e5;
    uint24 constant MAX_REFERRER_USER_FEE = 3e5;
    uint256 constant MIN_GLOBAL_AMOUNT = 1e20;
    uint256 constant REFERRAL_ID_LENGTH = 8;
    
    IConversionPool public conversionPool;
    IERC20 immutable public outputToken;
    IERC20 immutable public inputToken;
    IERC20 immutable public wUST;
    uint256 immutable MULTIPLIER;

    uint128 public autoGlobalAmount;
    address public feeCollector;
    address public manager;
    uint24 public feePercentage;
    uint24 public swapSlippage = 998000;
    uint24 public depositSlippage = HUNDRED_PERCENT;
    uint24 public withdrawSlippage = HUNDRED_PERCENT;

    struct User {
        uint128 depositedAmount;
        uint128 shares;
        uint128 pendingWithdrawAmount;
        uint128 yieldRegistered;
        string referrerId;
    }
    mapping(address => User) public users;

    struct GlobalState {
        uint128 totalPendingAmount;
        uint128 totalShares;
        uint128 totalPendingWithdrawAmount;
        uint128 totalPendingWithdrawShares;
    }
    GlobalState public globalState;
    
    struct Referrer {
        address referrer;
        uint24 userFee;
        uint24 baseFee;
    }
    mapping(string => Referrer) public referrers;

    event Deposit(address indexed user, string indexed referrerId, uint256 amount, uint256 shares, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 shares, uint256 timestamp, bool finished);
    event FinishWithdraw(address indexed user, uint256 amount);
    event GlobalDeposit(address sender, uint256 amountOut, uint256 timestamp);
    event GlobalWithdraw(address sender, uint256 shares, uint256 timestamp);
    event IncludeLeftover(address sender, uint256 leftover);
    event ChargeFee(address indexed user, string indexed referrerId, uint256 feeShares, uint256 baseFeeShares);
    event SetReferrer(string id, address referrer, uint24 userFee);
    event SlippageChange(uint256 newSlippage, uint256 slippageType);

    constructor(
        IConversionPool _conversionPool,
        IERC20 _inputToken, 
        IERC20 _outputToken, 
        IERC20 _wUST, 
        address _feeCollector,
        uint24 _feePercentage,
        uint128 _autoGlobalAmount,
        bool usingConversionPool
    ) {
        if (usingConversionPool) {
            require(_inputToken == _conversionPool.inputToken());
            require(_outputToken == _conversionPool.outputToken());
            require(_wUST == _conversionPool.proxyInputToken());
        }

        require(_feeCollector != address(0), "StablecoinFarm: zero address");
        require(_feePercentage <= HUNDRED_PERCENT, "StablecoinFarm: fee higher than 100%");
        MULTIPLIER = 10 ** (36 - IERC20Metadata(address(_inputToken)).decimals());

        conversionPool = _conversionPool;
        inputToken = _inputToken;
        outputToken = _outputToken;
        wUST = _wUST;

        feeCollector = _feeCollector;
        feePercentage = _feePercentage;
        autoGlobalAmount = _autoGlobalAmount;
        manager = msg.sender;
    }

    // =================== OWNER FUNCTIONS  =================== //

    function setFee(uint24 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= HUNDRED_PERCENT, "StablecoinFarm: fee higher than 100%");
        feePercentage = newFeePercentage;
    }

    function setAutoGlobalAmount(uint128 newValue) external onlyOwner {
        autoGlobalAmount = newValue;
    }

    function setFeeCollector(address newFeeCollector) external onlyOwner {
        feeCollector = newFeeCollector;
    }

    function setManager(address newManager) external onlyOwner {
        manager = newManager;
    }
    
    /**
        Only owner can modify fee on feePercentage part.
        @param id - referral id
        @param fee - moving this percentage of fees from feeCollector to the referrer address
    */
    function setReferrerFee(string calldata id, uint24 fee) external onlyOwner {
        require(referrers[id].referrer != address(0), "StablecoinFarm: invalid referral id");
        require(fee <= HUNDRED_PERCENT);
        referrers[id].baseFee = fee;
    }
    
    function setSlippage(uint24 newSlippage, uint8 slippageType) external {
        require(msg.sender == manager || msg.sender == owner(), "StablecoinFarm: unauthorized");
        require(newSlippage <= HUNDRED_PERCENT, "StablecoinFarm: slippage higher than 100%");
        require(newSlippage >= MIN_SLIPPAGE, "StablecoinFarm: invalid slippage");

        if (slippageType == 0) {
            swapSlippage = newSlippage;
        } else if (slippageType == 1) {
            depositSlippage = newSlippage;
        } else {
            withdrawSlippage = newSlippage;
        }

        emit SlippageChange(newSlippage, slippageType);
    }

    // =================== EXTERNAL FUNCTIONS  =================== //

    /**
        Single user deposit. User deposits token and the smart contract issues anchor shares to the user based on the share price.
        @param amount amount of token to deposit
     */
    function deposit(uint128 amount, string calldata referrerId) external nonReentrant returns (uint128 amountWithSlippage) {
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        amountWithSlippage = (uint256(amount) * depositSlippage / HUNDRED_PERCENT).toUint128();
        uint128 shares = (MULTIPLIER * amountWithSlippage / _feeder.exchangeRateOf(address(inputToken), true)).toUint128();
        require(shares > 0, "StablecoinFarm: 0 shares"); 

        _setUserReferrer(amount, referrerId);
        User storage user = users[msg.sender];
        user.shares += shares;
        user.depositedAmount += amountWithSlippage;

        if (globalState.totalPendingWithdrawShares >= shares) {
            globalState.totalPendingWithdrawShares -= shares;
        } else {
            globalState.totalPendingAmount += amount;
            globalState.totalShares += shares;
        }

        inputToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, referrerId, amountWithSlippage, shares, block.timestamp);

        if (amount * MULTIPLIER / 1e18 >= autoGlobalAmount) {
            _globalDeposit(globalState.totalPendingAmount);
        }
    }

    /**
        Sends back min(requestedAmount, maxWithdrawable) amount of token if there's enough balance. 
        If not, add sender's shares to the globalWithdraw pool and assign pendingWithdrawAmount to the sender.
        @param requestedAmount withdraw maximally this amount
     */
    function withdraw(uint128 requestedAmount) external nonReentrant returns (uint128 withdrawAmount, uint128 fee, bool finished) {
        User storage user = users[msg.sender];

        (uint128 maxWithdrawableAmount, uint128 _fee) = _chargeFee(msg.sender);
        fee = _fee;
        withdrawAmount = requestedAmount > maxWithdrawableAmount ? maxWithdrawableAmount : requestedAmount;
        require(withdrawAmount > 0, "StablecoinFarm: nothing to withdraw");
        uint128 sharesNeeded = (user.shares - uint256(maxWithdrawableAmount - withdrawAmount) * user.shares / maxWithdrawableAmount).toUint128();
        
        if (withdrawAmount <= globalState.totalPendingAmount) {
            // remove from pending deposits, tokens can be sent immediately
            globalState.totalPendingAmount -= withdrawAmount;
            globalState.totalShares -= sharesNeeded;
            finished = true;
        } else {
            globalState.totalPendingWithdrawShares += sharesNeeded;

            uint256 freeBalance;
            if (inputToken.balanceOf(address(this)) > globalState.totalPendingAmount) {
                freeBalance = inputToken.balanceOf(address(this)) - globalState.totalPendingAmount;
            }

            if (freeBalance >= withdrawAmount) {
                // enough balance, tokens can be sent immediately
                finished = true;
            } else {
                globalState.totalPendingWithdrawAmount += withdrawAmount;
                user.pendingWithdrawAmount += withdrawAmount;
            }
        }

        uint128 deductAmount = withdrawAmount;
        if (user.yieldRegistered > deductAmount) {
            user.yieldRegistered -= deductAmount;
            deductAmount = 0;
        } else {
            deductAmount -= user.yieldRegistered;
            user.yieldRegistered = 0;
        }
        if (user.depositedAmount > deductAmount) {
            user.depositedAmount -= deductAmount;
        } else {
            user.depositedAmount = 0;
        }

        user.shares -= sharesNeeded;
        if (finished) {
            inputToken.safeTransfer(msg.sender, withdrawAmount);
        } else {
            if (withdrawAmount * MULTIPLIER / 1e18 >= autoGlobalAmount) {
                _globalWithdraw(globalState.totalPendingWithdrawShares);
            }
        }
        emit Withdraw(msg.sender, withdrawAmount, fee, sharesNeeded, block.timestamp, finished);
    }
    
    /**
        Deposit totalPendingAmount into ETH Anchor.
        @param amount maximally this amount of pendingAmount
     */
    function globalDeposit(uint128 amount) external nonReentrant {
        _globalDeposit(amount);
    }

    /**
        Withdraws totalPendingWithdrawShares from ETH Anchor.
        @param shares maximally withdraw this amount of shares
     */
    function globalWithdraw(uint128 shares) external nonReentrant {
        _globalWithdraw(shares);
    }

    /**
        If there's not enough inputToken balance when a user calls withdraw function, 
        a pendingWithdrawAmount is assigned to him. This function sends them the pendingWithdrawAmount.
        @param userAddresses users to finish their withdraw for
        @param wUSTWithdraw whether to withdraw in UST
     */
    function finishWithdraws(address[] calldata userAddresses, bool wUSTWithdraw) external nonReentrant {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            User storage user = users[userAddress];
            uint128 pendingWithdrawAmount = user.pendingWithdrawAmount;
            require(pendingWithdrawAmount > 0, "StablecoinFarm: no pending withdraw amount");

            user.pendingWithdrawAmount = 0;
            globalState.totalPendingWithdrawAmount -= pendingWithdrawAmount;

            if (!wUSTWithdraw) {
                inputToken.safeTransfer(userAddress, pendingWithdrawAmount);
            } else {
                wUST.safeTransfer(userAddress, pendingWithdrawAmount);
            }
            
            emit FinishWithdraw(userAddress, pendingWithdrawAmount);
        }

        if (!wUSTWithdraw || inputToken == wUST) {
            require(inputToken.balanceOf(address(this)) >= globalState.totalPendingAmount, "StablecoinFarm: not enough balance");
        }
    }

    /**
        Charge fees manually.
        @param userAddresses charge fee to these users
     */
    function chargeFees(address[] calldata userAddresses) external {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            _chargeFee(userAddresses[i]);
        }
    }

    /**
        Useful when received more amount than expected after globalWithdraw.
     */
    function includeLeftover() external {
        uint128 leftover = (inputToken.balanceOf(address(this)) - globalState.totalPendingAmount - globalState.totalPendingWithdrawAmount).toUint128();
        globalState.totalPendingAmount += leftover;
        emit IncludeLeftover(msg.sender, leftover);
    }

    /**
        Anyone can create a referral object.
        @param id - referral id
        @param referrer - address receiving fees
        @param userFee - fee on user part where the base is the user maxWithdrawable with already deducted feePercentage
     */
    function setReferrer(string calldata id, address referrer, uint24 userFee) external {
        require(bytes(id).length == REFERRAL_ID_LENGTH, "StablecoinFarm: id invalid length");
        require(referrer != address(0), "StablecoinFarm: zero address");
        require(userFee <= MAX_REFERRER_USER_FEE, "StablecoinFarm: user fee too high");
        require(referrers[id].referrer == address(0) || referrers[id].referrer == msg.sender, "StablecoinFarm: unauthorized");

        referrers[id].referrer = referrer;
        referrers[id].userFee = userFee;
        emit SetReferrer(id, referrer, userFee);
    }

    // =================== INTERNAl FUNCTIONS  =================== //

    /**
        Move some shares of a user to the feeCollector. The fee is based only on yield, not on deposit plus yield.
        @param userAddress charge fee to this user
     */
    function _chargeFee(address userAddress) private returns (uint128 maxWithdrawableAmount, uint128 fee) {
        User storage user = users[userAddress];
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        maxWithdrawableAmount = (uint256(user.shares) * _feeder.exchangeRateOf(address(inputToken), true) * withdrawSlippage / MULTIPLIER / HUNDRED_PERCENT).toUint128();
        if (userAddress == feeCollector) return (maxWithdrawableAmount, 0);

        uint128 yieldRegistered = user.depositedAmount + user.yieldRegistered;
        uint128 yield = maxWithdrawableAmount > yieldRegistered ? maxWithdrawableAmount - yieldRegistered : 0;
        if (yield > 0) {
            uint256 referrerUserFeePercentage = uint256(referrers[user.referrerId].userFee) * (HUNDRED_PERCENT - feePercentage) / HUNDRED_PERCENT;
            uint256 absoluteFeePercentage = feePercentage + referrerUserFeePercentage;
            fee = (uint256(yield) * absoluteFeePercentage / HUNDRED_PERCENT).toUint128();
            uint128 feeShares = (user.shares - uint256(maxWithdrawableAmount - fee) * user.shares / maxWithdrawableAmount).toUint128();
            
            user.yieldRegistered += yield - fee;
            user.shares -= feeShares;
            maxWithdrawableAmount -= fee;

            (uint128 baseFeeShares) = _splitFee(fee, feeShares, user.referrerId, referrerUserFeePercentage);
            emit ChargeFee(userAddress, user.referrerId, feeShares, baseFeeShares);
        }
    }

    function _splitFee(
        uint128 fee, 
        uint128 feeShares, 
        string memory referrerId, 
        uint256 referrerUserFeePercentage
    ) private returns (uint128) {
        uint256 referrerFeePercentage = uint256(referrers[referrerId].baseFee) * feePercentage / HUNDRED_PERCENT;
        referrerFeePercentage += referrerUserFeePercentage;
        uint256 referrerFeeRatio = referrerFeePercentage * HUNDRED_PERCENT / (feePercentage + referrerUserFeePercentage);
        
        address referrer = referrers[referrerId].referrer;
        uint128 referrerFee = (uint256(fee) * referrerFeeRatio / HUNDRED_PERCENT).toUint128();
        uint128 referrerFeeShares = (uint256(feeShares) * referrerFeeRatio / HUNDRED_PERCENT).toUint128();
        users[referrer].depositedAmount += referrerFee;
        users[referrer].shares += referrerFeeShares;

        uint128 baseFee = fee - referrerFee;
        uint128 baseFeeShares = feeShares - referrerFeeShares;
        users[feeCollector].depositedAmount += baseFee;
        users[feeCollector].shares += baseFeeShares;
        return baseFeeShares;
    }

    function _setUserReferrer(uint128 amount, string calldata referrerId) private {
        require(bytes(referrerId).length == 0 || referrers[referrerId].referrer != address(0), "StablecoinFarm: invalid referral id");
        User storage user = users[msg.sender];

        if (amount > user.depositedAmount) {
            // change referrer if user deposited more
            _chargeFee(msg.sender); // charge fee before changing the referrer
            user.referrerId = referrerId;
        }
    }

    function _globalDeposit(uint128 amount) private {
        if (amount > globalState.totalPendingAmount) amount = globalState.totalPendingAmount;
        require(amount * MULTIPLIER / 1e18 >= MIN_GLOBAL_AMOUNT, "StablecoinFarm: not enough amount to deposit");
        
        uint256 minReceived = MULTIPLIER * amount * swapSlippage / HUNDRED_PERCENT / 1e18; // in wUST
        _anchorDeposit(amount, minReceived);

        globalState.totalPendingAmount -= amount;
        emit GlobalDeposit(msg.sender, amount, block.timestamp);
    }

    function _globalWithdraw(uint128 shares) private {
        if (shares > globalState.totalPendingWithdrawShares) shares = globalState.totalPendingWithdrawShares;
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        uint256 rate = _feeder.exchangeRateOf(address(inputToken), true);
        uint128 sharesValue = (uint256(shares) * rate / MULTIPLIER).toUint128();

        if (sharesValue > globalState.totalPendingAmount) {
            uint128 withdrawShares = shares;
            withdrawShares -= (MULTIPLIER * globalState.totalPendingAmount / rate).toUint128();
            globalState.totalPendingAmount = 0;

            require(withdrawShares >= MIN_GLOBAL_AMOUNT, "StablecoinFarm: not enough shares to withdraw");
            _anchorWithdraw(withdrawShares);
        } else {
            globalState.totalPendingAmount -= sharesValue;
        }

        globalState.totalShares -= shares;
        globalState.totalPendingWithdrawShares -= shares;
        emit GlobalWithdraw(msg.sender, shares, block.timestamp);
    }

    function _anchorDeposit(uint256 amount, uint256 minReceived) internal virtual {
        inputToken.safeIncreaseAllowance(address(conversionPool), amount);
        conversionPool.deposit(amount, minReceived);
    }

    function _anchorWithdraw(uint256 shares) internal virtual {
        outputToken.safeIncreaseAllowance(address(conversionPool), shares);
        conversionPool.redeem(shares);
    }

    // =================== VIEW FUNCTIONS  =================== //

    function getUserMaxWithdrawable(address userAddress) external view returns (uint128 maxWithdrawableAmount) {
        User storage user = users[userAddress];
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        maxWithdrawableAmount = (uint256(user.shares) * _feeder.exchangeRateOf(address(inputToken), true) * withdrawSlippage / MULTIPLIER / HUNDRED_PERCENT).toUint128();
        if (userAddress == feeCollector) return maxWithdrawableAmount;

        uint128 yieldRegistered = user.depositedAmount + user.yieldRegistered;
        uint128 yield = maxWithdrawableAmount > yieldRegistered ? maxWithdrawableAmount - yieldRegistered : 0;
        if (yield > 0) {
            uint256 referrerUserFeePercentage = uint256(referrers[user.referrerId].userFee) * (HUNDRED_PERCENT - feePercentage) / HUNDRED_PERCENT;
            uint256 absoluteFeePercentage = feePercentage + referrerUserFeePercentage;
            uint128 fee = (uint256(yield) * absoluteFeePercentage / HUNDRED_PERCENT).toUint128();
            maxWithdrawableAmount -= fee;
        }
    }

    function token() external view returns (IERC20) {
        return inputToken;
    }

    function aUST() external view returns (IERC20) {
        return outputToken;
    }

    function feeder() external view returns (IExchangeRateFeeder) {
        return conversionPool.feeder();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IExchangeRateFeeder.sol";

interface IConversionPool {
    function deposit(uint256 _amount, uint256 _minAmountOut) external;
    function redeem(uint256 _amount) external;
    function inputToken() external view returns (IERC20);
    function outputToken() external view returns (IERC20);
    function proxyInputToken() external view returns (IERC20);
    function feeder() external view returns (IExchangeRateFeeder);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IExchangeRateFeeder {
    function exchangeRateOf(address _token, bool _simulate) external view returns (uint256);
    function update(address _token) external;
}