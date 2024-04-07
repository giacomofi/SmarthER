// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./interface/IWETH9.sol";
import "./interface/IRegistry.sol";
import "./interface/IPolicyManager.sol";
import "./interface/ITreasury.sol";
import "./interface/IVault.sol";


/**
 * @title Treasury
 * @author solace.fi
 * @notice The war chest of Castle Solace.
 *
 * As policies are purchased, premiums will flow from [**policyholders**](/docs/protocol/policy-holder) to the `Treasury`. By default `Treasury` reroutes 100% of the premiums into the [`Vault`](./Vault) where it is split amongst the [**capital providers**](/docs/user-guides/capital-provider/cp-role-guide).
 *
 * If a [**policyholder**](/docs/protocol/policy-holder) updates or cancels a policy they may receive a refund. Refunds will be paid out from the [`Vault`](./Vault). If there are not enough funds to pay out the refund in whole, the [`unpaidRefunds()`](#unpaidrefunds) will be tracked and can be retrieved later via [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can change the premium recipients via [`setPremiumRecipients()`](#setpremiumrecipients). This can be used to add new building blocks to Castle Solace or enact a protocol fee. Premiums can be stored in the `Treasury` and managed with a number of functions.
 */
contract Treasury is ITreasury, ReentrancyGuard, Governable {
    using Address for address;
    using SafeERC20 for IERC20;

    // Registry
    IRegistry internal _registry;

    // Wrapped ether.
    IWETH9 internal _weth;

    address internal constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable[] internal _premiumRecipients;
    uint32[] internal _recipientWeights;
    uint32 internal _weightSum;

    // The amount of **ETH** that a user is owed if any.
    mapping(address => uint256) internal _unpaidRefunds;

    /**
     * @notice Constructs the Treasury contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of registry.
     */
    constructor(address governance_, address registry_) Governable(governance_) {
        // set registry
        require(registry_ != address(0x0), "zero address registry");
        _registry = IRegistry(registry_);
        // set weth
        address weth_ = _registry.weth();
        require(weth_ != address(0x0), "zero address weth");
        _weth = IWETH9(payable(weth_));
        // if vault is deployed, route 100% of the premiums to it
        address vault_ = _registry.vault();
        if (vault_ != address(0x0)) {
            _premiumRecipients = [payable(vault_)];
            _recipientWeights = [1,0];
            _weightSum = 1;
        } // if vault is not deployed, hold 100% of the premiums in the treasury
    }

    /***************************************
    FUNDS IN
    ***************************************/

    /**
     * @notice Routes the **premiums** to the `recipients`.
     * Each recipient will receive a `recipientWeight / weightSum` portion of the premiums.
     * Will be called by products with `msg.value = premium`.
     */
    function routePremiums() external payable override nonReentrant {
        // preload variables
        uint256 div = _weightSum;
        uint256 length = _premiumRecipients.length;
        // transfer to all recipients
        for(uint i = 0; i < length; i++) {
            uint256 amount = msg.value * _recipientWeights[i] / div;
            if (amount > 0) {
                // this call may fail. let it
                // funds will be safely stored in treasury
                _premiumRecipients[i].call{value: amount, gas: 100000}(""); // IGNORE THIS WARNING
            }
        }
        // hold treasury share as eth
        emit PremiumsRouted(msg.value);
    }

    /**
     * @notice Number of premium recipients.
     * @return count The number of premium recipients.
     */
    function numPremiumRecipients() external view override returns (uint256 count) {
        return _premiumRecipients.length;
    }

    /**
     * @notice Gets the premium recipient at `index`.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()-1]`.
     * @return recipient The receipient address.
     */
    function premiumRecipient(uint256 index) external view override returns (address recipient) {
        return _premiumRecipients[index];
    }

    /**
     * @notice Gets the weight of the recipient.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()]`.
     * @return weight The recipient weight.
     */
    function recipientWeight(uint256 index) external view override returns (uint32 weight) {
        return _recipientWeights[index];
    }

    /**
     * @notice Gets the sum of all premium recipient weights.
     * @return weight The sum of weights.
     */
    function weightSum() external view override returns (uint32 weight) {
        return _weightSum;
    }

    /***************************************
    FUNDS OUT
    ***************************************/

    /**
     * @notice Refunds some **ETH** to the user.
     * Will attempt to send the entire `amount` to the `user`.
     * If there is not enough available at the moment, it is recorded and can be pulled later via [`withdraw()`](#withdraw).
     * Can only be called by active products.
     * @param user The user address to send refund amount.
     * @param amount The amount to send the user.
     */
    function refund(address user, uint256 amount) external override nonReentrant {
        // check if from active product
        require(IPolicyManager(_registry.policyManager()).productIsActive(msg.sender), "!product");
        _transferEth(user, amount);
    }

    /**
     * @notice The amount of **ETH** that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidRefunds(address user) external view override returns (uint256 amount) {
        return _unpaidRefunds[user];
    }

    /**
     * @notice Transfers the unpaid refunds to the user.
     */
    function withdraw() external override nonReentrant {
        _transferEth(msg.sender, 0);
    }

    /**
     * @notice Transfers **ETH** to the user. It's called by [`refund()`](#refund) and [`withdraw()`](#withdraw) functions in the contract.
     * Also adds on their unpaid refunds, and stores new unpaid refunds if necessary.
     * @param user The user to pay.
     * @param amount The amount to pay _before_ unpaid funds.
     */
    function _transferEth(address user, uint256 amount) internal {
        require(user != address(0x0), "zero address recipient");
        // account for unpaid rewards
        uint256 unpaidRefunds1 = _unpaidRefunds[user];
        amount += unpaidRefunds1;
        if(amount == 0) return;
        // transfer amount from vault
        if (_registry.vault() != address(0)) IVault(payable(_registry.vault())).requestEth(amount);
        // unwrap weth if necessary
        if(address(this).balance < amount) {
            uint256 diff = amount - address(this).balance;
            _weth.withdraw(Math.min(_weth.balanceOf(address(this)), diff));
        }
        // send eth
        uint256 transferAmount = Math.min(address(this).balance, amount);
        uint256 unpaidRefunds2 = amount - transferAmount;
        if(unpaidRefunds2 != unpaidRefunds1) _unpaidRefunds[user] = unpaidRefunds2;
        Address.sendValue(payable(user), transferAmount);
        emit EthRefunded(user, transferAmount);
    }

    /***************************************
    FUND MANAGEMENT
    ***************************************/

    /**
     * @notice Sets the premium recipients and their weights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param recipients The premium recipients, plus an implicit `address(treasury)` at the end.
     * @param weights The recipient weights.
     */
    function setPremiumRecipients(address payable[] calldata recipients, uint32[] calldata weights) external override onlyGovernance {
        // check recipient - weight map
        require(recipients.length + 1 == weights.length, "length mismatch");
        uint256 length = weights.length;
        require(length <= 16, "too many recipients");
        uint32 sum = 0;
        for(uint256 i = 0; i < length; i++) sum += weights[i];
        if(length > 1) require(sum > 0, "1/0");
        // delete old recipients
        delete _premiumRecipients;
        delete _recipientWeights;
        // set new recipients
        _weightSum = sum;
        _premiumRecipients = recipients;
        _recipientWeights = weights;
        emit RecipientsSet();
    }

    /**
     * @notice Spends an **ERC20** token or **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param token The address of the token to spend.
     * @param amount The amount of the token to spend.
     * @param recipient The address of the token receiver.
     */
    function spend(address token, uint256 amount, address recipient) external override nonReentrant onlyGovernance {
        require(token != address(0x0), "zero address token");
        require(recipient != address(0x0), "zero address recipient");
        // transfer eth
        if(token == _ETH_ADDRESS) Address.sendValue(payable(recipient), amount);
        // transfer token
        else IERC20(token).safeTransfer(recipient, amount);
        // emit event
        emit FundsSpent(token, amount, recipient);
    }

    /**
     * @notice Wraps some **ETH** into **WETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to wrap.
     */
    function wrap(uint256 amount) external override onlyGovernance {
        _weth.deposit{value: amount}();
    }

    /**
     * @notice Unwraps some **WETH** into **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to unwrap.
     */
    function unwrap(uint256 amount) external override onlyGovernance {
        _weth.withdraw(amount);
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    receive () external payable override { }

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    fallback () external payable override { }
}

// SPDX-License-Identifier: MIT

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./interface/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: NONE
// code borrowed from https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code

// Copyright (C) 2015, 2016, 2017 Dapphub

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

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IWETH9
 * @author Dapphub
 * @notice [Wrapped Ether](https://weth.io/) smart contract. Extends **ERC20**.
 */
interface IWETH9 is IERC20Metadata {

    /// @notice Emitted when **ETH** is wrapped.
    event Deposit(address indexed dst, uint wad);
    /// @notice Emitted when **ETH** is unwrapped.
    event Withdrawal(address indexed src, uint wad);

    /**
     * @notice Wraps Ether. **WETH** will be minted to the sender at 1 **ETH** : 1 **WETH**.
     */
    receive() external payable;

    /**
     * @notice Wraps Ether. **WETH** will be minted to the sender at 1 **ETH** : 1 **WETH**.
     */
    fallback () external payable;

    /**
     * @notice Wraps Ether. **WETH** will be minted to the sender at 1 **ETH** : 1 **WETH**.
     */
    function deposit() external payable;

    /**
     * @notice Unwraps Ether. **ETH** will be returned to the sender at 1 **ETH** : 1 **WETH**.
     * @param wad Amount to unwrap.
     */
    function withdraw(uint wad) external;
}


/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * Note that `Registry` doesn't track all Solace contracts. FarmController is tracked in [`OptionsFarming`](../OptionsFarming), farms are tracked in FarmController, Products are tracked in [`PolicyManager`](../PolicyManager), and the `Registry` is untracked.
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    // Emitted when WETH is set.
    event WethSet(address weth);
    // Emitted when Vault is set.
    event VaultSet(address vault);
    // Emitted when ClaimsEscrow is set.
    event ClaimsEscrowSet(address claimsEscrow);
    // Emitted when Treasury is set.
    event TreasurySet(address treasury);
    // Emitted when PolicyManager is set.
    event PolicyManagerSet(address policyManager);
    // Emitted when RiskManager is set.
    event RiskManagerSet(address riskManager);
    // Emitted when Solace Token is set.
    event SolaceSet(address solace);
    // Emitted when OptionsFarming is set.
    event OptionsFarmingSet(address optionsFarming);
    // Emitted when FarmController is set.
    event FarmControllerSet(address farmController);
    // Emitted when Locker is set.
    event LockerSet(address locker);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [**WETH**](../WETH9) contract.
     * @return weth_ The address of the [**WETH**](../WETH9) contract.
     */
    function weth() external view returns (address weth_);

    /**
     * @notice Gets the [`Vault`](../Vault) contract.
     * @return vault_ The address of the [`Vault`](../Vault) contract.
     */
    function vault() external view returns (address vault_);

    /**
     * @notice Gets the [`ClaimsEscrow`](../ClaimsEscrow) contract.
     * @return claimsEscrow_ The address of the [`ClaimsEscrow`](../ClaimsEscrow) contract.
     */
    function claimsEscrow() external view returns (address claimsEscrow_);

    /**
     * @notice Gets the [`Treasury`](../Treasury) contract.
     * @return treasury_ The address of the [`Treasury`](../Treasury) contract.
     */
    function treasury() external view returns (address treasury_);

    /**
     * @notice Gets the [`PolicyManager`](../PolicyManager) contract.
     * @return policyManager_ The address of the [`PolicyManager`](../PolicyManager) contract.
     */
    function policyManager() external view returns (address policyManager_);

    /**
     * @notice Gets the [`RiskManager`](../RiskManager) contract.
     * @return riskManager_ The address of the [`RiskManager`](../RiskManager) contract.
     */
    function riskManager() external view returns (address riskManager_);

    /**
     * @notice Gets the [**SOLACE**](../SOLACE) contract.
     * @return solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function solace() external view returns (address solace_);

    /**
     * @notice Gets the [`OptionsFarming`](../OptionsFarming) contract.
     * @return optionsFarming_ The address of the [`OptionsFarming`](../OptionsFarming) contract.
     */
    function optionsFarming() external view returns (address optionsFarming_);

    /**
     * @notice Gets the [`FarmController`](../FarmController) contract.
     * @return farmController_ The address of the [`FarmController`](../FarmController) contract.
     */
    function farmController() external view returns (address farmController_);

    /**
     * @notice Gets the [`Locker`](../Locker) contract.
     * @return locker_ The address of the [`Locker`](../Locker) contract.
     */
    function locker() external view returns (address locker_);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [**WETH**](../WETH9) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     */
    function setWeth(address weth_) external;

    /**
     * @notice Sets the [`Vault`](../Vault) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     */
    function setVault(address vault_) external;

    /**
     * @notice Sets the [`Claims Escrow`](../ClaimsEscrow) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     */
    function setClaimsEscrow(address claimsEscrow_) external;

    /**
     * @notice Sets the [`Treasury`](../Treasury) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     */
    function setTreasury(address treasury_) external;

    /**
     * @notice Sets the [`Policy Manager`](../PolicyManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     */
    function setPolicyManager(address policyManager_) external;

    /**
     * @notice Sets the [`Risk Manager`](../RiskManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     */
    function setRiskManager(address riskManager_) external;

    /**
     * @notice Sets the [**SOLACE**](../SOLACE) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function setSolace(address solace_) external;

    /**
     * @notice Sets the [`OptionsFarming`](../OptionsFarming) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param optionsFarming_ The address of the [`OptionsFarming`](../OptionsFarming) contract.
     */
    function setOptionsFarming(address optionsFarming_) external;

    /**
     * @notice Sets the [`FarmController`](../FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmController_ The address of the [`FarmController`](../FarmController) contract.
     */
    function setFarmController(address farmController_) external;

    /**
     * @notice Sets the [`Locker`](../Locker) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setLocker(address locker_) external;

    /**
     * @notice Sets multiple contracts in one call.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     * @param optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     * @param farmController_ The address of the [`FarmController`](./FarmController) contract.
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setMultiple(
        address weth_,
        address vault_,
        address claimsEscrow_,
        address treasury_,
        address policyManager_,
        address riskManager_,
        address solace_,
        address optionsFarming_,
        address farmController_,
        address locker_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721Enhanced.sol";

/**
 * @title IPolicyManager
 * @author solace.fi
 * @notice The **PolicyManager** manages the creation of new policies and modification of existing policies.
 *
 * Most users will not interact with **PolicyManager** directly. To buy, modify, or cancel policies, users should use the respective [**product**](../products/BaseProduct) for the position they would like to cover. Use **PolicyManager** to view policies.
 *
 * Policies are [**ERC721s**](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721).
 */
interface IPolicyManager is IERC721Enhanced {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a policy is created.
    event PolicyCreated(uint256 policyID);
    /// @notice Emitted when a policy is updated.
    event PolicyUpdated(uint256 indexed policyID);
    /// @notice Emitted when a policy is burned.
    event PolicyBurned(uint256 policyID);
    /// @notice Emitted when the policy descriptor is set.
    event PolicyDescriptorSet(address policyDescriptor);
    /// @notice Emitted when a new product is added.
    event ProductAdded(address product);
    /// @notice Emitted when a new product is removed.
    event ProductRemoved(address product);

    /***************************************
    POLICY VIEW FUNCTIONS
    ***************************************/

    /// @notice PolicyInfo struct.
    struct PolicyInfo {
        uint256 coverAmount;
        address product;
        uint40 expirationBlock;
        uint24 price;
        bytes positionDescription;
    }

    /**
     * @notice Information about a policy.
     * @param policyID The policy ID to return info.
     * @return info info in a struct.
     */
    function policyInfo(uint256 policyID) external view returns (PolicyInfo memory info);

    /**
     * @notice Information about a policy.
     * @param policyID The policy ID to return info.
     * @return policyholder The address of the policy holder.
     * @return product The product of the policy.
     * @return coverAmount The amount covered for the policy.
     * @return expirationBlock The expiration block of the policy.
     * @return price The price of the policy.
     * @return positionDescription The description of the covered position(s).
     */
    function getPolicyInfo(uint256 policyID) external view returns (address policyholder, address product, uint256 coverAmount, uint40 expirationBlock, uint24 price, bytes calldata positionDescription);

    /**
     * @notice The holder of the policy.
     * @param policyID The policy ID.
     * @return policyholder The address of the policy holder.
     */
    function getPolicyholder(uint256 policyID) external view returns (address policyholder);

    /**
     * @notice The product used to purchase the policy.
     * @param policyID The policy ID.
     * @return product The product of the policy.
     */
    function getPolicyProduct(uint256 policyID) external view returns (address product);

    /**
     * @notice The expiration block of the policy.
     * @param policyID The policy ID.
     * @return expirationBlock The expiration block of the policy.
     */
    function getPolicyExpirationBlock(uint256 policyID) external view returns (uint40 expirationBlock);

    /**
     * @notice The cover amount of the policy.
     * @param policyID The policy ID.
     * @return coverAmount The cover amount of the policy.
     */
    function getPolicyCoverAmount(uint256 policyID) external view returns (uint256 coverAmount);

    /**
     * @notice The cover price in wei per block per wei multiplied by 1e12.
     * @param policyID The policy ID.
     * @return price The price of the policy.
     */
    function getPolicyPrice(uint256 policyID) external view returns (uint24 price);

    /**
     * @notice The byte encoded description of the covered position(s).
     * Only makes sense in context of the product.
     * @param policyID The policy ID.
     * @return positionDescription The description of the covered position(s).
     */
    function getPositionDescription(uint256 policyID) external view returns (bytes calldata positionDescription);

    /*
     * @notice These functions can be used to check a policys stage in the lifecycle.
     * There are three major lifecycle events:
     *   1 - policy is bought (aka minted)
     *   2 - policy expires
     *   3 - policy is burnt (aka deleted)
     * There are four stages:
     *   A - pre-mint
     *   B - pre-expiration
     *   C - post-expiration
     *   D - post-burn
     * Truth table:
     *               A B C D
     *   exists      0 1 1 0
     *   isActive    0 1 0 0
     *   hasExpired  0 0 1 0

    /**
     * @notice Checks if a policy is active.
     * @param policyID The policy ID.
     * @return status True if the policy is active.
     */
    function policyIsActive(uint256 policyID) external view returns (bool);

    /**
     * @notice Checks whether a given policy is expired.
     * @param policyID The policy ID.
     * @return status True if the policy is expired.
     */
    function policyHasExpired(uint256 policyID) external view returns (bool);

    /// @notice The total number of policies ever created.
    function totalPolicyCount() external view returns (uint256 count);

    /// @notice The address of the [`PolicyDescriptor`](./PolicyDescriptor) contract.
    function policyDescriptor() external view returns (address);

    /***************************************
    POLICY MUTATIVE FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new policy.
     * Can only be called by **products**.
     * @param policyholder The receiver of new policy token.
     * @param coverAmount The policy coverage amount (in wei).
     * @param expirationBlock The policy expiration block number.
     * @param price The coverage price.
     * @param positionDescription The description of the covered position(s).
     * @return policyID The policy ID.
     */
    function createPolicy(
        address policyholder,
        uint256 coverAmount,
        uint40 expirationBlock,
        uint24 price,
        bytes calldata positionDescription
    ) external returns (uint256 policyID);

    /**
     * @notice Modifies a policy.
     * Can only be called by **products**.
     * @param policyID The policy ID.
     * @param coverAmount The policy coverage amount (in wei).
     * @param expirationBlock The policy expiration block number.
     * @param price The coverage price.
     * @param positionDescription The description of the covered position(s).
     */
    function setPolicyInfo(uint256 policyID, uint256 coverAmount, uint40 expirationBlock, uint24 price, bytes calldata positionDescription) external;

    /**
     * @notice Burns expired or cancelled policies.
     * Can only be called by **products**.
     * @param policyID The ID of the policy to burn.
     */
    function burn(uint256 policyID) external;

    /**
     * @notice Burns expired policies.
     * @param policyIDs The list of expired policies.
     */
    function updateActivePolicies(uint256[] calldata policyIDs) external;

    /***************************************
    PRODUCT VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Checks is an address is an active product.
     * @param product The product to check.
     * @return status True if the product is active.
     */
    function productIsActive(address product) external view returns (bool status);

    /**
     * @notice Returns the number of products.
     * @return count The number of products.
     */
    function numProducts() external view returns (uint256 count);

    /**
     * @notice Returns the product at the given index.
     * @param productNum The index to query.
     * @return product The address of the product.
     */
    function getProduct(uint256 productNum) external view returns (address product);

    /***************************************
    OTHER VIEW FUNCTIONS
    ***************************************/

    function activeCoverAmount() external view returns (uint256);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new product.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product the new product
     */
    function addProduct(address product) external;

    /**
     * @notice Removes a product.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product the product to remove
     */
    function removeProduct(address product) external;


    /**
     * @notice Set the token descriptor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyDescriptor The new token descriptor address.
     */
    function setPolicyDescriptor(address policyDescriptor) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title ITreasury
 * @author solace.fi
 * @notice The war chest of Castle Solace.
 *
 * As policies are purchased, premiums will flow from [**policyholders**](/docs/protocol/policy-holder) to the `Treasury`. By default `Treasury` reroutes 100% of the premiums into the [`Vault`](../Vault) where it is split amongst the [**capital providers**](/docs/user-guides/capital-provider/cp-role-guide).
 *
 * If a [**policyholder**](/docs/protocol/policy-holder) updates or cancels a policy they may receive a refund. Refunds will be paid out from the [`Vault`](../Vault). If there are not enough funds to pay out the refund in whole, the [`unpaidRefunds()`](#unpaidrefunds) will be tracked and can be retrieved later via [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can change the premium recipients via [`setPremiumRecipients()`](#setpremiumrecipients). This can be used to add new building blocks to Castle Solace or enact a protocol fee. Premiums can be stored in the `Treasury` and managed with a number of functions.
 */
interface ITreasury {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a token is spent.
    event FundsSpent(address token, uint256 amount, address recipient);
    /// @notice Emitted when premium recipients are set.
    event RecipientsSet();
    /// @notice Emitted when premiums are routed.
    event PremiumsRouted(uint256 amount);
    /// @notice Emitted when ETH is refunded to a user.
    event EthRefunded(address user, uint256 amount);

    /***************************************
    FUNDS IN
    ***************************************/

    /**
     * @notice Routes the **premiums** to the `recipients`.
     * Each recipient will receive a `recipientWeight / weightSum` portion of the premiums.
     * Will be called by products with `msg.value = premium`.
     */
    function routePremiums() external payable;

    /**
     * @notice Number of premium recipients.
     * @return count The number of premium recipients.
     */
    function numPremiumRecipients() external view returns (uint256 count);

    /**
     * @notice Gets the premium recipient at `index`.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()-1]`.
     * @return recipient The receipient address.
     */
    function premiumRecipient(uint256 index) external view returns (address recipient);

    /**
     * @notice Gets the weight of the recipient.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()]`.
     * @return weight The recipient weight.
     */
    function recipientWeight(uint256 index) external view returns (uint32 weight);

    /**
     * @notice Gets the sum of all premium recipient weights.
     * @return weight The sum of weights.
     */
    function weightSum() external view returns (uint32 weight);

    /***************************************
    FUNDS OUT
    ***************************************/

    /**
     * @notice Refunds some **ETH** to the user.
     * Will attempt to send the entire `amount` to the `user`.
     * If there is not enough available at the moment, it is recorded and can be pulled later via [`withdraw()`](#withdraw).
     * Can only be called by active products.
     * @param user The user address to send refund amount.
     * @param amount The amount to send the user.
     */
    function refund(address user, uint256 amount) external;

    /**
     * @notice The amount of **ETH** that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidRefunds(address user) external view returns (uint256 amount);

    /**
     * @notice Transfers the unpaid refunds to the user.
     */
    function withdraw() external;

    /***************************************
    FUND MANAGEMENT
    ***************************************/

    /**
     * @notice Sets the premium recipients and their weights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param recipients The premium recipients, plus an implicit `address(this)` at the end.
     * @param weights The recipient weights.
     */
    function setPremiumRecipients(address payable[] calldata recipients, uint32[] calldata weights) external;

    /**
     * @notice Spends an **ERC20** token or **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param token The address of the token to spend.
     * @param amount The amount of the token to spend.
     * @param recipient The address of the token receiver.
     */
    function spend(address token, uint256 amount, address recipient) external;

    /**
     * @notice Wraps some **ETH** into **WETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to wrap.
     */
    function wrap(uint256 amount) external;

    /**
     * @notice Unwraps some **WETH** into **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to unwrap.
     */
    function unwrap(uint256 amount) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    receive() external payable;

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    fallback () external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

import "./IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title IVault
 * @author solace.fi
 * @notice The risk-backing capital pool.
 *
 * [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can deposit **ETH** or **WETH** into the `Vault` to mint shares. Shares are represented as **CP tokens** aka **SCP** and extend `ERC20`. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) should use [`depositEth()`](#depositeth) or [`depositWeth()`](#depositweth), not regular **ETH** or **WETH** transfer.
 *
 * As [**Policyholders**](/docs/protocol/policy-holder) purchase coverage, premiums will flow into the capital pool and are split amongst the [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide). If a loss event occurs in an active policy, some funds will be used to payout the claim. These events will affect the price per share but not the number or distribution of shares.
 *
 * By minting shares of the `Vault`, [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) willingly accept the risk that the whole or a part of their funds may be used payout claims. A malicious [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) could detect a loss event and try to withdraw their funds before claims are paid out. To prevent this, the `Vault` uses a cooldown mechanic such that while the [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) is not in cooldown mode (default) they can mint, send, and receive **SCP** but not withdraw **ETH**. To withdraw their **ETH**, the [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) must `startCooldown()`(#startcooldown), wait no less than `cooldownMin()`(#cooldownmin) and no more than `cooldownMax()`(#cooldownmax), then call `withdrawEth()`(#withdraweth) or `withdrawWeth()`(#withdrawweth). While in cooldown mode users cannot send or receive **SCP** and minting shares will take them out of cooldown.
 */
interface IVault is IERC20Metadata, IERC20Permit {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a user deposits funds.
    event DepositMade(address indexed depositor, uint256 indexed amount, uint256 indexed shares);
    /// @notice Emitted when a user withdraws funds.
    event WithdrawalMade(address indexed withdrawer, uint256 indexed value);
    /// @notice Emitted when funds are sent to a requestor.
    event FundsSent(uint256 value);
    /// @notice Emitted when deposits are paused.
    event Paused();
    /// @notice Emitted when deposits are unpaused.
    event Unpaused();
    /// @notice Emitted when a user enters cooldown mode.
    event CooldownStarted(address user);
    /// @notice Emitted when a user leaves cooldown mode.
    event CooldownStopped(address user);
    /// @notice Emitted when the cooldown window is set.
    event CooldownWindowSet(uint40 cooldownMin, uint40 cooldownMax);
    /// @notice Emitted when a requestor is added.
    event RequestorAdded(address requestor);
    /// @notice Emitted when a requestor is removed.
    event RequestorRemoved(address requestor);

    /***************************************
    CAPITAL PROVIDER FUNCTIONS
    ***************************************/

    /**
     * @notice Allows a user to deposit **ETH** into the `Vault`(becoming a **Capital Provider**).
     * Shares of the `Vault` (CP tokens) are minted to caller.
     * It is called when `Vault` receives **ETH**.
     * It issues the amount of token share respected to the deposit to the `recipient`.
     * Reverts if `Vault` is paused.
     * @return shares The number of shares minted.
     */
    function depositEth() external payable returns (uint256 shares);

    /**
     * @notice Allows a user to deposit **WETH** into the `Vault`(becoming a **Capital Provider**).
     * Shares of the Vault (CP tokens) are minted to caller.
     * It issues the amount of token share respected to the deposit to the `recipient`.
     * Reverts if `Vault` is paused.
     * @param amount Amount of weth to deposit.
     * @return shares The number of shares minted.
     */
    function depositWeth(uint256 amount) external returns (uint256);

    /**
     * @notice Starts the cooldown.
     */
    function startCooldown() external;

    /**
     * @notice Stops the cooldown.
     */
    function stopCooldown() external;

    /**
     * @notice Allows a user to redeem shares for **ETH**.
     * Burns **SCP** and transfers **ETH** to the [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide).
     * @param shares Amount of shares to redeem.
     * @return value The amount in **ETH** that the shares where redeemed for.
     */
    function withdrawEth(uint256 shares) external returns (uint256 value);

    /**
     * @notice Allows a user to redeem shares for **WETH**.
     * Burns **SCP** tokens and transfers **WETH** to the [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide).
     * @param shares amount of shares to redeem.
     * @return value The amount in **WETH** that the shares where redeemed for.
     */
    function withdrawWeth(uint256 shares) external returns (uint256 value);

    /***************************************
    CAPITAL PROVIDER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The price of one **SCP**.
     * @return price The price in **ETH**.
     */
    function pricePerShare() external view returns (uint256 price);

    /**
     * @notice Returns the maximum redeemable shares by the `user` such that `Vault` does not go under **MCR**(Minimum Capital Requirement). May be less than their balance.
     * @param user The address of user to check.
     * @return shares The max redeemable shares by the user.
     */
    function maxRedeemableShares(address user) external view returns (uint256 shares);

    /**
     * @notice Returns the total quantity of all assets held by the `Vault`.
     * @return assets The total assets under control of this vault.
    */
    function totalAssets() external view returns (uint256 assets);

    /// @notice The minimum amount of time a user must wait to withdraw funds.
    function cooldownMin() external view returns (uint40);

    /// @notice The maximum amount of time a user must wait to withdraw funds.
    function cooldownMax() external view returns (uint40);

    /**
     * @notice The timestamp that a depositor's cooldown started.
     * @param user The depositor.
     * @return start The timestamp in seconds.
     */
    function cooldownStart(address user) external view returns (uint40 start);

    /**
     * @notice Returns true if the user is allowed to receive or send vault shares.
     * @param user User to query.
     * return status True if can transfer.
     */
    function canTransfer(address user) external view returns (bool status);

    /**
     * @notice Returns true if the user is allowed to withdraw vault shares.
     * @param user User to query.
     * return status True if can withdraw.
     */
    function canWithdraw(address user) external view returns (bool status);

    /// @notice Returns true if the vault is paused.
    function paused() external view returns (bool paused_);

    /***************************************
    REQUESTOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sends **ETH** to other users or contracts.
     * Can only be called by authorized requestors.
     * @param amount Amount of **ETH** wanted.
     */
    function requestEth(uint256 amount) external;

    /**
     * @notice Returns true if the destination is authorized to request **ETH**.
     * @param dst Account to check requestability.
     * @return status True if requestor, false if not.
     */
    function isRequestor(address dst) external view returns (bool status);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Pauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * While paused:
     * 1. No users may deposit into the Vault.
     * 2. Withdrawls can bypass cooldown.
     * 3. Only Governance may unpause.
    */
    function pause() external;

    /**
     * @notice Unpauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function unpause() external;

    /**
     * @notice Sets the `minimum` and `maximum` amount of time in seconds that a user must wait to withdraw funds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param cooldownMin_ Minimum time in seconds.
     * @param cooldownMax_ Maximum time in seconds.
     */
    function setCooldownWindow(uint40 cooldownMin_, uint40 cooldownMax_) external;

    /**
     * @notice Adds requesting rights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param requestor The requestor to grant rights.
     */
    function addRequestor(address requestor) external;

    /**
     * @notice Removes requesting rights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param requestor The requestor to revoke rights.
     */
    function removeRequestor(address requestor) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive *ETH*.
     * Does _not_ mint shares.
     */
    receive () external payable;

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     * Does _not_ mint shares.
     */
    fallback () external payable;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC721Enhanced
 * @author solace.fi
 * @notice An extension of `ERC721`.
 *
 * The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and better enumeration.
 */
interface IERC721Enhanced is IERC721Enumerable {

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) external;

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) external;

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view returns (uint256 nonce);

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 seperator);

    /***************************************
    BETTER ENUMERATION
    ***************************************/

    /**
     * @notice Lists all tokens.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokens() external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Lists the tokens owned by `owner`.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokensOfOwner(address owner) external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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