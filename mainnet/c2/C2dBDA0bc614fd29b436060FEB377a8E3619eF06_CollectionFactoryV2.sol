// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/**
 * @title Affiliate Registry Interface
 * @dev   Interface with necessary functionalities of Affiliate Registry.
 * @author Chain Labs Team
 */
interface IAffiliateRegistry {
    function setAffiliateShares(uint256 _affiliateShares, bytes32 _projectId)
        external;

    function registerProject(string memory projectName, uint256 affiliateShares)
        external
        returns (bytes32 projectId);

    function getProjectId(string memory _projectName, address _projectOwner)
        external
        view
        returns (bytes32 projectId);

    function getAffiliateShareValue(
        bytes memory signature,
        address affiliate,
        bytes32 projectId,
        uint256 value
    ) external view returns (bool _isAffiliate, uint256 _shareValue);
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "../interface/ICollection.sol";

/// @title CollectionFactoryV2
/// @author Chain Labs
/// @notice a single factory to create multiple and various clones of collection.
/// @dev new collection type can be added and deployed
contract CollectionFactoryV2 is Pausable, Ownable, ERC2771Recipient {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice version of Collection Factory
    /// @dev version of collection factory
    /// @return VERSION version of collection factory
    string public constant VERSION = "0.2.0";

    /// @notice address of Simplr Afffiliate Registry
    /// @dev address of simplr affiliate registry
    /// @return affiliateRegistry address of simple affiliate registry
    address public affiliateRegistry;

    /// @notice address of Simplr Early Access Token
    /// @dev only ERC721 contract address
    /// @return seat address of SEAT (Simplr Early Access Token)
    address public seat;

    /// @notice simplr fee receiver gnosis safe
    /// @dev all the fees is transfered to Simplr's Fee Receiver Gnosis Safe
    /// @return simplr Simplr Fee receiver gnosis safe
    address public simplr;

    /// @notice fixed share of simplr for each collection sale
    /// @dev in the beginning it is set to 0%, then gradually it will increase to 1% max
    /// @return simplrShares shares of simplr
    uint256 public simplrShares;

    /// @notice upfront fee to start a new collection
    /// @dev upfront fee to start a new collection
    /// @return upfrontFee upfront fee to start a new collection
    uint256 public upfrontFee;

    /// @notice total amount of upfront fee withdrawn from Factory
    /// @dev used to calculate total fee collected
    /// @return totalWithdrawn total amount of upfront fee withdrawn from Factory
    uint256 public totalWithdrawn;

    /// @notice ID of Simplr Collection in affiliate registry
    /// @dev ID that is used to identify Simplr Collection by affiliate registry
    /// @return affiliateProjectId ID of Simplr Collection in affiliate registry
    bytes32 public affiliateProjectId;

    /// @notice list of various collection types
    /// @dev mapping of collection id with master copy of collection
    /// @return mastercopies master copy address of a collection type
    mapping(uint256 => address) public mastercopies;

    /// @notice logs whenever new collection is created
    /// @dev emitted when new collection is created
    /// @param collection address of new collection
    /// @param admin admin address of new collection
    /// @param collectionType type of collection deployed
    event CollectionCreated(
        address indexed collection,
        address indexed admin,
        uint256 indexed collectionType
    );

    /// @notice logs when new collection type is added
    /// @dev emitted when new collection type is added
    /// @param collectionType ID of collection type
    /// @param mastercopy address of collection type master copy
    /// @param data collection type specific data eg. name of collection type
    event NewCollectionTypeAdded(
        uint256 indexed collectionType,
        address mastercopy,
        bytes data
    );

    //------------------------------------------------------//
    //
    //  Constructor
    //
    //------------------------------------------------------//

    /// @notice constructor
    /// @param _masterCopy address of implementation contract
    /// @param _data collection type specific data
    /// @param _simplr address of simplr beneficiary
    /// @param _trustedForwarder address of trusted forwarder
    /// @param _newRegistry address of affiliate registry
    /// @param _newProjectId ID of Simplr Collection in Affiliate Registry
    /// @param _simplrShares shares of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    /// @param _upfrontFee upfront fee to start a new collection
    constructor(
        address _masterCopy,
        bytes memory _data,
        address _simplr,
        address _trustedForwarder,
        address _newRegistry,
        bytes32 _newProjectId,
        uint256 _simplrShares,
        uint256 _upfrontFee
    ) {
        require(_masterCopy != address(0), "CFv2:001");
        require(_simplr != address(0), "CFv2:002");
        simplr = _simplr;
        simplrShares = _simplrShares;
        upfrontFee = _upfrontFee;
        affiliateRegistry = _newRegistry;
        affiliateProjectId = _newProjectId;
        _setTrustedForwarder(_trustedForwarder);
        _addNewCollectionType(_masterCopy, 1, _data);
    }

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set simplr fee receiver address
    /// @dev set Simplr Fee Receiver Gnosis Safe
    /// @param _simplr address of Simplr Fee receiver
    function setSimplr(address _simplr) external onlyOwner {
        require(_simplr != address(0) && simplr != _simplr, "CFv2:003");
        simplr = _simplr;
    }

    /// @notice set Simplr Early Access Token address
    /// @dev it can only be ERC721 type contract
    /// @param _newSeat adddress of SEAT (Simplr Early Access Token)
    function setSeat(address _newSeat) external onlyOwner {
        require(
            _newSeat != address(0) &&
                IERC165(_newSeat).supportsInterface(type(IERC721).interfaceId),
            "CFv2:010"
        );
        seat = _newSeat;
    }

    /// @notice set Simplr Shares
    /// @dev update simplr shares
    /// @param _simplrShares new shares of simplr
    function setSimplrShares(uint256 _simplrShares) external onlyOwner {
        simplrShares = _simplrShares;
    }

    /// @notice sets new upfront fee
    /// @dev sets new upfront fee
    /// @param _upfrontFee  new upfront fee
    function setUpfrontFee(uint256 _upfrontFee) external onlyOwner {
        upfrontFee = _upfrontFee;
    }

    /// @notice set Simplr Affiliate Registry address
    /// @dev set new Simplr Affiliate registry address
    /// @param _newRegistry address of new simplr affiliate registry address
    function setAffiliateRegistry(address _newRegistry) external onlyOwner {
        affiliateRegistry = _newRegistry;
    }

    /// @notice set project ID of Simplr Collection
    /// @dev Identifier of Simplr Collection in Affiliate Registry
    /// @param _newProjectId new project ID
    function setAffiliateProjectId(bytes32 _newProjectId) external onlyOwner {
        affiliateProjectId = _newProjectId;
    }

    /// @notice set new master copy for a collection type
    /// @dev set new master copy for a collection type
    /// @param _newMastercopy new master copy address
    /// @param _type collection type ID
    function setMastercopy(address _newMastercopy, uint256 _type)
        external
        onlyOwner
    {
        require(
            _newMastercopy != address(0) &&
                _newMastercopy != mastercopies[_type],
            "CFv2:004"
        );
        require(mastercopies[_type] != address(0), "CFv2:005");
        mastercopies[_type] = _newMastercopy;
    }

    /// @notice withdraw collected upfront fees
    /// @dev withdraw specific amount
    /// @param _value amount to withdraw
    function withdraw(uint256 _value) external onlyOwner {
        require(_value <= address(this).balance, "CFv2:008");
        totalWithdrawn += _value;
        Address.sendValue(payable(simplr), _value);
    }

    /// @notice pause creation of collection
    /// @dev pauses all the public methods, using OpenZeppelin's Pausable.sol
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice unpause creation of collection
    /// @dev unpauses all the public methods, using OpenZeppelin's Pausable.sol
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice add new collection type
    /// @dev only owner can add new collection type
    /// @param _mastercopy address of collection mastercopy
    /// @param _type type of collection
    /// @param _data bytes string to store  arbitrary data about the collection in emitted events eg. explaination about the  type
    function addNewCollectionType(
        address _mastercopy,
        uint256 _type,
        bytes memory _data
    ) external onlyOwner {
        _addNewCollectionType(_mastercopy, _type, _data);
    }

    /// @notice Set trusted forwarder for Collection Factory V2
    /// @dev trsuted forwarder is used to make the creartion of collection gasless
    /// @param _trustedForwarder address of trusted forwarder
    function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @notice create new collection
    /// @dev deploys new collection using cloning
    /// @param _type type of collection to be deployed
    /// @param _baseCollection struct with params to setup base collection
    /// @param _presaleable  struct with params to setup presaleable
    /// @param _paymentSplitter struct with params to setup payment splitting
    /// @param _projectURIProvenance  struct with params to setup reveal details
    /// @param _metadata ipfs hash or CID for the metadata of collection
    /// @param _isAffiliable to activate affiliate module
    function createCollection(
        uint256 _type,
        ICollection.BaseCollectionStruct memory _baseCollection,
        ICollection.PresaleableStruct memory _presaleable,
        ICollection.PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        ICollection.RoyaltyInfo memory _royalties,
        uint256 _reserveTokens,
        string memory _metadata,
        bool _isAffiliable
    ) external payable whenNotPaused {
        require(mastercopies[_type] != address(0), "CFv2:005");
        if (seat != address(0) && IERC721(seat).balanceOf(_msgSender()) > 0) {
            _paymentSplitter.simplrShares = 1;
        } else {
            require(msg.value == upfrontFee, "CFv2:006");
            _paymentSplitter.simplrShares = simplrShares;
        }
        _paymentSplitter.simplr = simplr;
        address collection = Clones.clone(mastercopies[_type]);
        ICollection(collection).setMetadata(_metadata);
        if (
            _isAffiliable &&
            affiliateRegistry != address(0) &&
            affiliateProjectId != bytes32(0)
        ) {
            ICollection(collection).setupWithAffiliate(
                _baseCollection,
                _presaleable,
                _paymentSplitter,
                _projectURIProvenance,
                _royalties,
                _reserveTokens,
                IAffiliateRegistry(affiliateRegistry),
                affiliateProjectId
            );
        } else {
            ICollection(collection).setup(
                _baseCollection,
                _presaleable,
                _paymentSplitter,
                _projectURIProvenance,
                _royalties,
                _reserveTokens
            );
        }
        emit CollectionCreated(collection, _baseCollection.admin, _type);
    }

    //------------------------------------------------------//
    //
    //  Internal function
    //
    //------------------------------------------------------//

    /// @notice internal method to add new collection types
    /// @dev used to add new collection type by constrcutor too
    /// @param _mastercopy address of collection mastercopy
    /// @param _type type of collection
    /// @param _data bytes string to store  arbitrary data about the collection in emitted events eg. explaination about the  type
    function _addNewCollectionType(
        address _mastercopy,
        uint256 _type,
        bytes memory _data
    ) private {
        require(mastercopies[_type] == address(0), "CFv2:009");
        require(_mastercopy != address(0), "CFv2:001");
        mastercopies[_type] = _mastercopy;
        emit NewCollectionTypeAdded(_type, _mastercopy, _data);
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./ICollectionStruct.sol";
import "../../affiliate/IAffiliateRegistry.sol";

/// @title Collection Interface
/// @author Chain Labs
/// @notice interface to with setup functionality of collection.
interface ICollection is ICollectionStruct {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    /// @notice setup collection with affiliate module
    /// @dev setup all the modules and base collection including affiliate module
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    /// @param _registry address of Simplr Affiliate registry
    /// @param _projectId project ID of Simplr Collection
    function setupWithAffiliate(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens,
        IAffiliateRegistry _registry,
        bytes32 _projectId
    ) external;

    /// @notice setup collection
    /// @dev setup all the modules and base collection
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens
    ) external;

    /// @notice updates the collection details (not collection assets)
    /// @dev updates the IPFS CID that points to new collection details
    /// @param _metadata new IPFS CID with updated collection details
    function setMetadata(string memory _metadata) external;
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/**
 * @title Collection Struct Interface
 * @dev   interface to for all the struct required for setup parameters.
 * @author Chain Labs Team
 */
/// @title Collection Struct Interface
/// @author Chain Labs
/// @notice interface for all the struct required for setup parameters.
interface ICollectionStruct {
    struct BaseCollectionStruct {
        string name;
        string symbol;
        address admin;
        uint256 maximumTokens;
        uint16 maxPurchase;
        uint16 maxHolding;
        uint256 price;
        uint256 publicSaleStartTime;
        string projectURI;
    }

    struct Whitelist {
        bytes32 root;
        string cid;
    }

    struct PresaleableStruct {
        uint256 presaleReservedTokens;
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleMaxHolding;
        Whitelist presaleWhitelist;
    }

    struct PaymentSplitterStruct {
        address simplr;
        uint256 simplrShares;
        address[] payees;
        uint256[] shares;
    }
}