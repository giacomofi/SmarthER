// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import "./SimpleFactory.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "./tokens/VibeERC20.sol";
import "./tokens/VibeERC721.sol";
import "./tokens/VibeERC1155.sol";
import "./RoyaltyReceiver.sol";
import "./mint/NFTMintSale.sol";
import "./mint/NFTMintSaleMultiple.sol";

contract VibeFactory is BoringBatchable {
    address public immutable vibeERC20Impl;
    address public immutable vibeERC721Impl;
    address public immutable vibeERC1155Impl;
    address public immutable royaltyReceiverImpl;
    address public immutable nftMintSale;
    address public immutable nftMintSaleMultiple;
    address public immutable claimantDropImpl;
    address public immutable claimantDropLimitedImpl;
    address public immutable vibeWhitelistSaleImpl;
    SimpleFactory public immutable factory;

    struct TierInfo {
        uint128 price;
        uint32 beginId;
        uint32 endId;
        uint32 currentId;
    }

    struct RoyaltyInformation {
        address royaltyReceiver_;
        uint16 royaltyRate_;
        uint16 derivativeRoyaltyRate;
        bool isDerivativeAllowed;
    }

    event ERC20Created(address indexed sender, address indexed proxy, bytes data);
    event ERC721Created(address indexed sender, address indexed proxy, bytes data);
    event ERC1155Created(address indexed sender, address indexed proxy, bytes data);
    event LogRoyaltyReceiver(address indexed sender, address indexed proxy, bytes data);
    event LogNFTMintSale(address indexed sender, address indexed proxy, bytes data);
    event LogNFTMintSaleMultiple(address indexed sender, address indexed proxy, bytes data);
    event ClaimantDropCreated(address indexed sender, address indexed proxy, bytes data);
    event ClaimantDropLimitedCreated(
        address indexed sender,
        address indexed proxy,
        bytes data
    );
    event VibeWhitelistSaleCreated(
        address indexed sender,
        address indexed proxy,
        bytes data
    );

    /**
     * @notice constructor
     * @param _vibeERC20Impl implementation address of VibeERC20 contract
     * @param _vibeERC721Impl implementation address of VibeERC721 contract
     * @param _vibeERC1155Impl implementation address of VibeERC1155 contract
     * @param _royaltyReceiverImpl implementation address of royalty receiver contract
     * @param _NFTMintSale implementation address of nft mint sale contract
     * @param _NFTMintSaleMultiple implementation address of nft mint sale multiple contract
     * @param _claimantDropImpl implementation address of claimantDrop contract
     * @param _claimantDropLimitedImpl implementation address of claimantDrop contract
     * @param _vibeWhitelistSaleImpl implementation address of VibeWhitelistSale contract
     * @param _simpleFactory simple factory for deployments
     */
    constructor(
        address _vibeERC20Impl,
        address _vibeERC721Impl,
        address _vibeERC1155Impl,
        address _royaltyReceiverImpl,
        address _NFTMintSale,
        address _NFTMintSaleMultiple,
        address _claimantDropImpl,
        address _claimantDropLimitedImpl,
        address _vibeWhitelistSaleImpl,
        SimpleFactory _simpleFactory
    ) {
        vibeERC20Impl = _vibeERC20Impl;
        vibeERC721Impl = _vibeERC721Impl;
        vibeERC1155Impl = _vibeERC1155Impl;
        royaltyReceiverImpl = _royaltyReceiverImpl;
        nftMintSale = _NFTMintSale;
        nftMintSaleMultiple = _NFTMintSaleMultiple;
        claimantDropImpl = _claimantDropImpl;
        claimantDropLimitedImpl = _claimantDropLimitedImpl;
        vibeWhitelistSaleImpl = _vibeWhitelistSaleImpl;
        factory = _simpleFactory;
    }

    function createRoyaltyReceiver(
        uint256[] calldata recipientBPS_,
        address[] calldata recipients_
    ) external {
        bytes memory data = abi.encode(recipientBPS_, recipients_);
        address proxy = factory.deploy(royaltyReceiverImpl, data, false);
        factory.transferOwnership(proxy, msg.sender);
        emit LogRoyaltyReceiver(msg.sender, proxy, data);
    }

    function createNFTMintSale(
        string memory symbol,
        string memory name,
        string memory baseURI,
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRoyaltyRate,
        bool isDerivativeAllowed,
        uint64 maxMint_,
        uint32 beginTime_,
        uint32 endTime_,
        uint128 price_,
        IERC20 paymentToken_
    ) external {
        bytes memory data;

        address nft = createERC721(
            name,
            symbol,
            baseURI,
            royaltyReceiver_,
            royaltyRate_,
            derivativeRoyaltyRate,
            isDerivativeAllowed,
            address(0)
        );

        data = abi.encode(
            nft,
            maxMint_,
            beginTime_,
            endTime_,
            price_,
            paymentToken_,
            msg.sender
        );

        address proxy = factory.deploy(nftMintSale, data, false);

        factory.exec(nft, abi.encodeCall(VibeERC721.setMinter, (proxy, true)));
        factory.transferOwnership(nft, msg.sender);

        emit LogNFTMintSale(msg.sender, proxy, data);
    }

    function createNFTMintSaleForExisting(
        address nft,
        uint64 maxMint_,
        uint32 beginTime_,
        uint32 endTime_,
        uint128 price_,
        IERC20 paymentToken_
    ) external {
        bytes memory data;

        data = abi.encode(
            nft,
            maxMint_,
            beginTime_,
            endTime_,
            price_,
            paymentToken_,
            msg.sender
        );

        address proxy = factory.deploy(nftMintSale, data, false);

        emit LogNFTMintSale(msg.sender, proxy, data);
    }

    function createNFTMintSaleMultiple(
        string memory symbol,
        string memory name,
        string memory baseURI,
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRoyaltyRate,
        bool isDerivativeAllowed,
        uint32 beginTime_,
        uint32 endTime_,
        TierInfo[] memory tiers_,
        IERC20 paymentToken
    ) external {
        bytes memory data;

        address nft = createERC721(
            name,
            symbol,
            baseURI,
            royaltyReceiver_,
            royaltyRate_,
            derivativeRoyaltyRate,
            isDerivativeAllowed,
            address(0)
        );

        data = abi.encode(
            nft,
            beginTime_,
            endTime_,
            tiers_,
            paymentToken,
            msg.sender
        );

        address proxy = factory.deploy(nftMintSaleMultiple, data, false);

        factory.exec(nft, abi.encodeCall(VibeERC721.setMinter, (proxy, true)));
        factory.transferOwnership(nft, msg.sender);

        emit LogNFTMintSaleMultiple(msg.sender, proxy, data);
    }

    function createNFTMintSaleMultipleForExisting(
        address nft,
        uint32 beginTime_,
        uint32 endTime_,
        TierInfo[] memory tiers_,
        IERC20 paymentToken
    ) external {
        bytes memory data;

        data = abi.encode(
            nft,
            beginTime_,
            endTime_,
            tiers_,
            paymentToken,
            msg.sender
        );

        address proxy = factory.deploy(nftMintSaleMultiple, data, false);

        emit LogNFTMintSaleMultiple(msg.sender, proxy, data);
    }

    function createClaimantDrop(
        address _claimantNFT,
        string memory name,
        string memory symbol,
        string memory baseURI,
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRoyaltyRate,
        bool isDerivativeAllowed
    ) external {
        bytes memory data;

        address nft = createERC721(
            name,
            symbol,
            baseURI,
            royaltyReceiver_,
            royaltyRate_,
            derivativeRoyaltyRate,
            isDerivativeAllowed,
            address(0)
        );

        data = abi.encode(nft, _claimantNFT);

        address proxy = factory.deploy(claimantDropImpl, data, false);

        factory.exec(nft, abi.encodeCall(VibeERC721.setMinter, (proxy, true)));

        emit ClaimantDropCreated(msg.sender, proxy, data);
    }


    function createClaimantDropLimited(
        address _claimantNFT,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint128 startTime,
        uint128 endTime,
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRoyaltyRate,
        bool isDerivativeAllowed
    ) external {
        bytes memory data;

        address nft = createERC721(
            name,
            symbol,
            baseURI,
            royaltyReceiver_,
            royaltyRate_,
            derivativeRoyaltyRate,
            isDerivativeAllowed,
            address(0)
        );

        data = abi.encode(startTime, endTime, nft, _claimantNFT);

        address proxy = factory.deploy(claimantDropLimitedImpl, data, false);

        factory.exec(nft, abi.encodeCall(VibeERC721.setMinter, (proxy, true)));

        emit ClaimantDropLimitedCreated(msg.sender, proxy, data);
    }

    function createVibeWhitelistSale(
        bytes32 _merkleRoot,
        string calldata _ipfsHash,
        string memory name,
        string memory symbol,
        string memory baseURI,
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRoyaltyRate,
        bool isDerivativeAllowed
    ) external {
        bytes memory data;

        address nft = createERC721(
            name,
            symbol,
            baseURI,
            royaltyReceiver_,
            royaltyRate_,
            derivativeRoyaltyRate,
            isDerivativeAllowed,
            address(0)
        );

        data = abi.encode(nft, _merkleRoot, _ipfsHash);

        address proxy = factory.deploy(vibeWhitelistSaleImpl, data, false);

        factory.exec(nft, abi.encodeCall(VibeERC721.setMinter, (proxy, true)));

        emit VibeWhitelistSaleCreated(msg.sender, proxy, data);
    }

    function createERC20(string memory name, string memory symbol) public {
        bytes memory data = abi.encode(name, symbol);
        address proxy = factory.deploy(vibeERC20Impl, data, false);
        factory.transferOwnership(proxy, msg.sender);

        emit ERC20Created(msg.sender, proxy, data);
    }

    function createERC721(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRoyaltyRate,
        bool isDerivativeAllowed,
        address owner
    ) public returns (address proxy) {
        bytes memory data = abi.encode(name, symbol, baseURI);
        proxy = factory.deploy(vibeERC721Impl, data, false);

        factory.exec(
            proxy,
            abi.encodeCall(
                VibeERC721.setRoyalty,
                (
                    royaltyReceiver_,
                    royaltyRate_,
                    derivativeRoyaltyRate,
                    isDerivativeAllowed
                )
            )
        );

        if (owner != address(0)) {
            factory.transferOwnership(proxy, owner);
        }

        emit ERC721Created(msg.sender, proxy, data);
    }

    function createERC1155(string memory uri) public {
        bytes memory data = abi.encode(uri);
        address proxy = factory.deploy(vibeERC1155Impl, data, false);

        factory.transferOwnership(proxy, msg.sender);

        emit ERC1155Created(msg.sender, proxy, data);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract SimpleFactory is BoringFactory, BoringBatchable {
    function transferOwnership(address owned, address newOwner) external {
        IOwnable(owned).transferOwnership(newOwner);
    }

    function exec(address target, bytes calldata data) external {
        target.call(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";

contract VibeERC20 is ERC20, Ownable, IMasterContract {

    constructor () ERC20("MASTER", "MASTER", 18) {}

    function init(bytes calldata data) public payable override {
        (string memory _name, string memory _symbol) = abi.decode(data, (string, string));
        require(bytes(name).length == 0 && bytes(_name).length != 0);
        _transferOwnership(msg.sender);
        name = _name;
        symbol = _symbol;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        _burn(from, amount);
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "../interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IDerivativeLicense.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
interface IProxyRegistry {
    function proxies(address) external returns (address);
}

contract VibeERC721 is
    Ownable,
    ERC721,
    IERC2981,
    IMasterContract,
    IDerivativeLicense,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    event LogSetRoyalty(
        uint16 royaltyRate,
        address indexed royaltyReceiver_,
        uint16 derivateRate,
        bool isDerivativeAllowed
    );
    event LogChangeBaseURI(string baseURI, bool immutability_);
    event LogMinterChange(address indexed minter, bool status);

    uint256 private constant BPS = 10_000;

    uint256 public totalSupply;
    string public baseURI;

    struct RoyaltyData {
        address royaltyReceiver;
        uint16 royaltyRate;
        uint16 derivativeRoyaltyRate;
        bool isDerivativeAllowed;
    }

    RoyaltyData public royaltyInformation;

    bool public immutability = false;

    constructor() ERC721("MASTER", "MASTER") {}

    mapping(address => bool) public isMinter;

    modifier onlyMinter() {
        require(isMinter[msg.sender]);
        _;
    }

    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
        emit LogMinterChange(minter, status);
    }

    function renounceMinter() external {
        isMinter[msg.sender] = false;
        emit LogMinterChange(msg.sender, false);
    }

    function init(bytes calldata data) public payable override {
        (
            string memory _name,
            string memory _symbol,
            string memory baseURI_
        ) = abi.decode(data, (string, string, string));
        require(bytes(baseURI).length == 0 && bytes(baseURI_).length != 0);
        _transferOwnership(msg.sender);
        name = _name;
        symbol = _symbol;
        baseURI = baseURI_;
    }

    function mint(address to) external onlyMinter returns (uint256 tokenId) {
        tokenId = totalSupply++;
        _mint(to, tokenId);
    }

    function mintWithId(address to, uint256 tokenId) external onlyMinter {
        _mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {ERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {ERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function burn(uint256 id) external {
        address oldOwner = _ownerOf[id];

        require(
            msg.sender == oldOwner ||
                msg.sender == getApproved[id] ||
                isApprovedForAll[oldOwner][msg.sender],
            "NOT_AUTHORIZED"
        );

        _burn(id);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            royaltyInformation.royaltyReceiver,
            (_salePrice * royaltyInformation.royaltyRate) / BPS
        );
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the derivative royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function derivativeRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(royaltyInformation.isDerivativeAllowed);
        return (
            royaltyInformation.royaltyReceiver,
            (_salePrice * royaltyInformation.derivativeRoyaltyRate) / BPS
        );
    }

    function setRoyalty(
        address royaltyReceiver_,
        uint16 royaltyRate_,
        uint16 derivativeRate,
        bool isDerivativeAllowed
    ) external onlyOwner {
        require(royaltyReceiver_ != address(0));
        // If Derivative Works were turned on in the past, this can not be retracted in the future
        isDerivativeAllowed = royaltyInformation.isDerivativeAllowed
            ? true
            : isDerivativeAllowed;
        royaltyInformation = RoyaltyData(
            royaltyReceiver_,
            royaltyRate_,
            derivativeRate,
            isDerivativeAllowed
        );
        emit LogSetRoyalty(
            royaltyRate_,
            royaltyReceiver_,
            derivativeRate,
            isDerivativeAllowed
        );
    }

    function changeBaseURI(string memory baseURI_, bool immutability_)
        external
        onlyOwner
    {
        require(immutability == false, "Immutable");
        immutability = immutability_;
        baseURI = baseURI_;

        emit LogChangeBaseURI(baseURI_, immutability_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x2a55205a || // ERC165 Interface ID for IERC2981
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            (interfaceId == 0x15a779f5 &&
                royaltyInformation.isDerivativeAllowed);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract VibeERC1155 is ERC1155, Ownable, IMasterContract, DefaultOperatorFilterer {

    string public _uri;

    function uri(uint256 id) public view override returns (string memory) {
        return _uri;
    }

    function init(bytes calldata data) public payable override {
        (string memory uri_) = abi.decode(data, (string));
        require(bytes(_uri).length == 0 && bytes(uri_).length != 0);
        _uri = uri_;
        _transferOwnership(msg.sender);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(account, id, amount, data);
    }

    function batchMint(address to, uint256 fromId, uint256 toId, uint256 amount, bytes memory data) external onlyOwner {
        for (uint256 id = fromId; id <= toId; id++) {
            _mint(to, id, amount, data);
        }
    }

     /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}

// SPDX-LICENSE-IDENTIFIER: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "./interfaces/IDistributor.sol";

contract RoyaltyReceiver is Ownable, IDistributor {
    using SafeTransferLib for ERC20;

    event LogSetRecipients(address[] recipients); 
    event LogSetrecipientBPS (uint256[] recipientBPS);
    event LogDistributeToken(ERC20 indexed token, address indexed recipient, uint256 amount);

    uint256 public constant BPS = 10_000;
    uint256[] public recipientBPS;
    address[] public recipients;

    function init(bytes calldata data) public payable{
        (uint256[] memory recipientBPS_, address[] memory recipients_) = abi.decode(data,(uint256[], address[]));
        require(recipients.length == 0 && recipients_.length != 0);
        _transferOwnership(msg.sender);
        recipientBPS = recipientBPS_;
        recipients = recipients_;

        uint256 total;

        for (uint256 i; i < recipientBPS.length; i++ ) {
            total += recipientBPS[i];
        }

        require (total == BPS);

        emit LogSetRecipients (recipients_);

        emit LogSetrecipientBPS (recipientBPS_);
    }

    function setRecipients(address[] calldata recipients_) external onlyOwner {
        recipients = recipients_;
        require(recipients_.length == recipientBPS.length);

        emit LogSetRecipients (recipients_);
    }

    function setRecipientBPS(uint256[] calldata recipientBPS_) external onlyOwner {
        recipientBPS = recipientBPS_;
        require(recipientBPS_.length == recipients.length);
        uint256 total;

        for (uint256 i; i < recipientBPS.length; i++ ) {
            total += recipientBPS[i];
        }

        require (total == BPS);

        emit LogSetrecipientBPS (recipientBPS_);
    }
 
    function distributeERC20(ERC20 token) public {
        uint256 totalAmount = token.balanceOf(address(this));
        for (uint256 i; i < recipientBPS.length; i++ ) {
            uint256 amount = totalAmount * recipientBPS[i] / BPS;
            token.safeTransfer(recipients[i], amount);
            emit LogDistributeToken(token, recipients[i], amount);
        }
    }

    function distribute(IERC20 token, uint256 amount) external override {
        distributeERC20(ERC20(address(token)));
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(IDistributor).interfaceId;
    }
    
}

// SPDX-LICENSE-IDENTIFIER: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";
import "../SimpleFactory.sol";
import "../tokens/VibeERC721.sol";
import "../interfaces/IDistributor.sol";

contract NFTMintSale is Ownable {
    using BoringERC20 for IERC20;
    uint256 public constant BPS = 100_000;
    address private immutable masterNFT;

    VibeERC721 public nft;
    SimpleFactory public immutable vibeFactory;
    uint64 public maxMint;
    uint32 public beginTime;
    uint32 public endTime;
    uint128 public price;
    IERC20 public paymentToken;
    event Created(bytes data);
    event LogNFTBuy(address indexed recipient, uint256 tokenId);
    event SaleExtended(uint32 newEndTime);
    event SaleEnded();
    event SaleEndedEarly();
    event TokensClaimed(uint256 total, uint256 fee, address proceedRecipient);

    struct VibeFees {
        address vibeTreasury;
        uint96 feeTake;
    }

    VibeFees public fees;

    constructor (address masterNFT_, SimpleFactory vibeFactory_) {
        masterNFT = masterNFT_;
        vibeFactory = vibeFactory_;
    }

    modifier onlyMasterContractOwner {
        address master = vibeFactory.masterContractOf(address(this));
        if (master != address(0)) {
            require(Ownable(master).owner() == msg.sender);
        }
        _;
    }

    function setVibeFees(address vibeTreasury_, uint96 feeTake_) external onlyMasterContractOwner {
        fees = VibeFees(vibeTreasury_, feeTake_);
    }

    function init(bytes calldata data) public payable {
        (address proxy, uint64 maxMint_, uint32 beginTime_, uint32 endTime_, uint128 price_, IERC20 paymentToken_, address owner_) = abi.decode(data, (address, uint64, uint32, uint32, uint128, IERC20, address));
        
        require(nft == VibeERC721(address(0)), "Already initialized");

        _transferOwnership(owner_);

        {
            (address treasury, uint96 feeTake )= NFTMintSale(vibeFactory.masterContractOf(address(this))).fees();

            fees = VibeFees(treasury, feeTake);
        }

        nft = VibeERC721(proxy);

        maxMint = maxMint_;
        price = price_;
        paymentToken = paymentToken_;
        beginTime = beginTime_;
        endTime = endTime_;

        emit Created(data);
    }

    function buyNFT(address recipient) external {
        require(block.timestamp >= beginTime && block.timestamp <= endTime && nft.totalSupply() < maxMint);
        paymentToken.safeTransferFrom(msg.sender, address(this), price);
        nft.mint(recipient);
        emit LogNFTBuy(recipient, nft.totalSupply());
    }

    function removeTokensAndReclaimOwnership(address proceedRecipient) external onlyOwner {
        if(block.timestamp < endTime){
            endTime = uint32(block.timestamp);
            emit SaleEndedEarly();
        } else {
            emit SaleEnded();
        }
        uint256 total = paymentToken.balanceOf(address(this));
        uint256 fee = total * uint256(fees.feeTake) / BPS;
        paymentToken.safeTransfer(proceedRecipient, total - fee);
        paymentToken.safeTransfer(fees.vibeTreasury, fee);
        nft.renounceMinter();
        
        if (proceedRecipient.code.length > 0) {
            (bool success, bytes memory result) = proceedRecipient.call(abi.encodeWithSignature("supportsInterface(bytes4)", type(IDistributor).interfaceId));
            if (success) {
                (bool distribute) = abi.decode(result, (bool));
                if (distribute) {
                    IDistributor(proceedRecipient).distribute(paymentToken, total - fee);
                }
            }
        }

        emit TokensClaimed(total, fee, proceedRecipient);
    }

    function extendEndTime(uint32 newEndTime) external onlyOwner {
        require(newEndTime > block.timestamp);
        endTime = newEndTime;

        emit SaleExtended(endTime);
    }

}

// SPDX-LICENSE-IDENTIFIER: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../SimpleFactory.sol";
import "../tokens/VibeERC721.sol";
import "../interfaces/IDistributor.sol";

contract NFTMintSaleMultiple is Ownable {
    event Created(bytes data);
    event LogNFTBuy(address indexed recipient, uint256 tokenId, uint256 tier);
    event LogNFTBuyMultiple(address indexed recipient, uint256[] tiers);
    event SaleExtended(uint32 newEndTime);
    event SaleEnded();
    event SaleEndedEarly();
    event TokensClaimed(uint256 total, uint256 fee, address proceedRecipient);

    using BoringERC20 for IERC20;

    uint256 public constant BPS = 100_000;
    address private immutable masterNFT;

    VibeERC721 public nft;
    uint32 public beginTime;
    uint32 public endTime;

    struct TierInfo {
        uint128 price;
        uint32 beginId;
        uint32 endId;
        uint32 currentId;
    }

    TierInfo[] public tiers;
    IERC20 public paymentToken;

    SimpleFactory public immutable vibeFactory;

    struct VibeFees {
        address vibeTreasury;
        uint96 feeTake;
    }
    
    VibeFees public fees;

    constructor (address masterNFT_, SimpleFactory vibeFactory_) {
        masterNFT = masterNFT_;
        vibeFactory = vibeFactory_;
    }

    modifier onlyMasterContractOwner {
        address master = vibeFactory.masterContractOf(address(this));
        if (master != address(0)) {
            require(Ownable(master).owner() == msg.sender);
        }
        _;
    }

    function setVibeFees(address vibeTreasury_, uint96 feeTake_) external onlyMasterContractOwner {
        fees = VibeFees(vibeTreasury_, feeTake_);
    }

    function init(bytes calldata data) external {
        (address proxy, uint32 beginTime_, uint32 endTime_, TierInfo[] memory tiers_, IERC20 paymentToken_, address owner_) = abi.decode(data, (address, uint32, uint32, TierInfo[], IERC20, address));
        require(nft == VibeERC721(address(0)), "Already initialized");

        _transferOwnership(owner_);


        {
            (address treasury, uint96 feeTake )= NFTMintSaleMultiple(vibeFactory.masterContractOf(address(this))).fees();

            fees = VibeFees(treasury, feeTake);
        }

        nft = VibeERC721(proxy);

        {
            // circumvents UnimplementedFeatureError: Copying of type struct NFTMintSaleMultiple.TierInfo calldata[] calldata to storage not yet supported.
            for(uint256 i; i < tiers_.length; i++) {
                tiers.push(tiers_[i]);
            }
        }
        

        paymentToken = paymentToken_;
        beginTime = beginTime_;
        endTime = endTime_;

        {
            // checks parameter for correct values, can be commented out for increased gas efficiency.
            for (uint256 i = tiers_.length - 1; i > 0; i--) {
                require(tiers_[i].endId >= tiers_[i].beginId && tiers_[i-1].endId < tiers_[i].beginId, "Parameter verification failed");
            }
        }
        
        emit Created(data);
    }

    function buyNFT(address recipient, uint256 tier) public {
        TierInfo memory tierInfo = tiers[tier];
        uint256 id = uint256(tierInfo.currentId);
        require(block.timestamp >= beginTime && block.timestamp <= endTime && id <= tierInfo.endId);
        paymentToken.safeTransferFrom(msg.sender, address(this), uint256(tierInfo.price));
        nft.mintWithId(recipient, id);
        tiers[tier].currentId++;
        emit LogNFTBuy(recipient, id, tier);
    }

    function buyMultipleNFT(address recipient, uint256[] calldata tiersToBuy) external {
        for (uint i; i < tiersToBuy.length; i++) {
            buyNFT(recipient, tiersToBuy[i]);
        }

        emit LogNFTBuyMultiple(recipient, tiersToBuy);
    }

    function removeTokensAndReclaimOwnership(address proceedRecipient) external onlyOwner {
        if(block.timestamp < endTime){
            endTime = uint32(block.timestamp);
            emit SaleEndedEarly();
        } else {
            emit SaleEnded();
        }
        uint256 total = paymentToken.balanceOf(address(this));
        uint256 fee = total * uint256(fees.feeTake) / BPS;
        paymentToken.safeTransfer(proceedRecipient, total - fee);
        paymentToken.safeTransfer(fees.vibeTreasury, fee);
        nft.renounceMinter();

        if (proceedRecipient.code.length > 0) {
            (bool success, bytes memory result) = proceedRecipient.call(abi.encodeWithSignature("supportsInterface(bytes4)", type(IDistributor).interfaceId));
            if (success) {
                (bool distribute) = abi.decode(result, (bool));
                if (distribute) {
                    IDistributor(proceedRecipient).distribute(paymentToken, total - fee);
                }
            }
        }

        emit TokensClaimed(total, fee, proceedRecipient);
    }

    function extendEndTime(uint32 newEndTime) external onlyOwner {
        require(newEndTime > block.timestamp);
        endTime = newEndTime;

        emit SaleExtended(endTime);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Mapping from masterContract to an array of all clones
    /// On mainnet events can be used to get this list, but events aren't always easy to retrieve and
    /// barely work on sidechains. While this adds gas, it makes enumerating all clones much easier.
    mapping(address => address[]) public clonesOf;

    /// @notice Returns the count of clones that exists for a specific masterContract
    /// @param masterContract The address of the master contract.
    /// @return cloneCount total number of clones for the masterContract.
    function clonesOfCount(address masterContract) public view returns (uint256 cloneCount) {
        cloneCount = clonesOf[masterContract].length;
    }

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;
        clonesOf[masterContract].push(cloneAddress);

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
///
/// @dev Interface for the NFT Royalty Standard
/// A NFT Contract implementing this is expected to allow derivative works.
/// On every primary or secondary sale of such derivative work, the following
/// derivative fees have to be paid.
///
interface IDerivativeLicense is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// if the call per EIP165 standard returns false, 
    /// this function SHOULD revert, a license is then not given
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the derivative royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function derivativeRoyaltyInfo (
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
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
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IDistributor is IERC165 {
    function distribute(IERC20 token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}