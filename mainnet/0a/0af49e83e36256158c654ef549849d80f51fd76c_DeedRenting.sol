/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// File: contracts/abstract/IProvisioningDelegation.sol


pragma solidity 0.8.9;

/**
 * @dev Interface of DeedProvisioning contract Delegation methods.
 */
interface IProvisioningDelegation {

  function setDelegatee(address _address, uint256 _nftId) external returns(bool);

  function getDelegatee(uint256 _nftId) view external returns(address);

}


// File: contracts/abstract/Roles.sol


pragma solidity 0.8.9;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {

    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view
        returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}



// File: contracts/abstract/IERC20.sol


pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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



// File: contracts/abstract/IERC1155.sol


pragma solidity 0.8.9;

interface IERC1155 {
    // Events
    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferSingle(address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount);

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferBatch(address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts);

    /**
     * @dev MUST emit when an approval is updated
     */
    event ApprovalForAll(address indexed _owner,
        address indexed _operator,
        bool _approved);

    /**
     * @dev MUST emit when the URI is updated for a token ID
     *   URIs are defined in RFC 3986
     *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
     */
    event URI(string _uri, uint256 indexed _id);

    /**
     * @notice Transfers amount of an _id from the _from address to the _to address specified
     * @dev MUST emit TransferSingle event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    )
        external;

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @dev MUST emit TransferBatch event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if length of `_ids` is not the same as length of `_amounts`
     * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    )
        external;

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view
        returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    )
        external
        view
        returns (
            uint256[] memory
        )
    ;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @dev MUST emit the ApprovalForAll event on success
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner      The owner of the Tokens
     * @param _operator   Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        view
        returns (
            bool isOperator
        )
    ;
}

// File: contracts/abstract/Context.sol


pragma solidity 0.8.9;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



// File: contracts/abstract/Ownable.sol


pragma solidity 0.8.9;


// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/abstract/SafeMath.sol


pragma solidity 0.8.9;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     * 
     * Counterpart to Solidity's `+` operator.
     * 
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     * 
     * Counterpart to Solidity's `-` operator.
     * 
     * Requirements:
     * - Subtraction cannot overflow.
     * 
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     * 
     * Counterpart to Solidity's `*` operator.
     * 
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     * 
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * 
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     * 
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * 
     * Requirements:
     * - The divisor cannot be zero.
     * 
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     * 
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     * 
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     * 
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     * 
     * Requirements:
     * - The divisor cannot be zero.
     * 
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



// File: contracts/abstract/ManagerRole.sol


pragma solidity 0.8.9;





/**
 * @title ManagerRole
 * @dev Owner is responsible to add/remove manager
 */
contract ManagerRole is Context, Ownable {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private _managers;

    modifier onlyManager() {
        require(isManager(_msgSender()), "ManagerRole: caller does not have the Manager role");
        _;
    }

    function isManager(address account) public view returns (bool) {
        return _managers.has(account);
    }

    function addManager(address account) public onlyOwner {
        _addManager(account);
    }

    function removeManager(address account) public onlyOwner {
        _removeManager(account);
    }

    function _addManager(address account) internal {
        _managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _managers.remove(account);
        emit ManagerRemoved(account);
    }
}



// File: contracts/abstract/ProvisioningManager.sol


pragma solidity 0.8.9;





/**
 * @title ProvisioningManager
 * @dev Contract Responsible to manage access on provisioning management
 */
abstract contract ProvisioningManager {

    function isProvisioningManager(address account, uint256 deedId) external virtual view returns (bool);

}
// File: contracts/abstract/Address.sol


pragma solidity 0.8.9;

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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

                // solhint-disable-next-line no-inline-assembly
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



// File: contracts/abstract/UUPSUpgradeable.sol


// File: .deps/npm/@openzeppelin/contracts/utils/StorageSlot.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;


/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// File: .deps/npm/@openzeppelin/contracts/proxy/beacon/IBeacon.sol


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: .deps/npm/@openzeppelin/contracts/interfaces/draft-IERC1822.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File: .deps/npm/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;





/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// File: .deps/npm/@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;



/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// File: contracts/abstract/Initializable.sol


// File: .deps/npm/@openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

// File: contracts/DeedRenting.sol


pragma solidity 0.8.9;










/**
 * @title Deed Renting Contract
 */
contract DeedRenting is UUPSUpgradeable, Initializable, ProvisioningManager, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant MONTH_IN_SECONDS = 2629800;

