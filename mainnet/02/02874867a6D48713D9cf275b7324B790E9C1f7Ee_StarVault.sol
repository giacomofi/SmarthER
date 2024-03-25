/*
                                   ./((((.
                               ((&&&&&&&&&&&((
                             (&&&&@@@@&&&&&&&&&(
                           (&&&@@@@@@@@@&&&&&&&&&(
                         #(&&@@@@@@@@@@@&&&&&&&&&&(
                        (#&&@@@@@@@@@@@@&&&&&&&&&&&(        /(((#%%&&%#((,
     /((#%%%%#(((/     *(&&@@@@@@@@@@@&&&&&&&&&&&&&&(  ((%&&&&&@@@@@@&&&&&&((
  (#&&&&@@@@@@@@&&&&#(#(&&&@@@@@@@@@@&&&&&&&&&&&&&&&%&&&&&&@@@@@@@@@@@&&&&&&%(
 (&&&&&@@@@@@@@@@@@@&&&&&&&&@@@@@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&&&&&&(
 (&&&&&@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@&&&&&&&&&&#(
 (&&&&&&&&@@@@@@@@@@@&&&%#(%%(#&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&&&&&&&&&&&#(
  (&&&&&&&&&&&&&&&&&&&%#(%%%(%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.
    (&&&&&&&&&&&&&&&&%(%&&(%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&((
      (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(
         ((&&&&&&&&&&&&&&&&&%#((%&&&&&&&&&&&&&&#((#%%%&&&%(&&&&&&&&((
           (#&&&&&&&&%(&&&%%%%%%%%&&&&&(&(#&&&&%%%%%%%%&&&(&&&&&&&&&&((
        ((&&&&&&&&&&&&(&&&%%%%%%%%&&&&&&&&&&&&&&%%%%%%&&&((&&&&&&&&&&&&(*
      ,#&&&&&&&&&&&&&&((&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(((((&&&&&&&&&&&&&&(
     (&&&&&&&&&&&&&&&&&((((((&&&&&&&&&&&&&&&&&&&&&&&&#((%&&&&&&&&&&&&&&&&&(
    (&&&&&&&&&&&&&&&&&&&&&%((&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&%(
    (&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&(&&&&&&&&&&&&&&&&&&&&&(
     (&&&&&&&&&&&&&&&&&&&&&&&(&&&&&&&&&&&(&&&&&@@@&&%(&&&&&&&&&&&&&&&&&&&&#.
      (%&&&&&&&&&&&&&&&&&&&&&%(&@@@@@@&&&((&&&@@@&&&((&&&&&&&&&&&&&&&&&&&(.
         *(%&&&&&&&&&&&&&&&&&(((%&&&&&&(*   /((((/   (&&&&&&&&&&&&&&&&%(
                *(((((((/,                             /((#%%%%#((((/
 - XxStarChadxX -
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol"; 

/**
 * @dev Contract implements a Pull Payments pattern for withdrawing funds based
 * on a pre-set vesting schedule.  Similar to OZ escrow contract, with added
 * vesting schedule.  Payees are only settable once, inside construction.
 *
 * Payees should not be contract addresses, these are explicitly disallowed in
 * claim functions for added safety.
 *
 * Vesting begins once {startTimer} is called, {startTimer} is only callable
 * once.  After vestDays + failSafeDays {claimAll} is unlocked.
 */
contract StarVault is Ownable, ReentrancyGuard {
  using Address for address payable;

  event Deposited(address indexed payee, uint weiAmount);
  event Withdrawn(address indexed payee, uint weiAmount);

  mapping(address => uint) public payeeLedger;
  uint public totalReceived = 0;

  /**
   * @dev initialized in {constructor}.
   */
  mapping(address => bool) public vaultPayees;
  uint private _cliffSeconds    = 0;
  uint private _vestSeconds     = 0;
  uint private _failsafeSeconds = 0;
  uint private _numPayees       = 0;

  /**
   * @dev initialized in {startTimer}.
   */
  uint256 public startTimestamp = 0;

  constructor(
    address[] memory payees,
    uint cliffDays,
    uint vestDays,
    uint failsafeDays
  ) {
    for (uint i = 0; i < payees.length; i++) {
      vaultPayees[payees[i]] = true;
    }
    _numPayees = payees.length;
    _cliffSeconds = cliffDays * 1 days;
    _vestSeconds = vestDays * 1 days;
    _failsafeSeconds = failsafeDays * 1 days;
  }

  /**
   * @dev Ensures vesting schedule has begun, and msg.sender is a valid payee.
   */
  modifier claimCompliance(address payee) {
    require(
      vaultPayees[msg.sender],
      "Invalid payee"
    );
    require(
      startTimestamp > 0,
      "Vest timestamp not set"
    );
    require(
      address(this).balance > 0,
      "Contract balance is 0"
    );
    require(
      msg.sender == payee,
      "Claim must be for self"
    );
    require(
      msg.sender == tx.origin,
      "Caller cannot be contract"
    );
    _;
  }

  /**
   * @dev Once callable function to start vesting schedule.
   */
  function startTimer()
    public
    onlyOwner
  {
    require(
      startTimestamp == 0,
      "Timer already started"
    );
    startTimestamp = block.timestamp;
  }

  /**
   * @dev Special failsafe claim in the event any funds go un-claimed.
   */
  function claimAll(address payable payee)
    public
    claimCompliance(payee)
    nonReentrant()
  {
    require(
      block.timestamp > startTimestamp + _vestSeconds + _failsafeSeconds,
      "It is too early to claimAll"
    );

    uint payment = address(this).balance;
    Address.sendValue(payee, payment);
    emit Withdrawn(payee, payment);
  }

  /**
   * @dev Claim pays out all available funds to payee.
   */
  function claim(address payable payee)
    public 
    claimCompliance(payee)
    nonReentrant()
  {
    uint payment = maxClaimable(payee);
    payeeLedger[payee] = payeeLedger[payee] + payment;
    payee.sendValue(payment);
    emit Withdrawn(payee, payment);
  }

  /**
   * @dev Returns max claimable by the provided payee.
   */
  function maxClaimable(address payee)
    public
    view
    virtual
    claimCompliance(payee)
    returns (uint claimableWei)
  {
    require(
      msg.sender == payee,
      "Claim must be for self"
    );
    if (block.timestamp < startTimestamp + _cliffSeconds) {
      return 0;
    }
    uint _maxPayable = totalReceived / _numPayees;
    uint _secondsElapsed = block.timestamp - startTimestamp;
    return _maxPayable * _secondsElapsed / _vestSeconds - payeeLedger[payee];
  }

  receive() external payable {
    totalReceived = totalReceived + msg.value;
    emit Deposited(msg.sender, msg.value);
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