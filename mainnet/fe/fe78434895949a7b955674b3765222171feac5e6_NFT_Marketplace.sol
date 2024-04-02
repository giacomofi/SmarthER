/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
// File: contracts/utils/introspection/IERC165.sol



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

// File: contracts/token/ERC1155/IERC1155.sol



pragma solidity ^0.8.0;

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

    /* function ownerOf(uint256 id) external view returns (address); */

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol



pragma solidity ^0.8.0;

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
     /**
      * @dev Returns the token collection name.
      */
     function name() external view returns (string memory);

     /**
      * @dev Returns the token collection symbol.
      */
     function symbol() external view returns (string memory);


    function uri(uint256 id) external view returns (string memory);
}

// File: contracts/utils/Address.sol



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

// File: contracts/utils/Context.sol



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

// File: contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;

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

// File: contracts/token/ERC1155/ERC1155.sol



pragma solidity ^0.8.0;
/* import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; */






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to minter
    mapping(uint256 => address) internal _tokenMinter;

    // Mapping from token ID to creator
    mapping(uint256 => address) internal _tokenCreator;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    /* constructor(string memory uri_) {
        _setURI(uri_);
    } */
    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_,string memory name_, string memory symbol_) {
        _setURI(uri_);
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function minterOf(uint256 id) public view virtual returns (address) {
      address tokenMinter = _tokenMinter[id];
      require(tokenMinter != address(0), "ERC1155: owner query for nonexistent token");

      return tokenMinter;
    }

    /* function ownerOf(uint256 id) public view virtual returns (address) {
      address tokenOwner = _tokenMinter[id];
      require(tokenOwner != address(0), "ERC1155: owner query for nonexistent token");

      return tokenOwner;
    } */

    function creatorOf(uint256 id) public view virtual returns (address) {
      address creator = _tokenCreator[id];
      require(creator != address(0), "ERC1155: creator query for nonexistent token");

      return creator;
    }





    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }


   function setApproval(address account,address operator, bool approved) internal {
       require(account != operator, "ERC1155: setting approval status for self");

       _operatorApprovals[account][operator] = approved;
       emit ApprovalForAll(account, operator, approved);
   }


    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-transferFrom}.
     */
    /* function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
      require(isApprovedForAll(from, _msgSender()),
          "ERC1155: caller is not owner nor approved"
      );
        _transferFrom(from, to, id, amount, data);
    } */

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /* function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    } */

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
        _tokenMinter[id] = account;
        _tokenCreator[id] = account;
    }

    /* function _mint(
      uint256 mint_type,
      address creator,
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();

        if(mint_type==2){
          _beforeTokenTransfer(operator, creator, account, _asSingletonArray(id), _asSingletonArray(amount), data);
          _balances[id][account] += amount;
          emit TransferSingle(operator, creator, account, id, amount);
          _doSafeTransferAcceptanceCheck(operator, creator, account, id, amount, data);
          _tokenMinter[id] = creator;
        }else if(mint_type==1){
          _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);
          _balances[id][account] += amount;
          emit TransferSingle(operator, address(0), account, id, amount);
          _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
          _tokenMinter[id] = creator;
        }else{
          _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

          _balances[id][account] += amount;
          emit TransferSingle(operator, address(0), account, id, amount);

          _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
          _tokenMinter[id] = account;
        }
    } */

    function setCreator(address creator,address account,uint256 id) internal {
        require(account == _tokenMinter[id], "ERC1155: not token owner");
        _tokenCreator[id] = creator;
    }



    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /* function _setApprovalForAll(
       address owner,
       address operator,
       bool approved
   ) internal virtual {
       _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    } */
}

// File: contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/token/ERC20/IERC20.sol



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

// File: contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;


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

// File: contracts/NFT_Marketplace.sol