    uint256 public constant DAY_IN_SECONDS = 1 days;

    struct DeedLease {
        uint256 id; // Unique identifier for a Lease And the same used for Offer
        uint256 deedId;
        uint16 paidMonths; // Number of Paid months
        uint256 paidRentsDate; // Paid Rents End Date
        uint256 noticePeriodDate; // End Date of notice Period by considering paid rents
        uint256 leaseStartDate; // Lease Effective Start/Acquired Date
        uint256 leaseEndDate; // Lease Effective End Date
        address tenant; // Tenant Address who acquired the offer
    }

    struct DeedOffer {
        uint256 id; // Unique identifier for a Lease And Offer
        uint256 deedId;
        address creator; // Original Renter/Offer Creator
        uint16 months; // Number of months to rent
        uint8 noticePeriod; // Number of months of Notice Period
        uint256 price; // Monthly Rent Amount
        uint256 allDurationPrice; // All Rental Duration Price For Discount If proposed
        uint256 offerStartDate; // Offer Start Date
        uint256 offerExpirationDate; // Offer Expiration Date
        uint8 offerExpirationDays; // Offer Expiration Date
        address authorizedTenant; // Tenant Address who is authorized to acquire the offer
        uint8 ownerMintingPercentage; // Owner Minting Percentage
    }

    event OfferCreated(
        uint256 indexed id,
        uint256 indexed deedId,
        address owner
    );

    event OfferUpdated(
        uint256 indexed id,
        uint256 indexed deedId,
        address owner
    );

    event OfferDeleted(
        uint256 indexed id,
        uint256 indexed deedId,
        address owner
    );

    event RentPaid(
        uint256 indexed id,
        uint256 indexed deedId,
        address tenant,
        address owner,
        uint16 paidMonths,
        bool firstRent
    );

    event TenantEvicted(
        uint256 indexed id,
        uint256 indexed deedId,
        address tenant,
        address owner,
        uint16 leaseRemainingMonths
    );

    event LeaseEnded(
        uint256 indexed id,
        uint256 indexed deedId,
        address tenant,
        uint16 leaseRemainingMonths
    );

    IERC20 public meed;

    IERC1155 public deed;

    IProvisioningDelegation public tenantProvisioning;

    uint256 public offersCount;

    // Lease/Offer ID => DeedLease
    mapping(uint256 => DeedOffer) public deedOffers;

    // Lease/Offer ID => DeedLease
    mapping(uint256 => DeedLease) public deedLeases;

    // Deed ID => List of lease IDs
    mapping(uint256 => uint256[]) public leases;

