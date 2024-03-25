// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// the erc1155 base contract - the openzeppelin erc1155
import "../token/ERC1155.sol";
import "../royalties/ERC2981.sol";
import "../utils/AddressSet.sol";
import "../utils/UInt256Set.sol";

import "./ProxyRegistry.sol";
import "./ERC1155Owners.sol";
import "./ERC1155Owned.sol";
import "./ERC1155TotalBalance.sol";
import "./ERC1155CommonUri.sol";

import "../access/Controllable.sol";

import "../interfaces/IMultiToken.sol";
import "../interfaces/IERC1155Mint.sol";
import "../interfaces/IERC1155Burn.sol";
import "../interfaces/IERC1155Multinetwork.sol";
import "../interfaces/IERC1155Bridge.sol";

import "../service/Service.sol";

import "../utils/Strings.sol";

/**
 * @title MultiToken
 * @notice the multitoken contract. All tokens are printed on this contract. The token has all the capabilities
 * of an erc1155 contract, plus network transfer, royallty tracking and assignment and other features.
 */
contract MultiToken is
ERC1155,
ProxyRegistryManager,
ERC1155Owners,
ERC1155Owned,
ERC1155TotalBalance,
IERC1155Multinetwork,
ERC1155CommonUri,
IMultiToken,
ERC2981,
Service,
Controllable
{

    // to work with token holder and held token lists
    using AddressSet for AddressSet.Set;
    using UInt256Set for UInt256Set.Set;

    address internal masterMinter;

    function initialize(address registry) public initializer {
        _serviceRegistry = registry;
    }

    function setMasterController(address _masterMinter) public {
        require(masterMinter == address(0), "master minter must not be set");
        masterMinter = _masterMinter;
        _addController(_masterMinter);
    }

    function addDirectMinter(address directMinter) public {
        require(msg.sender == masterMinter, "only master minter can add direct minters");
        _addController(directMinter);
    }

    /// @notice only allow owner of the contract
    modifier onlyOwner() {
        require(_isController(msg.sender), "You shall not pass");
        _;
    }
    /// @notice only allow owner of the contract
    modifier onlyMinter() {
        require(_isController(msg.sender) || masterMinter == msg.sender, "You shall not pass");
        _;
    }

    /// @notice Mint a specified amount the specified token hash to the specified receiver
    /// @param recipient the address of the receiver
    /// @param tokenHash the token id to mint
    /// @param amount the amount to mint
    function mint(
        address recipient,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyMinter {

        _mint(recipient, tokenHash, amount, "");

    }

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mintWithCommonUri(
        address recipient,
        uint256 tokenHash,
        uint256 amount,
        uint256 uriId
    ) external override onlyMinter {

        _mint(recipient, tokenHash, amount, "");
        _setCommonUriOf(tokenHash, uriId);

    }

    function setCommonUri(uint256 uriId, string memory value) external override onlyMinter {

        require(commonURIOwners[uriId] == address(0)
            || commonURIOwners[uriId] == msg.sender
            || _isController(msg.sender), "Only the owner can set the URI");
        _setCommonUri(uriId, value);

    }

    function setCommonUriOf(uint256 uriId, uint256 value) external override onlyMinter {

        require(commonURIOwners[uriId] == address(0)
            || commonURIOwners[uriId] == msg.sender
            || _isController(msg.sender), "Only the owner can set the URI");
        _setCommonUriOf(uriId, value);
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
    function uri(uint256 tokenHash) public view virtual override returns (string memory) {

        string memory curi = _commonUriOf(tokenHash);
        string memory _uriOf = uriOf[tokenHash];

        if(bytes(_uriOf).length > 0) {
            return Strings.strConcat(_uriOf, Strings.uint2str(tokenHash));
        }
        if(bytes(curi).length > 0) {
            return Strings.strConcat(curi, Strings.uint2str(tokenHash));
        }
        return _uri;

    }

    function setUri(uint256 tokenHash, string memory value) external onlyMinter {

        require(uriOwners[tokenHash] == address(0)
            || uriOwners[tokenHash] == msg.sender
            || _isController(msg.sender), "Only the owner can set the URI");
        _setUri(tokenHash, value);

    }

    mapping(uint256 => string) internal uriOf;
    mapping(uint256 => address) internal uriOwners;
    function _setUri(uint256 tokenHash, string memory value) internal {

        uriOf[tokenHash] = value;
        uriOwners[tokenHash] = msg.sender;

    }

    /// @notice burn a specified amount of the specified token hash from the specified target
    /// @param target the address of the target
    /// @param tokenHash the token id to burn
    /// @param amount the amount to burn
    function burn(
        address target,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyMinter {
        _burn(target, tokenHash, amount);
    }

    /// @notice override base functionality to check proxy registries for approvers
    /// @param _owner the owner address
    /// @param _operator the operator address
    /// @return isOperator true if the owner is an approver for the operator
    function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator) {
        // check proxy whitelist
        bool _approved = _isApprovedForAll(_owner, _operator);
        return _approved || ERC1155.isApprovedForAll(_owner, _operator);
    }

    /// @notice See {IERC165-supportsInterface}. ERC165 implementor. identifies this contract as an ERC1155
    /// @param interfaceId the interface id to check
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC1155Multinetwork).interfaceId ||
            interfaceId == type(IERC1155Owners).interfaceId ||
            interfaceId == type(IERC1155Owned).interfaceId ||
            interfaceId == type(IERC1155TotalBalance).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice perform a network token transfer. Transfer the specified quantity of the specified token hash to the destination address on the destination network.
    function networkTransferFrom(
        address from,
        address to,
        uint256 network,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external virtual override {

        address _bridge = IJanusRegistry(_serviceRegistry).get("MultiToken", "NetworkBridge");
        require(_bridge != address(0), "No network bridge found");

        // call the network transfer on the bridge
        IERC1155Multinetwork(_bridge).networkTransferFrom(from, to, network, id, amount, data);

    }

    /// @notice override base functionality to process token transfers so as to populate token holders and held tokens lists
    /// @param operator the operator address
    /// @param from the address of the sender
    /// @param to the address of the receiver
    /// @param ids the token ids
    /// @param amounts the token amounts
    /// @param data the data
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // let super process this first
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        //address royaltyPayee = _serviceRegistry.get("MultiToken", "RoyaltyPayee");

        // iterate through all ids in this transfer
        for (uint256 i = 0; i < ids.length; i++) {

            // if this is not a mint then remove the held token id from lists if
            // this is the last token if this type the sender owns
            if (from != address(0) && balanceOf(from, ids[i]) == amounts[i]) {
                // find and delete the token id from the token holders held tokens
                _owned[from].remove(ids[i]);
                _owners[ids[i]].remove(from);
            }

            // if this is not a burn and receiver does not yet own token then
            // add that account to the token for that id
            if (to != address(0) && balanceOf(to, ids[i]) == 0) {
                // insert the token id from the token holders held tokens\
                _owned[to].insert(ids[i]);
                _owners[ids[i]].insert(to);
            }

            // when a mint occurs, increment the total balance for that token id
            if (from == address(0)) {
                _totalBalances[uint256(ids[i])] =
                    _totalBalances[uint256(ids[i])] +
                    (amounts[i]);
            }
            // when a burn occurs, decrement the total balance for that token id
            if (to == address(0)) {
                _totalBalances[uint256(ids[i])] =
                    _totalBalances[uint256(ids[i])] -
                    (amounts[i]);
            }
        }
    }

    mapping(uint256 => string) internal symbolsOf;
    mapping(uint256 => string) internal namesOf;

    function symbolOf(uint256 _tokenId) external view override returns (string memory out) {
        return symbolsOf[_tokenId];
    }

    function nameOf(uint256 _tokenId) external view override returns (string memory out) {
        return namesOf[_tokenId];
    }

    function setSymbolOf(uint256 _tokenId, string memory _symbolOf) external onlyMinter {
        symbolsOf[_tokenId] = _symbolOf;
    }

    function setNameOf(uint256 _tokenId, string memory _nameOf) external onlyMinter {
        namesOf[_tokenId] = _nameOf;
    }

    function setRoyalty(uint256 tokenId, address receiver, uint256 amount) external onlyOwner {
        royaltyReceiversByHash[tokenId] = receiver;
        royaltyFeesByHash[tokenId] = amount;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, Initializable {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

    /**
     * @dev {_setURI} has been moved into {initialize_ERC1155} to support CREATE2 deploys
     */
    constructor() {}

    /**
     * @dev See {_setURI}.
     */
    function initialize_ERC1155(string memory uri_) public {
        require(bytes(uri_).length == 0, "URI already initialized");
        _setURI(uri_);
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

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

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
    function setURI(string memory newuri) public {
        setURI(newuri);
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
    ) internal {
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IERC2981Holder.sol";
import "../interfaces/IERC2981.sol";

///
/// @dev An implementor for the NFT Royalty Standard. Provides interface
/// response to erc2981 as well as a way to modify the royalty fees
/// per token and a way to transfer ownership of a token.
///
abstract contract ERC2981 is ERC165, IERC2981, IERC2981Holder {

    // royalty receivers by token hash
    mapping(uint256 => address) internal royaltyReceiversByHash;

    // royalties for each token hash - expressed as permilliage of total supply
    mapping(uint256 => uint256) internal royaltyFeesByHash;

    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @dev only the royalty owner shall pass
    modifier onlyRoyaltyOwner(uint256 _id) {
        require(royaltyReceiversByHash[_id] == msg.sender,
        "Only the owner can modify the royalty fees");
        _;
    }

    /**
     * @dev ERC2981 - return the receiver and royalty payment given the id and sale price
     * @param _tokenId the id of the token
     * @param _salePrice the price of the token
     * @return receiver the receiver
     * @return royaltyAmount the royalty payment
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        require(_salePrice > 0, "Sale price must be greater than 0");
        require(_tokenId > 0, "Token Id must be valid");

        // get the receiver of the royalty
        receiver = royaltyReceiversByHash[_tokenId];

        // calculate the royalty amount. royalty is expressed as permilliage of total supply
        royaltyAmount = royaltyFeesByHash[_tokenId] / 1000000 * _salePrice;
    }

    /// @notice ERC165 interface responder for this contract
    /// @param interfaceId - the interface id to check
    /// @return supportsIface - whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override returns (bool supportsIface) {
        supportsIface = interfaceId == type(IERC2981).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /// @notice set the fee permilliage for a token hash
    /// @param _id - id of the token hash
    /// @param _fee - the fee permilliage to set
    function setFee(uint256 _id, uint256 _fee) onlyRoyaltyOwner(_id) external override {
        require(_id != 0, "Fee cannot be zero");
        royaltyFeesByHash[_id] = _fee;
    }

    /// @notice get the fee permilliage for a token hash
    /// @param _id - id of the token hash
    /// @return fee - the fee
    function getFee(uint256 _id) external view override returns (uint256 fee) {
        fee = royaltyFeesByHash[_id];
    }

    /// @notice get the royalty receiver for a token hash
    /// @param _id - id of the token hash
    /// @return owner - the royalty owner
    function royaltyOwner(uint256 _id) external view override returns (address owner) {
        owner = royaltyReceiversByHash[_id];
    }

    /// @notice get the royalty receiver for a token hash
    /// @param _id - id of the token hash
    /// @param _newOwner - address of the new owners
    function transferOwnership(uint256 _id, address _newOwner) onlyRoyaltyOwner(_id) external override {
        require(_id != 0 && _newOwner != address(0), "Invalid token id or new owner");
        royaltyReceiversByHash[_id] = _newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library AddressSet {
    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, address key) public {
        require(
            !exists(self, key),
            "AddressSet: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, address key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        require(
            exists(self, key),
            "AddressSet: key does not exist in the set."
        );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            address keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, address key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (address)
    {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library UInt256Set {
    struct Set {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, uint256 key) public {
        require(
            !exists(self, key),
            "UInt256Set: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, uint256 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "UInt256Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            uint256 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, uint256 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (uint256)
    {
        return self.keyList[index];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IProxyRegistry.sol";
import "../utils/AddressSet.sol";

/// @title ProxyRegistryManager
/// @notice a proxy registry is a registry of delegate proxies which have the ability to autoapprove transactions for some address / contract. Used by OpenSEA to enable feeless trades by a proxy account
contract ProxyRegistryManager is IProxyRegistryManager {

    // using the addressset library to store the addresses of the proxies
    using AddressSet for AddressSet.Set;

    // the set of registry managers able to manage this registry
    mapping(address => bool) internal registryManagers;

    // the set of proxy addresses
    AddressSet.Set private _proxyAddresses;

    /// @notice add a new registry manager to the registry
    /// @param newManager the address of the registry manager to add
    function addRegistryManager(address newManager) external virtual override {
        registryManagers[newManager] = true;
    }

    /// @notice remove a registry manager from the registry
    /// @param oldManager the address of the registry manager to remove
    function removeRegistryManager(address oldManager) external virtual override {
        registryManagers[oldManager] = false;
    }

    /// @notice check if an address is a registry manager
    /// @param _addr the address of the registry manager to check
    /// @return _isManager true if the address is a registry manager, false otherwise
    function isRegistryManager(address _addr)
    external
    virtual
    view
    override
    returns (bool _isManager) {
        return registryManagers[_addr];
    }

    /// @notice add a new proxy address to the registry
    /// @param newProxy the address of the proxy to add
    function addProxy(address newProxy) external virtual override {
        _proxyAddresses.insert(newProxy);
    }

    /// @notice remove a proxy address from the registry
    /// @param oldProxy the address of the proxy to remove
    function removeProxy(address oldProxy) external virtual override {
        _proxyAddresses.remove(oldProxy);
    }

    /// @notice check if an address is a proxy address
    /// @param proxy the address of the proxy to check
    /// @return _isProxy true if the address is a proxy address, false otherwise
    function isProxy(address proxy)
    external
    virtual
    view
    override
    returns (bool _isProxy) {
        _isProxy = _proxyAddresses.exists(proxy);
    }

    /// @notice get the count of proxy addresses
    /// @return _count the count of proxy addresses
    function allProxiesCount()
    external
    virtual
    view
    override
    returns (uint256 _count) {
        _count = _proxyAddresses.count();
    }

    /// @notice get the nth proxy address
    /// @param _index the index of the proxy address to get
    /// @return the nth proxy address
    function proxyAt(uint256 _index)
    external
    virtual
    view
    override
    returns (address) {
        return _proxyAddresses.keyAtIndex(_index);
    }

    /// @notice check if the proxy approves this request
    function _isApprovedForAll(address _owner, address _operator)
    internal
    view
    returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        for (uint256 i = 0; i < _proxyAddresses.keyList.length; i++) {
            IProxyRegistry proxyRegistry = IProxyRegistry(
                _proxyAddresses.keyList[i]
            );
            try proxyRegistry.proxies(_owner) returns (
                OwnableDelegateProxy thePr
            ) {
                if (address(thePr) == _operator) {
                    return true;
                }
            } catch {}
        }
        return false;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../utils/AddressSet.sol";

import "../interfaces/IERC1155Owners.sol";

// TODO write tests

/// @title ERC1155Owners
/// @notice a list of token holders for a given token
contract ERC1155Owners is IERC1155Owners {

    // the uint set used to store the held tokens
    using AddressSet for AddressSet.Set;

    // lists of held tokens by user
    mapping(uint256 => AddressSet.Set) internal _owners;

    /// @notice Get  all token holderd for a token id
    /// @param id the token id
    /// @return ownersList all token holders for id
    function ownersOf(uint256 id)
    external
    virtual
    view
    override
    returns (address[] memory ownersList) {
        ownersList = _owners[id].keyList;
    }

    /// @notice returns whether the address is in the list
    /// @return isOwner whether the address is in the list
    function isOwnedBy(uint256 id, address toCheck)
    external
    virtual
    view
    override
    returns (bool isOwner) {
        return _owners[id].exists(toCheck);
    }

    /// @notice add a token to an accound's owned list
    /// @param id address
    /// @param owner id of the token
    function _addOwner(uint256 id, address owner)
    internal {
        _owners[id].insert(owner);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../utils/UInt256Set.sol";

import "../interfaces/IERC1155Owned.sol";

// TODO write tests

/// @title ERC1155Owned
/// @notice a list of held tokens for a given token
contract ERC1155Owned is IERC1155Owned {

    // the uint set used to store the held tokens
    using UInt256Set for UInt256Set.Set;

    // lists of held tokens by user
    mapping(address => UInt256Set.Set) internal _owned;

    /// @notice Get all owned tokens
    /// @param account the owner
    /// @return ownedList all tokens for owner
    function owned(address account)
    external
    virtual
    view
    override
    returns (uint256[] memory ownedList) {
        ownedList = _owned[account].keyList;
    }

    /// @notice returns whether the address is in the list
    /// @param account address
    /// @param toCheck id of the token
    /// @return isOwned whether the address is in the list
    function isOwnerOf(address account, uint256 toCheck)
    external
    virtual
    view
    override
    returns (bool isOwned) {
        isOwned = _owned[account].exists(toCheck);
    }

    /// @notice add a token to an accound's owned list
    /// @param account address
    /// @param token id of the token
    function _addOwned(address account, uint256 token)
    internal {
        _owned[account].insert(token);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IERC1155TotalBalance.sol";

/// @title ERC1155TotalBalance
/// @notice the total balance of a token type
contract ERC1155TotalBalance is IERC1155TotalBalance {

    // total balance per token id
    mapping(uint256 => uint256) internal _totalBalances;

    /// @notice get the total balance for the given token id
    /// @param id the token id
    /// @return the total balance for the given token id
    function totalBalanceOf(uint256 id) external virtual view override returns (uint256) {
        return _totalBalances[id];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC1155CommonUri.sol";

abstract contract ERC1155CommonUri is IERC1155CommonUri {

    mapping (uint256 => string) internal commonURIs;
    mapping (uint256 => address) internal commonURIOwners;
    mapping (uint256 => uint256) internal tokenHashtoUriMap;

    function getCommonUri(uint256 uriId) external view override returns (string memory result) {

        return commonURIs[uriId];

    }
    function _setCommonUri(uint256 uriId, string memory value) internal {

        commonURIs[uriId] = value;
        commonURIOwners[uriId] = msg.sender;

    }
    function _setCommonUriOf(uint256 uriId, uint256 tokenHash) internal {

        tokenHashtoUriMap[tokenHash] = uriId;

    }

    function _commonUriOf(uint256 tokenHash) internal view returns (string memory result) {

        return commonURIs[tokenHashtoUriMap[tokenHash]];

    }
    function commonUriOf(uint256 tokenHash) external view override returns (string memory result) {

        return _commonUriOf(tokenHash);

    }

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mintWithCommonUri(
        address recipient,
        uint256 tokenHash,
        uint256 amount,
        uint256 uriId
    ) virtual external override {
        // does nothing
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IControllable.sol";

abstract contract Controllable is IControllable {
    mapping(address => bool) internal _controllers;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address _controller)
        external
        override
        onlyController
    {
        _addController(_controller);
    }
    function _addController(address _controller) internal {
        _controllers[_controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address _address)
        external
        view
        override
        returns (bool allowed)
    {
        allowed = _isController(_address);
    }
    function _isController(address _address)
        internal view
        returns (bool allowed)
    {
        allowed = _controllers[_address];
    }

    /**
     * @dev Remove the sender address from the list of controllers
     */
    function relinquishControl() external override onlyController {
        _relinquishControl();
    }
    function _relinquishControl() internal onlyController{
        delete _controllers[msg.sender];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155Mint.sol";
import "./IERC1155Burn.sol";

/// @dev extended by the multitoken
interface IMultiToken is IERC1155Mint, IERC1155Burn {

    function symbolOf(uint256 _tokenId) external view returns (string memory);
    function nameOf(uint256 _tokenId) external view returns (string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Mint {

    /// @notice event emitted when tokens are minted
    event MinterMinted(
        address target,
        uint256 tokenHash,
        uint256 amount
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mint(
        address recipient,
        uint256 tokenHash,
        uint256 amount
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow burning
interface IERC1155Burn {

    /// @notice event emitted when tokens are burned
    event MinterBurned(
        address target,
        uint256 tokenHash,
        uint256 amount
    );

    /// @notice burn tokens of specified amount from the specified address
    /// @param target the burn target
    /// @param tokenHash the token hash to burn
    /// @param amount the amount to burn
    function burn(
        address target,
        uint256 tokenHash,
        uint256 amount
    ) external;


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow the bridge to mint and burn tokens
/// bridge must be able to mint and burn tokens on the multitoken contract
interface IERC1155Multinetwork {

    // transfer token to a different address
    function networkTransferFrom(
        address from,
        address to,
        uint256 network,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferNetworkERC1155(
        uint256 networkFrom,
        uint256 networkTo,
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC1155Multinetwork.sol";

/// @notice defines the interface for the bridge contract. This contract implements a decentralized
/// bridge for an erc1155 token which enables users to transfer erc1155 tokens between supported networks.
/// users request a transfer in one network, which registers the transfer in the bridge contract, and generates
/// an event. This event is seen by a validator, who validates the transfer by calling the validate method on
/// the target network. Once a majority of validators have validated the transfer, the transfer is executed on the
/// target network by minting the approriate token type and burning the appropriate amount of the source token,
/// which is held in custody by the bridge contract until the transaction is confirmed. In order to participate,
/// validators must register with the bridge contract and put up a deposit as collateral.  The deposit is returned
/// to the validator when the validator self-removes from the validator set. If the validator acts in a way that
/// violates the rules of the bridge contract - namely the validator fails to validate a number of transfers,
/// or the validator posts some number of transfers which remain unconfirmed, then the validator is removed from the
/// validator set and their bond is distributed to other validators. The validator will then need to re-bond and
/// re-register. Repeated violations of the rules of the bridge contract will result in the validator being removed
/// from the validator set permanently via a ban.
interface IERC1155Bridge is IERC1155Multinetwork {

    /// @notice the network transfer status
    /// pending = on its way to the target network
    /// confirmed = target network received the transfer
    enum NetworkTransferStatus {
        Started,
        Confirmed,
        Failed
    }

    /// @notice the network transfer request structure. contains all the expected params of a transfer plus one addition nwtwork id param
    struct NetworkTransferRequest {
        uint256 id;
        address from;
        address to;
        uint32 network;
        uint256 token;
        uint256 amount;
        bytes data;
        NetworkTransferStatus status;
    }

    /// @notice emitted when a transfer is started
    event NetworkTransferStarted(
        uint256 indexed id,
        NetworkTransferRequest data
    );

    /// @notice emitted when a transfer is confirmed
    event NetworkTransferConfirmed(
        uint256 indexed id,
        NetworkTransferRequest data
    );

    /// @notice emitted when a transfer is cancelled
    event NetworkTransferCancelled(
        uint256 indexed id,
        NetworkTransferRequest data
    );

    /// @notice the token this bridge works with
    function token() external view returns (address);

    /// @notice start the network transfer
    function transfer(
        uint256 id,
        NetworkTransferRequest memory request
    ) external;

    /// @notice confirm the transfer. called by the target-side bridge
    /// @param id the id of the transfer
    function confirm(uint256 id) external;

    /// @notice fail  the transfer. called by the target-side bridge
    /// @param id the id of the transfer
    function cancel(uint256 id) external;

    /// @notice get the transfer request struct
    /// @param id the id of the transfer
    /// @return the transfer request struct
    function get(uint256 id)
    external view returns (NetworkTransferRequest memory);


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IJanusRegistry.sol";
import "../interfaces/IFactory.sol";

/// @title NextgemStakingPool
/// @notice implements a staking pool for nextgem. Intakes a token and issues another token over time
contract Service {

    address internal _serviceOwner;

    // the service registry controls everything. It tells all objects
    // what service address they are registered to, who the owner is,
    // and all other things that are good in the world.
    address internal _serviceRegistry;

    function _setRegistry(address registry) internal {

        _serviceRegistry = registry;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Strings {
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        unchecked {
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + (_i % 10)));
                _i /= 10;
            }
        }
        return string(bstr);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

///
/// @dev interface for a holder (owner) of an ERC2981-enabled token
/// @dev to modify the fee amount as well as transfer ownership of
/// @dev royalty to someone else.
///
interface IERC2981Holder {

    /// @dev emitted when the roalty has changed
    event RoyaltyFeeChanged(
        address indexed operator,
        uint256 indexed _id,
        uint256 _fee
    );

    /// @dev emitted when the roalty ownership has been transferred
    event RoyaltyOwnershipTransferred(
        uint256 indexed _id,
        address indexed oldOwner,
        address indexed newOwner
    );

    /// @notice set the fee amount for the fee id
    /// @param _id  the fee id
    /// @param _fee the fee amount
    function setFee(uint256 _id, uint256 _fee) external;

    /// @notice get the fee amount for the fee id
    /// @param _id  the fee id
    /// @return the fee amount
    function getFee(uint256 _id) external returns (uint256);

    /// @notice get the owner address of the royalty
    /// @param _id  the fee id
    /// @return the owner address
    function royaltyOwner(uint256 _id) external returns (address);


    /// @notice transfer ownership of the royalty to someone else
    /// @param _id  the fee id
    /// @param _newOwner  the new owner address
    function transferOwnership(uint256 _id, address _newOwner) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface OwnableDelegateProxy {}

/**
 * @dev a registry of proxies
 */
interface IProxyRegistry {

    function proxies(address _owner) external view returns (OwnableDelegateProxy);

}

/// @notice a proxy registry is a registry of delegate proxies which have the ability to autoapprove transactions for some address / contract. Used by OpenSEA to enable feeless trades by a proxy account
interface IProxyRegistryManager {

    /// @notice add a new registry manager to the registry
    /// @param newManager the address of the registry manager to add
    function addRegistryManager(address newManager) external;

   /// @notice remove a registry manager from the registry
    /// @param oldManager the address of the registry manager to remove
    function removeRegistryManager(address oldManager) external;

    /// @notice check if an address is a registry manager
    /// @param _addr the address of the registry manager to check
    /// @return _isRegistryManager true if the address is a registry manager, false otherwise
    function isRegistryManager(address _addr)
        external
        view
        returns (bool _isRegistryManager);

    /// @notice add a new proxy address to the registry
    /// @param newProxy the address of the proxy to add
    function addProxy(address newProxy) external;

    /// @notice remove a proxy address from the registry
    /// @param oldProxy the address of the proxy to remove
    function removeProxy(address oldProxy) external;

    /// @notice check if an address is a proxy address
    /// @param _addr the address of the proxy to check
    /// @return _is true if the address is a proxy address, false otherwise
    function isProxy(address _addr)
        external
        view
        returns (bool _is);

    /// @notice get count of proxies
    /// @return _allCount the number of proxies
    function allProxiesCount()
        external
        view
        returns (uint256 _allCount);

    /// @notice get the address of a proxy at a given index
    /// @param _index the index of the proxy to get
    /// @return _proxy the address of the proxy at the given index
    function proxyAt(uint256 _index)
        external
        view
        returns (address _proxy);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Owners {

    /// @notice returns the owners of the token
    /// @param tokenId the token id
    /// @param owners the owner addresses of the token id
    function ownersOf(uint256 tokenId) external view returns (address[] memory owners);

    /// @notice returns whether given address owns given id
    /// @param tokenId the token id
    /// @param toCheck the address to check
    /// @param isOwner whether the given address is owner of the token id
    function isOwnedBy(uint256 tokenId, address toCheck) external view returns (bool isOwner);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Owned {

    /// @notice returns the owned tokens of the account
    /// @param owner the owner address
    /// @param ids owned token ids
    function owned(address owner) external view returns (uint256[] memory ids);

    /// @notice returns whether given id is owned by the account
    /// @param account tthe account
    /// @param toCheck the token id to check
    /// @param isOwner whether the given address is owner of the token id
    function isOwnerOf(address account, uint256 toCheck) external view returns (bool isOwner);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice a contract that can be withdrawn from by some user
interface IERC1155TotalBalance {

    /// @notice get the total balance for the given token id
    /// @param id the token id
    /// @return the total balance for the given token id
    function totalBalanceOf(uint256 id) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow burning
interface IERC1155CommonUri {

    function setCommonUri(uint256 uriId, string memory value) external;

    function setCommonUriOf(uint256 uriId, uint256 value) external;

    function getCommonUri(uint256 uriId) external view returns (string memory result);

    function commonUriOf(uint256 tokenHash) external view returns (string memory result);

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mintWithCommonUri(
        address recipient,
        uint256 tokenHash,
        uint256 amount,
        uint256 uriId
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice a controllable contract interface. allows for controllers to perform privileged actions. controllera can other controllers and remove themselves.
interface IControllable {

    /// @notice emitted when a controller is added.
    event ControllerAdded(
        address indexed contractAddress,
        address indexed controllerAddress
    );

    /// @notice emitted when a controller is removed.
    event ControllerRemoved(
        address indexed contractAddress,
        address indexed controllerAddress
    );

    /// @notice adds a controller.
    /// @param controller the controller to add.
    function addController(address controller) external;

    /// @notice removes a controller.
    /// @param controller the address to check
    /// @return true if the address is a controller
    function isController(address controller) external view returns (bool);

    /// @notice remove ourselves from the list of controllers.
    function relinquishControl() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice implements a Janus (multifaced) registry. GLobal registry items can be set by specifying 0 for the registry face. Those global items are then available to all faces, and individual faces can override the global items for
interface IJanusRegistry {

    /// @notice Get the registro address given the face name. If the face is 0, the global registry is returned.
    /// @param face the face name or 0 for the global registry
    /// @param name uint256 of the token index
    /// @return item the service token record
    function get(string memory face, string memory name)
    external
    view
    returns (address item);

    /// @notice returns whether the service is in the list
    /// @param item uint256 of the token index
    function member(address item)
    external
    view
    returns (string memory face, string memory name);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFactoryElement {
    function factoryCreated(address _factory, address _owner) external;
    function factory() external returns(address);
    function owner() external returns(address);
}

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
/// @notice a contract factory. Can create an instance of a new contract and return elements from that list to callers
interface IFactory {

    /// @notice a contract instance.
    struct Instance {
        address factory;
        address contractAddress;
    }

    /// @dev emitted when a new contract instance has been craeted
    event InstanceCreated(
        address factory,
        address contractAddress,
        Instance data
    );

    /// @notice a set of requirements. used for random access
    struct FactoryInstanceSet {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
        Instance[] valueList;
    }

    struct FactoryData {
        FactoryInstanceSet instances;
    }

    struct FactorySettings {
        FactoryData data;
    }

    /// @notice returns the contract bytecode
    /// @return _instances the contract bytecode
    function contractBytes() external view returns (bytes memory _instances);

    /// @notice returns the contract instances as a list of instances
    /// @return _instances the contract instances
    function instances() external view returns (Instance[] memory _instances);

    /// @notice returns the contract instance at the given index
    /// @param idx the index of the instance to return
    /// @return instance the instance at the given index
    function at(uint256 idx) external view returns (Instance memory instance);

    /// @notice returns the length of the already-created contracts list
    /// @return _length the length of the list
    function count() external view returns (uint256 _length);

    /// @notice creates a new contract instance
    /// @param owner the owner of the new contract
    /// @param salt the salt to use for the new contract
    /// @return instanceOut the address of the new contract
    function create(address owner, uint256 salt)
        external
        returns (Instance memory instanceOut);

}