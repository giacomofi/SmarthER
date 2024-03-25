// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Implementation of the basic standard multi-token.
 * see https://eips.ethereum.org/EIPS/eip-1155
 * based on https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155
 */
contract ERC1155 is ERC165, IERC1155, ReentrancyGuard {
    using Address for address;

    /// cannot use the zero address
    error InvalidAddress();

    /// owner `owner` does not have sufficient amount of token `id`; requested `requested`, but has only `owned` is owned
    error InsufficientTokens(uint id, address owner, uint owned, uint requested);

    /// sender `operator` is not owner nor approved to transfer
    error UnauthorizedTransfer(address operator);

    /// receiver `receiver` has rejected token(s) transfer`
    error ERC1155ReceiverRejectedTokens(address receiver);

    mapping(uint => mapping(address => uint)) internal balances; // tokenId => account => balance
    mapping(address => mapping(address => bool)) internal operatorApprovals; // account => operator => approval

    modifier valid(address account) { if (account == address(0)) revert InvalidAddress(); _; }

    modifier canTransfer(address from) { if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert UnauthorizedTransfer(msg.sender); _; }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address account, uint id) public view virtual override valid(account) returns (uint) {
        return balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint[] memory ids) external view virtual override returns (uint[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint[] memory batchBalances = new uint[](accounts.length);
        for (uint i = 0; i < accounts.length; ++i) batchBalances[i] = balanceOf(accounts[i], ids[i]);
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev Approve `operator` to operate on all of `owner` tokens
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return operatorApprovals[account][operator];
    }

    /**
     * @dev transfer `amount` tokens of token type `id` from `from` to `to`.
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}
     *   and return the acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) external virtual override nonReentrant canTransfer(from) valid(to) {
        _safeTransferFrom(from, to, id, amount, data);
        emit TransferSingle(msg.sender, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function _safeTransferFrom(address from, address to, uint id, uint amount, bytes memory) internal virtual {
        uint balance = balances[id][from];
        if (balance < amount) revert InsufficientTokens(id, from, balance, amount);
        balances[id][from] = balance - amount;
        balances[id][to] += amount;
    }

    function safeBatchTransferFrom(address from, address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external virtual override nonReentrant canTransfer(from) valid(to) {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint i = 0; i < ids.length; ++i) _safeTransferFrom(from, to, ids[i], amounts[i], data);
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) revert ERC1155ReceiverRejectedTokens(to);
            } catch Error(string memory reason) {
                revert(reason);
            } // otherwise do nothing
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) revert ERC1155ReceiverRejectedTokens(to);
            } catch Error(string memory reason) {
                revert(reason);
            } // otherwise do nothing
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../ERC1155.sol";
import "../../../utils/structs/Bits.sol";


/**
 * @dev an ERC1155 that has a fixed supply for all its tokens.
 * it is created with an implicit finite set of 256 tokens, as the token id range is [1-256].
 * minting happens implicitly when only a portion of fixed supply is transferred.
 */
contract ERC1155PreMintedCollection is ERC1155, IERC1155MetadataURI {
    using Address for address payable;
    using Address for address;
    using Bits for Bits.Bitmap;

    address public creator;
    string public name;
    string public symbol;
    string public baseURI; // used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    uint public howManyTokens;
    uint public supplyPerToken;
    Bits.Bitmap private notOwnedByCreator; // in the beginning, creator owns it all (using reverse logic: 0 indicates ownership)

    constructor(
        string memory _name,
        string memory _symbol,
        uint _howManyTokens,
        uint _supplyPerToken,
        string memory _baseURI
    ) {
        creator = tx.origin;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        supplyPerToken = _supplyPerToken;
        howManyTokens = _howManyTokens;
    }

    function isOwnedByCreator(uint id) public view returns (bool) { return !notOwnedByCreator.get(id); }

    /// @dev for tracing
    function creatorOwnershipBitMap() external view returns (uint[] memory) {
        return notOwnedByCreator.toArray(howManyTokens);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function exists(uint id) public view virtual returns (bool) { return 0 <= id && id < howManyTokens; }

    function totalSupply(uint id) public view virtual returns (uint) { return exists(id) ? supplyPerToken : 0; }

    /**
     * This implementation relies on the token type ID substitution mechanism.
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the actual token type ID.
     */
    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "IERC1155MetadataURI: uri query for nonexistent token");
        return string(abi.encodePacked(baseURI, "/", uint2str(tokenId), ".json"));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function balanceOf(address account, uint id) public view override(IERC1155, ERC1155) virtual returns (uint) {
        uint balance = super.balanceOf(account, id);
        return balance > 0 ?
            balance :
            account == creator && isOwnedByCreator(id) ?
                supplyPerToken :
                0;
    }

    function _safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) internal virtual override {
        if (from == creator && isOwnedByCreator(id)) {
            notOwnedByCreator.set(id);
            balances[id][creator] += supplyPerToken;
        }
        super._safeTransferFrom(from, to, id, amount, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981.sol";

/// @dev a contract adding ERC2981 support to ERC721 and ERC1155
contract ERC2981 is ERC165, IERC2981 {

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    RoyaltyInfo public royalties;

    constructor(address recipient, uint24 basispoints) {
        setRoyalties(recipient, basispoints);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint24 basispoints) internal {
        require(basispoints <= 10000, "ERC2981: royalty basispoints too high");
        royalties.recipient = recipient;
        royalties.amount = basispoints;
    }

    function royaltyInfo(uint, uint salePrice) external view override returns (address receiver, uint royaltyAmount) {
        receiver = royalties.recipient;
        royaltyAmount = (salePrice * royalties.amount) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint,uint)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param id - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by id
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint id, uint salePrice) external view returns (address receiver, uint royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../utils/HasAuthorization.sol";
import "./ERC1155/extensions/ERC1155PreMintedCollection.sol";
import "./ERC2981/ERC2981.sol";


contract TradableCollection is ERC1155PreMintedCollection, ERC2981, HasAuthorization {

    event BaseUriUpdate(string uri);
    event RoyaltyInfoUpdate(address recipient, uint24 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint howManyTokens,
        uint supplyPerToken,
        string memory baseURI,
        address royaltiesRecipient,
        uint24 royaltiesBasispoints
    )
        ERC1155PreMintedCollection(name, symbol, howManyTokens, supplyPerToken, baseURI)
        ERC2981(royaltiesRecipient, royaltiesBasispoints) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PreMintedCollection, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferRoyaltiesRecipient(address recipient) only(royalties.recipient) external {
        setRoyalties(recipient, royalties.amount);
        emit RoyaltyInfoUpdate(recipient, royalties.amount);
    }

    function reduceRoyalties(uint24 basispoints) only(royalties.recipient) external {
        require(basispoints < royalties.amount, "ERC2981: reduced royalty basispoints must be smaller");
        setRoyalties(royalties.recipient, basispoints);
        emit RoyaltyInfoUpdate(royalties.recipient, basispoints);
    }

    function updateBaseURI(string memory _baseURI) only(royalties.recipient) external {
        baseURI = _baseURI;
        emit BaseUriUpdate(_baseURI);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


abstract contract HasAuthorization {

    /// sender is not authorized for this action
    error Unauthorized();

    modifier only(address authorized) { if (msg.sender != authorized) revert Unauthorized(); _; }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


/**
 * @dev Library for managing uint to bool mapping in a compact and efficient way, providing the keys are sequential.
 * based on https://docs.openzeppelin.com/contracts/4.x/api/utils#BitMaps
 */
library Bits {

    struct Bitmap {
        mapping(uint => uint) data;
    }

    uint constant internal ONES = ~uint(0);

    function get(Bitmap storage self, uint index) internal view returns (bool) {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        return self.data[bucket] & mask != 0;
    }

    function set(Bitmap storage self, uint index) internal {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        self.data[bucket] |= mask;
    }

    function setAll(Bitmap storage self, uint size) internal {
        uint fullBuckets = size >> 8;
        if (fullBuckets > 0) for (uint i = 0; i < fullBuckets; i++) self.data[i] = ONES;
        uint remaining = size & 0xff;
        if(remaining == 0 ) return ;
        self.data[fullBuckets] = ONES >> (256 - remaining);
    }

    function unset(Bitmap storage self, uint index) internal {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        self.data[bucket] &= ~mask;
    }

    function toggle(Bitmap storage self, uint index) internal {
        setTo(self, index, !get(self, index));
    }

    function setTo(Bitmap storage self, uint index, bool value) private {
        value ? set(self, index) : unset(self, index);
    }

    /// @dev for tracing
    function toArray(Bitmap storage self, uint size) internal view returns (uint[] memory result) {
        result = new uint[]((size >> 8) + ((size & 0xff) > 0 ? 1 : 0));
        for (uint i = 0; i < result.length; i++) result[i] = self.data[i];
    }
}