    /**
     * @dev Throws if called by any account other than the owner of the NFT.
     */
    modifier onlyDeedOwner(uint256 _deedId) {
        require(deed.balanceOf(_msgSender(), _deedId) > 0, "DeedRenting#NotOwnerOfDeed");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner of the NFT
     * identified using Lease ID.
     */
    modifier onlyDeedOwnerByLeaseId(uint256 _offerId) {
        require(deed.balanceOf(_msgSender(), deedOffers[_offerId].deedId) > 0, "DeedRenting#NotOwnerOfDeed");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner of the NFT.
     */
    modifier isReceiverDeedOwnerByLeaseId(uint256 _offerId, address _deedOwner) {
        require(deed.balanceOf(_deedOwner, deedOffers[_offerId].deedId) > 0, "DeedRenting#ReceiverNotOwnerOfDeed");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner of the NFT.
     */
    modifier notDeedOwnerByLeaseId(uint256 _offerId) {
        require(deed.balanceOf(_msgSender(), deedOffers[_offerId].deedId) == 0, "DeedRenting#DeedOwnerCantAcquireHisOwnOffer");
        _;
    }

    /**
     * @dev Throws when offer id isn't currently assigned to the NFT Id
     */
    modifier isDeedOffer(uint256 _offerId, uint256 _deedId) {
        require(_deedId == deedOffers[_offerId].deedId, "DeedRenting#NotAdequateDeedForOffer");
        _;
    }

    /**
     * @dev Throws if offer creator isn't the NFT owner anymore.
     */
    modifier isOfferCreatorDeedOwner(uint256 _offerId) {
        require(deed.balanceOf(deedOffers[_offerId].creator, deedOffers[_offerId].deedId) > 0, "DeedRenting#DeedOwnerChangedThusInvalidOffer");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner of the NFT
     * identified using Lease ID.
     */
    modifier onlyOfferCreator(uint256 _offerId) {
        require(deedOffers[_offerId].creator == _msgSender(), "DeedRenting#NotOfferCreator");
        _;
    }

    /**
     * @dev Throws if lease offer has been already acquired.
     */
    modifier notAcquiredOffer(uint256 _offerId) {
        require(deedLeases[_offerId].leaseStartDate == 0, "DeedRenting#OfferAlreadyAcquiredByTenant");
        _;
    }

    /**
     * @dev Throws if offer has a start date that is less than last acquired offer end date.
     */
    modifier hasOfferValidStartDate(uint256 _deedId, uint256 _offerStartDate) {
        if (_offerStartDate == 0) {
            _offerStartDate = block.timestamp;
        }
        for (uint i = 0; i < leases[_deedId].length; i++) {
            require(_offerStartDate >= deedLeases[leases[_deedId][i]].leaseEndDate, "DeedRenting#InvalidOfferStartDate");
        }
        _;
    }

    /**
     * @dev Throws if Rent months is 0 or Notice months is more than Rent months
     */
    modifier isValidOfferPeiod(uint16 _months, uint8 _noticePeriod) {
        require(_months > 0, "DeedRenting#RentalDurationMustBePositive");
        require(_noticePeriod < _months, "DeedRenting#NoticePeriodMustBeLessThanRentalDuration");
        _;
    }

    /**
     * @dev Throws if offer is meant to a different Tenant Address.
     */
    modifier isAuthorizedTenant(uint256 _offerId) {
        if (deedOffers[_offerId].authorizedTenant != address(0)) {
          require(deedOffers[_offerId].authorizedTenant == _msgSender(), "DeedRenting#OfferNotAuthorizedForAddress");
        }
        _;
    }

    /**
     * @dev Throws if offer had expired or has a start date that is less than last acquired offer end date
     */
    modifier isOfferNotExpired(uint256 _offerId) {
        DeedOffer storage offer = deedOffers[_offerId];
        if (offer.offerExpirationDate > 0) {
          require(offer.offerExpirationDate > block.timestamp, "DeedRenting#OfferExpired");
        }
        for (uint i = 0; i < leases[offer.deedId].length; i++) {
          uint256 leaseId = leases[offer.deedId][i];
          require(offer.offerStartDate >= deedLeases[leaseId].leaseEndDate, "DeedRenting#OfferExpiredInvalidOfferStartDate");
        }
        _;
    }

    /**
     * @dev Throws if Percentage is more than 100
     */
    modifier isPercentageValid(uint8 _percentage) {
        require(_percentage <= 100, "DeedRenting#InvalidPercentageValue");
        _;
    }

    /**
     * @dev Throws if neither "price" nor "all duration price" are strictly positive number or both are set
     */
    modifier isValidPrice(uint256 _price, uint256 _allDurationPrice) {
        require(_price > 0 || _allDurationPrice > 0, "DeedRenting#InvalidOfferPrice");
        require(_price == 0 || _allDurationPrice == 0, "DeedRenting#EitherMonthlyRentOrAllDurationPrice");
        _;
    }

    /**
     * @dev Throws if current address isn't the current Deed Tenant/Provisioning Manager
     */
    modifier onlyDeedTenant(uint256 _leaseId) {
        DeedLease storage lease = deedLeases[_leaseId];
        require(lease.tenant == _msgSender(), "DeedRenting#NotDeedManager");
        _;
    }

    /**
     * @dev Throws if Lease Contract is already ended
     */
    modifier isOngoingLease(uint256 _leaseId) {
        DeedLease storage lease = deedLeases[_leaseId];
        require(lease.leaseEndDate > block.timestamp && lease.leaseEndDate > lease.noticePeriodDate, "DeedRenting#LeaseAlreadyEnded");
        _;
    }

    /**
     * @dev Throws if Deed tenant isn't the current address
     */
    modifier isRentNotPaid(uint256 _leaseId) {
        DeedLease storage lease = deedLeases[_leaseId];
        require(lease.paidRentsDate < block.timestamp, "DeedRenting#TenantHasAlreadyPaidDueRents");
        _;
    }

    /**
     * This method replaces the constructor since this is about an Upgradable Contract
     */
    function initialize(
        IERC20 _meed,
        IERC1155 _deed,
        IProvisioningDelegation _tenantProvisioning
    )
        virtual
        public
        initializer {

        meed = _meed;
        deed = _deed;
        tenantProvisioning = _tenantProvisioning;
        _transferOwnership(_msgSender());
    }

    /**
     * @dev This method allows to a Deed NFT owner to create a renting offer
     */
    function createOffer(
        DeedOffer memory _offer
    )
        public
        onlyDeedOwner(_offer.deedId)
        hasOfferValidStartDate(_offer.deedId, _offer.offerStartDate)
        isValidOfferPeiod(_offer.months, _offer.noticePeriod)
        isPercentageValid(_offer.ownerMintingPercentage)
        isValidPrice(_offer.price, _offer.allDurationPrice) {

        offersCount = offersCount.add(1);
        _offer.id = offersCount;

        _setOffer(_offer);
        _setTenantProvisioningDelegatee(_offer.deedId);

        emit OfferCreated(
          _offer.id,
          _offer.deedId,
          _msgSender()
        );
    }

    /**
     * @dev This method allows to a Deed NFT owner to update a renting offer
     */
    function updateOffer(DeedOffer memory _offer)
        public
        isDeedOffer(_offer.id, _offer.deedId)
        onlyDeedOwner(_offer.deedId)
        onlyOfferCreator(_offer.id)
        notAcquiredOffer(_offer.id)
        hasOfferValidStartDate(_offer.deedId, _offer.offerStartDate)
        isValidOfferPeiod(_offer.months, _offer.noticePeriod)
        isPercentageValid(_offer.ownerMintingPercentage) {

        _setOffer(_offer);

        emit OfferUpdated(
          _offer.id,
          _offer.deedId,
          _msgSender()
        );
    }

    /**
     * @dev This method allows to a Deed NFT owner to delete a renting offer
     */
    function deleteOffer(uint256 _id)
        public
        onlyDeedOwnerByLeaseId(_id)
        notAcquiredOffer(_id) {

        uint256 deedId = deedOffers[_id].deedId;
        delete deedOffers[_id];

        emit OfferDeleted(
          _id,
          deedId,
          _msgSender()
        );
    }

    /**
     * @dev This method allows to acquire an offer by a Tenant
     */
    function acquireRent(uint256 _id, uint8 _monthsToPay)
        public
        notAcquiredOffer(_id)
        isAuthorizedTenant(_id)
        isOfferNotExpired(_id)
        notDeedOwnerByLeaseId(_id)
        isOfferCreatorDeedOwner(_id) {

        DeedOffer storage offer = deedOffers[_id];

        uint8 overallMonthsToPay = offer.noticePeriod + _monthsToPay;
        require(_monthsToPay > 0, "DeedRenting#AtLeastOneMonthPayment");
        require(overallMonthsToPay <= offer.months, "DeedRenting#ExceedsRemainingMonthsToPay");

        uint256 amount;
        if (offer.allDurationPrice > 0 && overallMonthsToPay == offer.months) {
          amount = offer.allDurationPrice;
        } else {
          amount = offer.price.mul(overallMonthsToPay);
        }
        require(meed.transferFrom(_msgSender(), offer.creator, amount), "DeedRenting#DeedRentingPaymentFailed");

        uint256 leaseStartDate;
        if (offer.offerStartDate > block.timestamp) {
            leaseStartDate = offer.offerStartDate;
        } else {
            leaseStartDate = block.timestamp;
        }
        DeedLease memory lease = DeedLease({
            id: offer.id,
            deedId: offer.deedId,
            leaseStartDate: leaseStartDate,
            leaseEndDate: leaseStartDate.add(MONTH_IN_SECONDS.mul(offer.months)),
            paidRentsDate: leaseStartDate.add(MONTH_IN_SECONDS.mul(_monthsToPay)),
            noticePeriodDate: leaseStartDate.add(MONTH_IN_SECONDS.mul(overallMonthsToPay)),
            paidMonths: overallMonthsToPay,
            tenant: _msgSender()
        });
        deedLeases[lease.id] = lease;
        leases[lease.deedId].push(_id);

        emit RentPaid(_id, lease.deedId, _msgSender(), offer.creator, lease.paidMonths, true);
    }

    /**
     * @dev This method allows to pay a Rent by Tenant
     */
    function payRent(uint256 _id, address _deedOwner, uint8 _monthsToPay)
        public
        isReceiverDeedOwnerByLeaseId(_id, _deedOwner)
        onlyDeedTenant(_id)
        isOngoingLease(_id) {

        DeedOffer storage offer = deedOffers[_id];
        DeedLease storage lease = deedLeases[_id];

        require(_monthsToPay > 0, "DeedRenting#AtLeastOneMonthPayment");
        require((offer.months - lease.paidMonths) >= _monthsToPay, "DeedRenting#ExceedsRemainingMonthsToPay");

        uint256 amount = offer.price.mul(_monthsToPay);
        require(meed.transferFrom(_msgSender(), _deedOwner, amount), "DeedRenting#DeedRentingPaymentFailed");

        lease.paidMonths += _monthsToPay;
        lease.paidRentsDate = lease.paidRentsDate.add(MONTH_IN_SECONDS.mul(_monthsToPay));
        lease.noticePeriodDate = lease.noticePeriodDate.add(MONTH_IN_SECONDS.mul(_monthsToPay));

        emit RentPaid(_id, lease.deedId, _msgSender(), _deedOwner, _monthsToPay, false);
    }

    /**
     * @dev This method allows to end Lease by Tenant before the End of the Rent Date
     */
    function endLease(uint256 _id)
        public
        onlyDeedTenant(_id)
        isOngoingLease(_id) {

        DeedOffer storage offer = deedOffers[_id];
        DeedLease storage lease = deedLeases[_id];
        if (lease.noticePeriodDate > block.timestamp) {
          lease.leaseEndDate = lease.noticePeriodDate;
        } else {
          lease.leaseEndDate = block.timestamp;
        }

        emit LeaseEnded(_id, lease.deedId, _msgSender(), (offer.months - lease.paidMonths));
    }

    /**
     * @dev This method allows to evict a Tenant who hasn't paid rents at time.
     * Once evicted, the Tenant can still until the end of the Notice Period which
     * was already paid when acquiring offer.
     */
    function evictTenant(uint256 _id)
        public
        onlyDeedOwnerByLeaseId(_id)
        isOngoingLease(_id)
        isRentNotPaid(_id) {

        DeedOffer storage offer = deedOffers[_id];
        DeedLease storage lease = deedLeases[_id];
        if (lease.noticePeriodDate > block.timestamp) {
          lease.leaseEndDate = lease.noticePeriodDate;
        } else {
          lease.leaseEndDate = block.timestamp;
        }

        emit TenantEvicted(_id, lease.deedId, lease.tenant, _msgSender(), (offer.months - lease.paidMonths));
    }

    /**
     * @dev returns true if the address can manage Deed Provisioning
     */
    function isProvisioningManager(
        address _address,
        uint256 _deedId
    )
        public
        view
        override
        returns (bool) {

        for (uint i = 0; i < leases[_deedId].length;i++) {
            uint256 leaseId = leases[_deedId][i];
            DeedLease storage lease = deedLeases[leaseId];
            if (lease.leaseStartDate <= block.timestamp && lease.leaseEndDate > block.timestamp) {
                return lease.tenant == _address;
            }
        }
        return deed.balanceOf(_address, _deedId) > 0;
    }

    function _setTenantProvisioningDelegatee(uint256 _deedId) internal {
        if (tenantProvisioning.getDelegatee(_deedId) != address(this)) {
          require(tenantProvisioning.setDelegatee(address(this), _deedId), "DeedRenting#RentingContractIsntProvisioningManager");
        }
    }

    function _setOffer(DeedOffer memory _offer) internal {
        _offer.creator = _msgSender();
        if (_offer.offerStartDate == 0) {
            _offer.offerStartDate = block.timestamp;
        }
        if (_offer.offerExpirationDays == 0) {
            _offer.offerExpirationDate = 0;
        } else {
            _offer.offerExpirationDate = _offer.offerStartDate.add(DAY_IN_SECONDS.mul(_offer.offerExpirationDays));
        }
        deedOffers[_offer.id] = _offer;
    }

    function _authorizeUpgrade(address newImplementation) internal view virtual override onlyOwner {}

}