pragma solidity ^0.8.0;
contract NFT_Marketplace is ERC1155{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

    address ContractOwner;          // 컨트랙트 소유자
    constructor() ERC1155("","BLUEBAY GALLERY","BBG") {
      ContractOwner = msg.sender;
      setting["main"] = adminSetting(0x34E366278EEfe4FEf648AC826528E38717FF900d,0,0x8C661806f716652B637728355cC4e2620D428F99); //플랫폼 지갑 주소, 수수료율,ERC20 주소
    }

   modifier onlyowner {
       require(ContractOwner == msg.sender);
       _;
   }

    struct NFTAsset {
      string metadata;
      address owner;
      uint id;
      uint amount;
      uint price;
      uint flag;
      uint currency; //0-ETH 1-ERC20
    }

    struct adminSetting {
      address platformAddr;
      uint feeRate;
      address tokenAddr;
    }

    mapping (string => adminSetting) setting;

    mapping(address=> mapping(uint => NFTAsset)) public ownedNFT;

    NFTAsset[] public nft_asset;

    function getContractOwner() public view returns (address) {
        return ContractOwner;
    }
    function transferOwnership(address newOwner) public onlyowner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        ContractOwner = newOwner;
    }
    function setChangeFee(uint256 _feeRate) public onlyowner() {
       setting["main"].feeRate = _feeRate;
    }
    function setChangeAddr(address _platformAddr) public onlyowner() {
       setting["main"].platformAddr = _platformAddr;
    }
    function setChangeTokenAddr(address _tokenAddr) public onlyowner() {
       setting["main"].tokenAddr = _tokenAddr;
    }
    function setOwnedNFTFlag(address _owner,uint256 _tokenId,uint256 _flag) public onlyowner(){
      require(_owner == ownedNFT[_owner][_tokenId].owner);
      ownedNFT[_owner][_tokenId].flag = _flag;
    }
    function getFeeRate() public view returns(uint256){
      return (setting["main"].feeRate);
    }
    function getPlatformAddr() public view returns(address){
      return (setting["main"].platformAddr);
    }
    function getTokenAddr() public view returns(address){
      return (setting["main"].tokenAddr);
    }
    function getOwnedNFTPrice(address _owner,uint256 _tokenId) public view returns(uint256){
      require(_owner == ownedNFT[_owner][_tokenId].owner);
      return (ownedNFT[_owner][_tokenId].price);
    }
    function getOwnedNFTCurrency(address _owner,uint256 _tokenId) public view returns(uint256){
      require(_owner == ownedNFT[_owner][_tokenId].owner);
      return (ownedNFT[_owner][_tokenId].currency);
    }
    function getPriceFeeIncluded(address _owner,uint256 _tokenId, uint256 _fee) public view returns(uint256){
      require(_owner == ownedNFT[_owner][_tokenId].owner);
      return (ownedNFT[_owner][_tokenId].price.add(_fee));
    }
    function getOwnedNFTFlag(address _owner,uint256 _tokenId) public view returns(uint256){
      require(_owner == ownedNFT[_owner][_tokenId].owner);
      return (ownedNFT[_owner][_tokenId].flag);
    }
    function getOwnedNFTMetadata(address _owner,uint256 _tokenId) public view returns(string memory){
      require(_owner == nft_asset[_tokenId].owner,"No NFT owner");
      return (nft_asset[_tokenId].metadata);
    }
    //ERC20
    function getERC20Balance() public view returns (uint256){
      uint256 balance = IERC20(getTokenAddr()).balanceOf(msg.sender);
      return balance;
    }
    function getERC20Total() public view returns (uint256){
      uint256 supply = IERC20(getTokenAddr()).totalSupply();
      return supply;
    }
    //ERC20

    //발행
    function mint(string memory _metadata, uint256 _amount, uint256 _price, uint256 _currency) public {//이용자 발행
        require(_currency < 2,"currency::Check");
        uint256 assetId = nft_asset.length; // 유일한 작품 ID
        nft_asset.push(NFTAsset(_metadata,msg.sender,assetId,_amount,_price,0,_currency));
        ownedNFT[msg.sender][assetId]= NFTAsset(_metadata,msg.sender,assetId,_amount,_price,0,_currency);
        _mint(msg.sender, assetId, _amount, ""); //ERC1155 등록
    }
    //이용자 경매 발행 추가 로열티 발행자로 등록

    function mintTrade(string memory _metadata,  uint256 _price, uint256 _currency) public payable {//관리자 발행 경매 구매, 개수 1개로 고정
       require(_currency < 2,"currency::Check");
        if(_currency==0){//ETH 구매
          require(msg.value > 0);
          require(msg.value >= _price);
          uint256 assetId = nft_asset.length; // 유일한 작품 ID
          nft_asset.push(NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency));
          ownedNFT[msg.sender][assetId]= NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency);
          _mint(msg.sender, assetId, 1, ""); //유저 NFT 소유권
          setCreator(getPlatformAddr(),msg.sender,assetId);//로열티 발행자 플랫폼
          if (msg.value > 0) {
            payable(getPlatformAddr()).transfer(msg.value);//판매 비용 전액 플랫폼 지갑으로
          }
        }else if(_currency==1){//ERC20 구매
          require(_price > 0);
          uint256 assetId = nft_asset.length; // 유일한 작품 ID
          nft_asset.push(NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency));
          ownedNFT[msg.sender][assetId]= NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency);
          _mint(msg.sender, assetId, 1, ""); //유저 NFT 소유권
          setCreator(getPlatformAddr(),msg.sender,assetId);//로열티 발행자 플랫폼

          IERC20(getTokenAddr()).transferFrom(msg.sender,getPlatformAddr(), _price); //판매 비용 전액 플랫폼 지갑으로

        }
    }

    function mintAuction(address payable _owner,string memory _metadata, uint256 _fee, uint256 _price, uint256 _currency) public payable {//이용자 발행 경매 구매,개수 1개로 고정
       require(_currency < 2,"currency::Check");
        if(_currency==0){//ETH 구매
          require(msg.value > 0);
          require(msg.value >= _price);
          uint256 assetId = nft_asset.length; // 유일한 작품 ID
          nft_asset.push(NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency));
          ownedNFT[msg.sender][assetId]= NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency);
          _mint(msg.sender, assetId, 1, ""); //유저 NFT 소유권
          setCreator(_owner,msg.sender,assetId);//로열티 발행자 이용자
          if (msg.value > 0) {
            platformFeeBuyer(_fee);//구매 수수료
            platformFeeSeller(_owner,_fee);//판매 수수료
          }
        }else if(_currency==1){//ERC20 구매
          require(_price > 0);
          uint256 assetId = nft_asset.length; // 유일한 작품 ID
          nft_asset.push(NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency));
          ownedNFT[msg.sender][assetId]= NFTAsset(_metadata,msg.sender,assetId,1,_price,1,_currency);
          _mint(msg.sender, assetId, 1, ""); //유저 NFT 소유권
          setCreator(_owner,msg.sender,assetId);//로열티 발행자 이용자

          platformFeeBuyerToken(_fee);//구매 수수료
          platformFeeSellerToken(_owner,_fee,_price);//판매 수수료
        }
    }

    function mintCreator(string memory _metadata, uint256 _amount, uint256 _price, uint256 _currency) public {//관리자 발행 1차 판매
        require(_currency < 2,"currency::Check");
        uint256 assetId = nft_asset.length; // 유일한 작품 ID
        nft_asset.push(NFTAsset(_metadata,msg.sender,assetId,_amount,_price,0,_currency));
        ownedNFT[msg.sender][assetId]= NFTAsset(_metadata,msg.sender,assetId,_amount,_price,0,_currency);
        _mint(msg.sender, assetId, _amount, ""); //유저 NFT 소유권
        setCreator(getPlatformAddr(),msg.sender,assetId); //로열티 발행자 플랫폼
    }
    //발행

    function priceChange(uint256 _tokenId, uint256 _amount, uint256 _price) public {//2차 판매 가격 변경
        require(msg.sender == ownedNFT[msg.sender][_tokenId].owner);
        require(ownedNFT[msg.sender][_tokenId].amount >= _amount);
        require(ownedNFT[msg.sender][_tokenId].flag == 0);

        ownedNFT[msg.sender][_tokenId].price = _price;

    }


    //구매
    function buyNFT(address payable _owner,uint256 _tokenId, uint256 _amount,uint256 _fee, uint256 _price, uint256 _currency) public payable { //NFT 구매
      require(_owner!=msg.sender);
      require(getOwnedNFTFlag(_owner,_tokenId) == 0,"buy::Not for sale");
      require(getOwnedNFTCurrency(_owner,_tokenId) == _currency,"buy::Currency does not match");

      if(_currency==0){//ETH 구매
        require(getPriceFeeIncluded(_owner, _tokenId, _fee).mul(_amount) <= msg.value, "buy::Must purchase the token for the correct price" );

        setApproval(_owner,msg.sender, true);
        platformFeeBuyer(_fee);//구매 수수료
        platformFeeSeller(_owner,_fee);//판매 수수료
        safeTransferFrom(_owner,msg.sender,_tokenId,_amount,"0x0");//소유권 이전

        ownedNFT[msg.sender][_tokenId]= NFTAsset(getOwnedNFTMetadata(minterCheck(_tokenId),_tokenId),msg.sender,_tokenId,_amount,msg.value,1,_currency);


        setApproval(_owner,msg.sender, false);

      }else if(_currency==1){//ERC20 구매
        require(getPriceFeeIncluded(_owner, _tokenId, _fee).mul(_amount) <= _price, "buy::Must purchase the token for the correct price" );

        setApproval(_owner,msg.sender, true);
        platformFeeBuyerToken(_fee);//구매 수수료
        platformFeeSellerToken(_owner,_fee,_price);//판매 수수료
        safeTransferFrom(_owner,msg.sender,_tokenId,_amount,"0x0");//소유권 이전
        ownedNFT[msg.sender][_tokenId]= NFTAsset(getOwnedNFTMetadata(minterCheck(_tokenId),_tokenId),msg.sender,_tokenId,_amount,_price,1,_currency);


        setApproval(_owner,msg.sender, false);
      }
    }
    //구매
    //ETH 결제
    function platformFeeBuyer(uint256 _fee) public payable { //구매자 지급 수수료
      if (msg.value > 0 && getFeeRate()>0) {
        payable(getPlatformAddr()).transfer(_fee); //추가된 구매 수수료만 지급
      }
    }
    function platformFeeSeller(address payable _owner,uint256 _fee) public payable { //판매자 수수료
      if (msg.value > 0 && getFeeRate()>0) {
          uint256 platformFeeSeller =(msg.value.sub(_fee)).mul(getFeeRate()).div(10000);
        payable(getPlatformAddr()).transfer(platformFeeSeller);
        paymentArtwork(_owner,calculateTotalFee(platformFeeSeller,_fee));//판매대금 지급
      }else if(msg.value > 0 && getFeeRate()==0){ //수수료 제로
        paymentArtwork(_owner,0);//판매대금 지급
      }
    }
    function paymentArtwork(address payable _from,uint256 _totalFee) public payable { //판매대금 판매자 지급
      if (msg.value > 0) {
        _from.transfer(msg.value.sub(_totalFee));
      }
    }
    //ETH 결제

    function calculateTotalFee(uint256 _sellerFee,uint256 _buyerFee) public view returns(uint256) {
      return (_sellerFee.add(_buyerFee));
    }

    //ERC20 결제
    function platformFeeBuyerToken(uint256 _fee) public payable { //구매자 지급 수수료
      if (getFeeRate()>0) {
        IERC20(getTokenAddr()).transferFrom(msg.sender,getPlatformAddr(), _fee);
      }
    }
    function platformFeeSellerToken(address payable _owner,uint256 _fee, uint256 _price) public payable { //판매자 수수료
      if (getFeeRate()>0) {
        uint256 platformFeeSeller =(_price.sub(_fee)).mul(getFeeRate()).div(10000);

        IERC20(getTokenAddr()).transferFrom(msg.sender,getPlatformAddr(), platformFeeSeller);
        paymentArtworkToken(_owner,calculateTotalFee(platformFeeSeller,_fee),_price);//판매대금 지급
      }else if(getFeeRate()==0){ //수수료 제로
        paymentArtworkToken(_owner,0,_price);//판매대금 지급
      }
    }
    function paymentArtworkToken(address payable _from,uint256 _totalFee, uint256 _price) public payable { //판매대금 판매자 지급
      if (getFeeRate()>0) {
        IERC20(getTokenAddr()).transferFrom(msg.sender,_from, _price.sub(_totalFee));
      }else if(getFeeRate()==0){ //수수료 제로
        IERC20(getTokenAddr()).transferFrom(msg.sender,_from, _price);
      }
    }
    //ERC20 결제


    function burn(uint256 _tokenId, uint256 _amount) public {
      require(msg.sender == creatorCheck(_tokenId));
      _burn(msg.sender, _tokenId, _amount); //ERC1155 삭제
    }






      //RESELL 2차 구매
      function reSellMint(uint256 _tokenId, uint256 _amount, uint256 _price) public {//client -> listing(2차판매)
          require(msg.sender == ownedNFT[msg.sender][_tokenId].owner);
          require(ownedNFT[msg.sender][_tokenId].amount >= _amount);
          if(getOwnedNFTPrice(msg.sender, _tokenId)>_price){
            ownedNFT[msg.sender][_tokenId].price = _price;
          }
          ownedNFT[msg.sender][_tokenId].flag = 2;
      }

      function reSellPriceChange(uint256 _tokenId, uint256 _amount, uint256 _price) public {//2차 판매 가격 변경
          require(msg.sender == ownedNFT[msg.sender][_tokenId].owner);
          require(ownedNFT[msg.sender][_tokenId].amount >= _amount);
          require(ownedNFT[msg.sender][_tokenId].flag == 2);

          ownedNFT[msg.sender][_tokenId].price = _price;

      }

      function reSellDelist(uint256 _tokenId) public {
          require(msg.sender == ownedNFT[msg.sender][_tokenId].owner);
          require(ownedNFT[msg.sender][_tokenId].flag != 0);
          ownedNFT[msg.sender][_tokenId].flag = 1;
      }

      function reSellBuyNFT(address payable _owner,uint256 _tokenId, uint256 _amount, uint256 _royalRate,uint256 _fee,uint256 _price) public payable { //NFT 재판매 후 구매
        require(_owner!=msg.sender);
        require(msg.sender!=creatorOf(_tokenId),"resell::Cannot buy my NFT");
        require(getOwnedNFTFlag(_owner,_tokenId) == 2,"resell::Not for sale");
        require(_royalRate <= 1000,"resell::Royalty Check"); //최대 10%
        require(ownedNFT[_owner][_tokenId].amount >= _amount ,"resell::Amount Check"); //추가
        require(_amount == 1,"resell::Amount Check"); //추가

        if(getFeeRate()==0){//추가
            require(_fee==0,"resell::Fee Check"); //추가
        }

        if(getOwnedNFTCurrency(_owner,_tokenId)==0){//ETH 구매
          require(getPriceFeeIncluded(_owner, _tokenId, _fee).mul(_amount) <= msg.value, "resell::Must purchase the token for the correct price" );
          setApproval(_owner,msg.sender, true);
          platformFeeBuyer(_fee);//구매 수수료
          uint256 ownerRoyalty = (msg.value.sub(_fee)).mul(_royalRate).div(10000);
          royalties(ownerRoyalty,_tokenId);//발행자 로열티
          uint256 sellerCost = (msg.value - platformFeeReSeller(_fee)- ownerRoyalty);
          reSellpayment(_owner,sellerCost);//판매 대금
          ownedNFT[msg.sender][_tokenId]= NFTAsset(getOwnedNFTMetadata(minterCheck(_tokenId),_tokenId),msg.sender,_tokenId,_amount,msg.value,1,0);
          safeTransferFrom(_owner,msg.sender,_tokenId,_amount,"0x0");
          ownedNFT[_owner][_tokenId].amount = ownedNFT[_owner][_tokenId].amount.sub(_amount);
          setApproval(_owner,msg.sender, false);
        }else if(getOwnedNFTCurrency(_owner,_tokenId)==1){//ERC 구매
          require(getPriceFeeIncluded(_owner, _tokenId, _fee).mul(_amount) <= _price, "resell::Must purchase the token for the correct price" );
          setApproval(_owner,msg.sender, true);
          platformFeeBuyerToken(_fee);//구매 수수료
          uint256 ownerRoyalty = (_price.sub(_fee)).mul(_royalRate).div(10000);
          royaltiesToken(ownerRoyalty,_tokenId);//발행자 로열티
          uint256 sellerCost = (_price - platformFeeReSellerToken(_fee,_price)- ownerRoyalty);
          reSellpaymentToken(_owner,sellerCost);//판매 대금
          ownedNFT[msg.sender][_tokenId]= NFTAsset(getOwnedNFTMetadata(minterCheck(_tokenId),_tokenId),msg.sender,_tokenId,_amount,_price,1,1);
          safeTransferFrom(_owner,msg.sender,_tokenId,_amount,"0x0");
          ownedNFT[_owner][_tokenId].amount = ownedNFT[_owner][_tokenId].amount.sub(_amount);
          setApproval(_owner,msg.sender, false);
        }



      }

      function royaltiesToken(uint256 _royalty,uint256 _tokenId) public payable { //발행자 로열티
        if (_royalty > 0) {
            address creator = creatorOf(_tokenId);
            IERC20(getTokenAddr()).transferFrom(msg.sender,creator, _royalty);
        }
      }
      function platformFeeReSellerToken(uint256 _fee,uint256 _price) public payable returns(uint256) { //판매자 수수료
          if(getFeeRate()>0){
            uint256 platformFeeSeller =(_price.sub(_fee)).mul(getFeeRate()).div(10000);
            IERC20(getTokenAddr()).transferFrom(msg.sender,getPlatformAddr(), platformFeeSeller);
            return(calculateTotalFee(platformFeeSeller,_fee));
          }else if(getFeeRate()==0){
            return(0);
          }
      }
      function reSellpaymentToken(address payable _from,uint256 _cost) public payable { //비용 지불
        if (_cost > 0) {
          IERC20(getTokenAddr()).transferFrom(msg.sender,_from, _cost);
        }
      }

      function royalties(uint256 _royalty,uint256 _tokenId) public payable { //발행자 로열티
        if (_royalty > 0) {
            address creator = creatorOf(_tokenId);
            payable(creator).transfer(_royalty);
        }
      }
      function platformFeeReSeller(uint256 _fee) public payable returns(uint256) { //판매자 수수료
        if (msg.value > 0) {
          uint256 platformFeeSeller =(msg.value.sub(_fee)).mul(getFeeRate()).div(10000);
          payable(getPlatformAddr()).transfer(platformFeeSeller);
          return(calculateTotalFee(platformFeeSeller,_fee));
        }
      }
      function reSellpayment(address payable _from,uint256 _cost) public payable { //비용 지불
        if (_cost > 0) {
          _from.transfer(_cost);
        }
      }
      //RESELL 2차 구매



      function minterCheck(uint256 _tokenId) public view returns (address){ //minter 확인
        return minterOf(_tokenId);
      }
      function creatorCheck(uint256 _tokenId) public view returns (address){ //creator 확인 로열티 받을 사람
          return creatorOf(_tokenId);
      }


}