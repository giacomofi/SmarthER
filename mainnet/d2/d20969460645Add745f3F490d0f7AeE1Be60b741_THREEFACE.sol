// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './3FACEBase.sol';
import './3FACESplits.sol';

/**
 * @title THREEFACE
 *                                                                           ▄▄▀▀▀▀█
 *                                          ▄▄▄▄▄▄                 ▄▄▄▄▄▄▄▀▀      ▐▌
 *                                   ▄▄▄▄▓▀▀      █              ▄▀              ▄█▌
 *                                 ▄▀           ▄▄▀             █          ▄▄▄████
 *                                ▓      ▄██████▀              █     ▄▄██████▀▀   ▄▄█▀▀▀▀▀▓
 *                ▄▄▄▄▄▄▄▄▄▄▄▄▄   ▓     ▓██                   ▐▌    ███▀▀   ▄▄▀▀▀▀        ██
 *          ▄▄▀▀▀▀             █  ▐▌    ██▌                   ▐    ██    ▄▀              ▄█
 *       ▐▀                    ██ ▐▌    ██▌                   █   ██    ▓     ▄▄▄█████▀▀▀▀
 *       ▐         ▄▄▄█████    ██ ▐     ██▌                  ▐▌  ▐█▌    █    ▐██
 *       ▐▌   █████▀▀▀▀▀▀▀▀▌   ██ ▓     ██▌                  ▐   ██    ▐▌    ▓█▌
 *        ▌  ▓█▌           ▌   ██ ▐▌   ▐██                   █  ██     ▐▌    ██
 *         ▀▀▀▀            ▌  ▐██ ▐▌  ▐█▀  ▄▄▄▄              ▌ ▐█▌     ▐▌   ▐█▌ ▄▄▓▀▀▀▄
 *                        ▐▌  ▐██ ▐   ▀▀▀▀▀   ▌             ▐▌ ▓█      ▐     ▀▀▀     ▄▌
 *                       ▄▀   ▄█▌ █       ▄▄▄█              ▐  █▌      █   ▄▄▄▄▄▄▄████
 *            ▄▀  ▀▄ ▄▄▀▀   ▄██   ▌    ███▀▀▀ ▄▄▀▀▀▀▀▀▀▄    █  █▌     █    ██▀▀▀▀▀▀▀
 *           ▐              ▀███  ▌   ██    ▐▌   ▄▄▄   ▐   ▐  ▐█     ▐    ▐█▌
 *           █      ▄▄▄██     ██  ▌  ▐██    █   ██  █  ▐   ▌  ██     █    ▐█      ▄▄▀▀▀▀▀█
 *             ▀▀▀███▀▀ █▌   ▐██  ▌  ██▌    ▌   ▀▀▀▀▀  ▐▌ ▐▌  █▌    ▐▌     ▀▀▀▀▀▀      ▄██
 *         ▄▄▄          █    ██  ▓   ██    ▐▌  ▄█████▄ ▐  ▐   █▌    ▓             ▄████▀
 *        █  ▐      ▄▄▀▀    ██  ▐▌  ▐█▌     ▌ ▐█▌   ▐█ █  ▐   ▓▌    ▀▀████▄▄▄▄▄███▀
 *       ▐    ▀▀▀▀▀▀       ██   █   ██      █▄██     ██▌  ▐   ▐▌          ▀▀▀▀▀▀▀
 *       ▐            ▄▄▄███▀  ▓    ██                    ▐    █      ▄▄▄▄▄▄▄▄▄
 *        ▀▄▄▄▄▄██████▀▀▀     ▄▀   ▐█▌                     ▀▄   ▀▀▀▀▀▀         █▄
 *                          ▄█    ▄██                       ▀████▄▄▄▄▄▄▄▄▄▄▄▄▄██
 *                  ▄▀▀▀▀▀▀    ▄███▀                                  ▀▀▀▀▀▀▀▀
 *               ▄▓▀        ▄███▀
 *               ▌▄▄▄██████▀▀▀
 */
contract THREEFACE is THREEFACESplits, THREEFACEBase {
    constructor()
        THREEFACEBase(
            'THREEFACE',
            '3FACE',
            'https://3face.mypinata.cloud/ipfs/',
            addresses,
            splits,
            0.2 ether,
            0.1 ether,
            0.5 ether,
            0.003 ether
        )
    {
        // Implementation version: V1

        uint256[] memory natures = new uint256[](4);
        natures[0] = 100;
        natures[1] = 101;
        natures[2] = 102;
        natures[3] = 103;

        string[] memory natureFragments = new string[](4);
        natureFragments[0] = 'Qma8y8nhUJNymNd8b2w778cgGFdpsJWm6du75DSxc536BG'; // Change
        natureFragments[1] = 'QmT89zqM4SzCuow6LaZXSfs8PXMHAE88FJL2KjXQgfbDc4'; // Structure
        natureFragments[2] = 'QmTLpKhNduGRdDFhAZQJM6dP16SYabmib4YSN4tBoEuBEo'; // Belonging
        natureFragments[3] = 'QmUgGcKnGTYXEhoJx6pjTNQUDhbzQmoj1VB9fXPg7Ty5R9'; // Transcendence

        _setNatureFragments(natures, natureFragments);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';
import '@nftculture/nftc-open-contracts/contracts/utility/AuxHelper32.sol';
import './AuxHelperFourInto256.sol';
import './DigiSigHelper.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintThree.sol';
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Error Codes
error ExceedsMaxSupply();
error ExceedsReserveBatchSize();
error ProofInvalidPresale();
error ExceedsPresaleBatchSize();
error InvalidPresalePayment();
error ExceedsPresalePurchaseLimit();
error ExceedsPresaleSupply();
error ExceedsPublicMintBatchSize();
error InvalidPublicMintPayment();
error BindingNotAllowed();
error InvalidSelectedNature();
error InvalidRemoteMinter();

/**
 * @title THREEFACEBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721a Burnable, Queryable with @NFTCulture standardized components.
 *
 * Three phase mint:
 * Phase One - Indexed Allowlist
 * Phase Two - Indexed Allowlist
 * Phase Three - Public
 *
 * Contract features a concept called "Binding" where the user can trigger a new
 * generative artwork to take the place of a token's current artwork.
 */
abstract contract THREEFACEBase is
    ERC721ABurnable,
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintThree,
    MerkleLeaves,
    AuxHelperFourInto256,
    AuxHelper32,
    DigiSigHelper
{
    using Strings for uint256;
    using BooleanPacking for uint256;
    using MerkleClaimList for MerkleClaimList.Root;

    uint256 private constant MAX_NFTS_FOR_PRESALE_1 = 1896;
    uint256 private constant MAX_NFTS_FOR_SALE = 4096;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 32;
    uint256 private constant MAX_MINT_BATCH_SIZE = 10;

    uint256 public constant NATURE_BASE_VAL = 100;
    uint256 public constant NATURE_MIN = 0;
    uint256 public constant NATURE_MAX = 3;

    // Control flags for the token binding process.
    uint256 private constant BINDING_ALLOWED = 5;
    uint256 private constant REFUNDING_ENABLED = 6;
    uint256 internal _bindingControlFlags;
    uint256 public bindingRefundAmount;

    string public baseURI;

    MerkleClaimList.Root private _phaseOneRoot;
    MerkleClaimList.Root private _phaseTwoRoot;

    // Nature URI fragments. NatureID -> NatureURI mapping.
    mapping(uint256 => string) internal _natureUriFragments;

    // User URI fragments. TokenID -> UserURI mapping.
    // Each IPFS Hash costs about 85k gas to store.
    // There are optimizations for this, but they reduce
    // user-friendliness and forward compatiblity.
    mapping(uint256 => string) internal _userUriFragments;

    struct TokenBindingData {
        uint64 tokenId;
        uint64 generation;
        uint64 isBoundToUser;
        uint64 reserved;
    }

    mapping(uint256 => TokenBindingData) internal _tokenBindingMap;

    // Use the event log for persistence of previous URI fragments.
    // This saves about 60k gas vs. saving them in the contract.
    event ReleaseURIFragment(uint256 tokenId, uint256 generation, string previousUriFragment);

    // Use the event log for tracking when tokens have been refunded.
    event TokenBindingRefunded(uint256 tokenId);

    address private _threefaceSigner;
    address private _remoteMinter;

    modifier canBind() {
        if (!_bindingControlFlags.getBoolean(BINDING_ALLOWED)) revert BindingNotAllowed();
        _;
    }

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __phaseThreePricePerNft,
        uint256 __bindingRefundAmount
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintThree(__phaseOnePricePerNft, __phaseTwoPricePerNft, __phaseThreePricePerNft)
    {
        baseURI = __baseURI;

        _threefaceSigner = msg.sender;
        _remoteMinter = 0xdAb1a1854214684acE522439684a145E62505233;

        bindingRefundAmount = __bindingRefundAmount;
    }

    function maxPresaleOne() external pure returns (uint256) {
        return MAX_NFTS_FOR_PRESALE_1;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function phaseOneBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function phaseTwoBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        // Front end minting websites should treat this mint as an open edition, even though there is a hard cap.
        return false;
    }

    function isBindingAllowed() external view returns (bool) {
        return _isBindingAllowed();
    }

    function isRefundingEnabled() external view returns (bool) {
        return _isRefundingEnabled();
    }

    function setBindingState(
        bool __bindingAllowed,
        bool __refundingEnabled,
        uint256 __bindingRefundAmount
    ) external onlyOwner {
        uint256 tempControlFlags = _bindingControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(BINDING_ALLOWED, __bindingAllowed);
        tempControlFlags = tempControlFlags.setBoolean(REFUNDING_ENABLED, __refundingEnabled);

        _bindingControlFlags = tempControlFlags;

        if (__bindingRefundAmount > 0) {
            bindingRefundAmount = __bindingRefundAmount;
        }
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setThreefaceSigner(address __newSigner) external onlyOwner {
        _threefaceSigner = __newSigner;
    }

    function setRemoteMinter(address __newMinter) external onlyOwner {
        _remoteMinter = __newMinter;
    }

    function setNatureFragments(uint256[] memory __natureIds, string[] memory __natureUris) external onlyOwner {
        _setNatureFragments(__natureIds, __natureUris);
    }

    /**
     * @dev This is just here in case of emergency
     */
    function restoreUserFragment(
        uint256 tokenId,
        uint256 boundGenerationOverride,
        string calldata userUri,
        bool flush
    ) external onlyOwner {
        if (flush) {
            // Something bad must have happened, cause we are deliberately
            // wiping the bound state and generation here.
            delete _tokenBindingMap[tokenId];
        }

        // Do the normal workflow.
        _setBindToUser(tokenId, _tokenBindingMap[tokenId], userUri);

        if (flush) {
            _tokenBindingMap[tokenId].generation = uint64(boundGenerationOverride);
        }
    }

    /**
     * @dev This is just here in case of emergency
     */
    function restoreToBlank(uint256 tokenId, uint256 selectedNature) external onlyOwner {
        // Reset the fragment for this token.
        delete _tokenBindingMap[tokenId];

        // Make sure the ownership info is initialized.
        _initializeOwnershipAt(tokenId);

        // Override set the nature back to expected value.
        _setNature(tokenId, uint24(selectedNature));
    }

    function setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) external onlyOwner {
        _setMerkleRoots(__phaseOneRoot, __phaseTwoRoot);
    }

    function _setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) internal {
        if (__phaseOneRoot != 0) {
            _phaseOneRoot._setRoot(__phaseOneRoot);
        }

        if (__phaseTwoRoot != 0) {
            _phaseTwoRoot._setRoot(__phaseTwoRoot);
        }
    }

    function auxMintValues(address wallet)
        external
        view
        returns (uint32 presalePhaseOnePurchases, uint32 presalePhaseTwoPurchases)
    {
        // Unpack single value from _getAux() to determine presalePhaseOnePurchases and presalePhaseTwoPurchases
        return _unpack32(_getAux(wallet));
    }

    function checkProofPhaseOne(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextProofIndexPhaseOne(address wallet) external view returns (uint256) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getAux(wallet));
        return phaseOnePurchases;
    }

    function checkProofPhaseTwo(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextProofIndexPhaseTwo(address wallet) external view returns (uint256) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getAux(wallet));
        return phaseTwoPurchases;
    }

    function getPresalePhaseOneTokensPurchased(address wallet) external view returns (uint32) {
        (uint32 phaseOnePurchases, ) = _unpack32(_getAux(wallet));
        return phaseOnePurchases;
    }

    function getPresalePhaseTwoTokensPurchased(address wallet) external view returns (uint32) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getAux(wallet));
        return phaseTwoPurchases;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        uint256 nature = _getNature(tokenId);

        if (!_isBoundToUser(tokenId)) {
            // Build uri for "blank" 3face.
            return string(abi.encodePacked(base, _natureUriFragments[nature], _tokenFilename(tokenId)));
        } else {
            // Note: these are direct IPFS links, and do not need the token id appended.
            return string(abi.encodePacked(base, _userUriFragments[tokenId]));
        }
    }

    function getNature(uint256 tokenId) external view returns (uint256) {
        return _getNature(tokenId);
    }

    function getBindingInfo(uint256 tokenId) external view returns (TokenBindingData memory) {
        return _tokenBindingMap[tokenId];
    }

    function getBindingInfo_CurrentFragment(uint256 tokenId) external view returns (string memory) {
        return _userUriFragments[tokenId];
    }

    function getBindingInfo_Generation(uint256 tokenId) external view returns (uint256) {
        return _tokenBindingMap[tokenId].generation;
    }

    function getBindingInfo_IsBoundToUser(uint256 tokenId) external view returns (bool) {
        return _tokenBindingMap[tokenId].isBoundToUser == 1;
    }

    function getBindingInfo_Status(uint256 tokenId, string calldata uriFragment) external view returns (uint256) {
        bytes32 theUriFragmentHash = keccak256(abi.encodePacked(uriFragment));

        if (keccak256(abi.encodePacked(_userUriFragments[tokenId])) == theUriFragmentHash) return 1;

        return 0;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * NOTE: All tokens in a given transaction will be forced to have the same nature.
     *
     * @param friends addresses to send tokens to.
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the tokens.
     */
    function reserveTokens(
        address[] memory friends,
        uint256 count,
        uint256 selectedNature
    ) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsReserveBatchSize();

        uint256 totalMinted = _totalMinted(); // track locally to save gas.

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], totalMinted, count, selectedNature);
            totalMinted += count;
        }
    }

    /**
     * @notice Owner: reserve sets for team.
     *
     * @param friends addresses to send tokens to.
     * @param sets the number of sets to mint.
     */
    function reserveSets(address[] memory friends, uint256 sets) external payable onlyOwner {
        if (0 >= sets || sets > MAX_RESERVE_BATCH_SIZE) revert ExceedsReserveBatchSize();

        uint256 totalMinted = _totalMinted(); // track locally to save gas.

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            totalMinted = _internalMintSet(friends[idx], totalMinted, sets);
        }
    }

    /**
     * @notice Presale tokens Phase 1 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     */
    function presalePhaseOneTokens(
        bytes32[] calldata proof,
        uint256 count,
        uint256 selectedNature
    ) external payable nonReentrant isPhaseOne {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPresaleBatchSize();
        if (msg.value != phaseOnePricePerNft * count) revert InvalidPresalePayment();

        (uint32 presalePhase1Purchases, uint32 otherPhase) = _unpack32(_getAux(msg.sender));

        uint256 newBalance = presalePhase1Purchases + count;

        _setAux(msg.sender, _pack32(uint16(newBalance), otherPhase));

        _proofMintTokensPhaseOne(msg.sender, proof, newBalance, count, selectedNature);
    }

    /**
     * @notice Presale tokens Phase 2 - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     */
    function presalePhaseTwoTokens(
        bytes32[] calldata proof,
        uint256 count,
        uint256 selectedNature
    ) external payable nonReentrant isPhaseTwo {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPresaleBatchSize();
        if (msg.value != phaseTwoPricePerNft * count) revert InvalidPresalePayment();

        (uint32 otherPhase, uint32 presalePhase2Purchases) = _unpack32(_getAux(msg.sender));

        uint256 newBalance = presalePhase2Purchases + count;

        _setAux(msg.sender, _pack32(otherPhase, uint16(newBalance)));

        _proofMintTokensPhaseTwo(msg.sender, proof, newBalance, count, selectedNature);
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     * IMPORTANT: All tokens minted will have the same nature selection.
     *
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     */
    function mintTokens(uint256 count, uint256 selectedNature) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPublicMintBatchSize();
        if (msg.value != publicMintPricePerNft * count) revert InvalidPublicMintPayment();

        _internalMintTokens(msg.sender, _totalMinted(), count, selectedNature);
    }

    /**
     * @notice Same as mintTokens(), but with a to: for fiat purchasing.
     *
     * @param count the number of tokens to mint.
     * @param selectedNature the nature of the token you would like to mint.
     * @param to address where the new token should be sent.
     */
    function mintTokensTo(
        uint256 count,
        uint256 selectedNature,
        address to
    ) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > MAX_MINT_BATCH_SIZE) revert ExceedsPublicMintBatchSize();
        if (msg.value != publicMintPricePerNft * count) revert InvalidPublicMintPayment();
        if (msg.sender != _remoteMinter && _remoteMinter != 0x0000000000000000000000000000000000000000)
            revert InvalidRemoteMinter();

        _internalMintTokens(to, _totalMinted(), count, selectedNature);
    }

    /**
     * @notice Mint function that will mint a single set of tokens, 1 per nature.
     *
     * @param sets the number of sets to mint
     */
    function mintSet(uint256 sets) external payable nonReentrant isPublicMinting {
        if (0 >= sets || sets > 5) revert ExceedsPublicMintBatchSize();
        if (msg.value != publicMintPricePerNft * (4 * sets)) revert InvalidPublicMintPayment();

        _internalMintSet(msg.sender, _totalMinted(), sets);
    }

    /**
     * @notice Bind a Token to a User URI Fragment.
     *
     * This method will convert the token from being a "blank" token with a default
     * piece of artwork to a token with a generative artwork.
     *
     * The initial call to bind a token will have gas refunded according to a committed
     * amount by the project.
     *
     * @param tokenId the token to bind
     * @param userUri the URI fragment for the token
     * @param threefaceSignature an approved signature for the request
     */
    function bindToUser(
        uint256 tokenId,
        string calldata userUri,
        bytes calldata threefaceSignature
    ) external {
        _bindToUser(tokenId, userUri, threefaceSignature);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal pure virtual returns (string memory) {
        // Special: Append the slash, so it looks like '/0'
        return string(abi.encodePacked('/', tokenId.toString()));
    }

    function _internalMintSet(
        address minter,
        uint256 totalMinted,
        uint256 sets
    ) internal returns (uint256) {
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL);

        totalMinted += sets;
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL + 1);

        totalMinted += sets;
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL + 2);

        totalMinted += sets;
        _internalMintTokens(minter, totalMinted, sets, NATURE_BASE_VAL + 3);

        totalMinted += sets;

        return totalMinted;
    }

    function _internalMintTokens(
        address minter,
        uint256 totalMinted,
        uint256 count,
        uint256 selectedNature
    ) internal {
        if (totalMinted + count > MAX_NFTS_FOR_SALE) revert ExceedsMaxSupply();
        if (selectedNature < NATURE_BASE_VAL + NATURE_MIN || selectedNature > NATURE_BASE_VAL + NATURE_MAX)
            revert InvalidSelectedNature();

        uint24 selectedNatureAs24 = uint24(selectedNature);
        uint256 nextToken = _nextTokenId();

        _safeMint(minter, count);

        _setNature(nextToken, selectedNatureAs24);

        if (count > 1) {
            // Even though this code has to do quite a few duplicate lookups to get the ownerships initialized
            // the gas efficiency is still quite good. It's only about 5% cheaper to modify ERC721a to directly
            // set extra data.
            for (uint256 nextTokenIdx = nextToken + 1; nextTokenIdx < nextToken + count; nextTokenIdx++) {
                _initializeOwnershipAt(nextTokenIdx);
                _setNature(nextTokenIdx, selectedNatureAs24);
            }
        }
    }

    function _proofMintTokensPhaseOne(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 selectedNature
    ) internal {
        uint256 totalMinted = _totalMinted();
        if (totalMinted + count > MAX_NFTS_FOR_PRESALE_1) revert ExceedsPresaleSupply();

        // Verify proof matches expected target total number of claim mints.
        if (!_phaseOneRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1))) {
            //Zero-based index.
            revert ProofInvalidPresale();
        }

        _internalMintTokens(minter, totalMinted, count, selectedNature);
    }

    function _proofMintTokensPhaseTwo(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count,
        uint256 selectedNature
    ) internal {
        // Verify address is eligible for presale mints.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1))) {
            //Zero-based index.
            revert ProofInvalidPresale();
        }

        _internalMintTokens(minter, _totalMinted(), count, selectedNature);
    }

    function _setNatureFragments(uint256[] memory __natureIds, string[] memory __natureUris) internal {
        require(__natureIds.length == __natureUris.length, 'Unmatched arrays');

        for (uint256 idx = 0; idx < __natureIds.length; idx++) {
            _natureUriFragments[__natureIds[idx]] = __natureUris[idx];
        }
    }

    function _bindToUser(
        uint256 tokenId,
        string calldata userUri,
        bytes calldata threefaceSignature
    ) internal canBind {
        require(_exists(tokenId), 'No token');
        require(msg.sender == _ownershipOf(tokenId).addr, 'Not owner');

        TokenBindingData memory currentData = _tokenBindingMap[tokenId];
        uint256 generation = currentData.generation + 1;

        // Verify the new binding.
        _verifyThreefaceBinding(msg.sender, tokenId, generation, userUri, threefaceSignature);

        // Bind the token to a new fragment.
        bool initialBinding = _setBindToUser(tokenId, currentData, userUri);

        if (initialBinding && _isRefundingEnabled()) {
            payable(msg.sender).transfer(bindingRefundAmount);
            emit TokenBindingRefunded(tokenId);
        }
    }

    function _setBindToUser(
        uint256 __tokenId,
        TokenBindingData memory currentData,
        string calldata __userUri
    ) internal returns (bool) {
        bool initialBinding = false;
        if (currentData.isBoundToUser == 0) {
            currentData.tokenId = uint64(__tokenId);
            currentData.isBoundToUser = 1;
            initialBinding = true;
        } else {
            // Emit the previous URI fragment to the event log.
            emit ReleaseURIFragment(__tokenId, currentData.generation, _userUriFragments[__tokenId]);
        }

        currentData.generation++;
        _userUriFragments[__tokenId] = __userUri;

        // Now write it back to the map.
        _tokenBindingMap[__tokenId] = currentData;

        return initialBinding;
    }

    function _setNature(uint256 tokenId, uint24 selectedNature) internal {
        if (selectedNature < NATURE_BASE_VAL + NATURE_MIN || selectedNature > NATURE_BASE_VAL + NATURE_MAX)
            revert InvalidSelectedNature();

        _setExtraDataAt(tokenId, selectedNature);
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal pure override returns (uint24) {
        // Just return the existing extra data, which is the selected Nature for the token. It doesn't matter who minted it, once
        // its set, its set.
        return previousExtraData;
    }

    function _getNature(uint256 tokenId) internal view returns (uint256) {
        uint24 extraData = uint24(_ownershipAt(tokenId).extraData);
        return uint256(extraData);
    }

    function _isBoundToUser(uint256 tokenId) internal view returns (bool) {
        return _tokenBindingMap[tokenId].isBoundToUser == 1;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _verifyThreefaceBinding(
        address sender,
        uint256 tokenId,
        uint256 generation,
        string calldata userUriFragment,
        bytes calldata threefaceSignature
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(sender, tokenId, generation, userUriFragment));
        return _verify(dataHash, threefaceSignature, _threefaceSigner);
    }

    function _isBindingAllowed() internal view returns (bool) {
        return _bindingControlFlags.getBoolean(BINDING_ALLOWED);
    }

    function _isRefundingEnabled() internal view returns (bool) {
        return _bindingControlFlags.getBoolean(REFUNDING_ENABLED);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract THREEFACESplits {
    address[] internal addresses = [
        0x73565C1a7CC4A3AB19bf136aC9a1CAee60dD922c,
        0x41Fb9227c703086B2d908E177A692EdCD3d7DE2C
    ];

    uint256[] internal splits = [75, 25];
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title GuardedAgainstContracts
 * @author @NiftyMike, NFT Culture
 * @dev Helper contract to help protect against contract based mint spamming attacks.
 */
abstract contract GuardedAgainstContracts {
    modifier onlyUsers() {
        require(tx.origin == msg.sender, 'Must be user');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SlimPaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LockedPaymentSplitter
 * @author @NiftyMike, NFT Culture
 * @dev A wrapper around SlimPaymentSplitter which adds on security elements.
 *
 * Based on OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
abstract contract LockedPaymentSplitter is SlimPaymentSplitter, Ownable {
    /**
     * @dev Overrides release() method, so that it can only be called by owner.
     * @notice Owner: Release funds to a specific address.
     *
     * @param account Payable address that will receive funds.
     */
    function release(address payable account) public override onlyOwner {
        super.release(account);
    }

    /**
     * @dev Triggers a transfer to caller's address of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * @notice Sender: request payment.
     */
    function releaseToSelf() public {
        super.release(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title AuxHelper32
 * @author @NiftyMike | NFT Culture
 * @dev Helper class for ERC721a Aux storage, using 32 bit ints.
 */
abstract contract AuxHelper32 {
    function _pack32(uint32 left32, uint32 right32) internal pure returns (uint64) {
        return (uint64(left32) << 32) | uint32(right32);
    }

    function _unpack32(uint64 aux) internal pure returns (uint32 left32, uint32 right32) {
        return (uint32(aux >> 32), uint32(aux));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title AuxHelperFourInto256
 * @author @KC, NFT Culture
 * @dev Helper class for ERC721a Aux-style storage. This flavor packs 4 64bit fields into a 256 bit int.
 */
abstract contract AuxHelperFourInto256 {
    function _pack64(uint64 left64, uint64 leftCenter64, uint64 rightCenter64, uint64 right64) internal pure returns (uint256) {
        return (uint256(left64) << 192) | (uint256(leftCenter64) << 128) | (uint256(rightCenter64) << 64) | uint64(right64);
    }

    function _unpack64(uint256 aux) internal pure returns (uint64 left64, uint64 leftCenter64, uint64 rightCenter64, uint64 right64) {
        return (uint64(aux >> 192), uint64(aux >> 128), uint64(aux >> 64), uint64(aux));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

error InvalidSignature();

/**
 * @title DigiSigHelper
 * @author @NiftyMike | @NFTCulture
 * @dev Helper class for handling ECDSA signatures with OpenZepplin library.
 */
abstract contract DigiSigHelper {
    using ECDSA for bytes32;

    function _verify(
        bytes32 dataHash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        address signatureSigner = dataHash.toEthSignedMessageHash().recover(signature);
        if (signatureSigner != expectedSigner) revert InvalidSignature();

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

import './PhasedMintBase.sol';

/**
 * @title PhasedMintThree
 * @author @NiftyMike, NFT Culture
 * @dev PhasedMint: An approach to a standard system of controlling mint phases.
 *
 * This is the "Three" phase mint flavor of the PhasedMint approach.
 *
 * Note: Since the last phase is always assumed to be the public mint phase, we only
 * need to define the first and second phases here.
 */
contract PhasedMintThree is Ownable, PhasedMintBase {
    using BooleanPacking for uint256;

    uint256 private constant PHASE_ONE = 1;
    uint256 private constant PHASE_TWO = 2;

    uint256 public phaseOnePricePerNft;
    uint256 public phaseTwoPricePerNft;

    modifier isPhaseOne() {
        require(_mintControlFlags.getBoolean(PHASE_ONE), 'Phase one stopped');
        _;
    }

    modifier isPhaseTwo() {
        require(_mintControlFlags.getBoolean(PHASE_TWO), 'Phase two stopped');
        _;
    }

    constructor(
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __publicMintPricePerNft
    ) PhasedMintBase(3, __publicMintPricePerNft) {
        phaseOnePricePerNft = __phaseOnePricePerNft;
        phaseTwoPricePerNft = __phaseTwoPricePerNft;
    }

    function setMintingState(
        bool __phaseOneActive,
        bool __phaseTwoActive,
        bool __publicMintingActive,
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __publicMintPricePerNft
    ) external onlyOwner {
        uint256 tempControlFlags = _setMintingState(__publicMintingActive, __publicMintPricePerNft);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_ONE, __phaseOneActive);

        tempControlFlags = tempControlFlags.setBoolean(PHASE_TWO, __phaseTwoActive);

        _mintControlFlags = tempControlFlags;

        if (__phaseOnePricePerNft > 0) {
            phaseOnePricePerNft = __phaseOnePricePerNft;
        }

        if (__phaseTwoPricePerNft > 0) {
            phaseTwoPricePerNft = __phaseTwoPricePerNft;
        }
    }

    function isPhaseOneActive() external view returns (bool) {
        return _isPhaseOneActive();
    }

    function _isPhaseOneActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PHASE_ONE);
    }

    function isPhaseTwoActive() external view returns (bool) {
        return _isPhaseTwoActive();
    }

    function _isPhaseTwoActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PHASE_TWO);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title MerkleLeaves
 * @author @NiftyMike, NFT Culture
 * @dev Merkle Leaves for Merkle Trees - This is a companion contract to NFTC Labs' MerkleClaimList.sol library.
 * It provides leaf generation functions for both indexed and non-indexed merkle trees.
 * It also provides wrapper methods to expose the leaf generation functions to off-chain callers.
 *
 * Off-chain access is useful, because both the contract and the caller need to be able to generate the
 * leaves in a perfectly identical manner, so the generators are exposed to make it easier.
 */
abstract contract MerkleLeaves {
    /**
     * @notice External: generate a leaf for a wallet.
     *
     * @param wallet Address to hash.
     */
    function getLeafFor(address wallet) external pure returns (bytes32) {
        return _generateLeaf(wallet);
    }

    /**
     * @notice External: generate a leaf for a wallet and an embedded index value.
     *
     * @param wallet Address to hash.
     * @param index integer index to assign the leaf.
     */
    function getIndexedLeafFor(address wallet, uint256 index)
        external
        pure
        returns (bytes32)
    {
        return _generateIndexedLeaf(wallet, index);
    }

    /**
     * @dev Generate a merkle leaf based only on a wallet address. This is useful when all users
     * represented in the tree are eligible for the exact same thing, such as one free mint.
     *
     * A tiered system can be supported by this approach, by making seperate merkle trees and
     * mint functions per tier, but that approach will become ungainly if you have to support more
     * than a few tiers.
     */
    function _generateLeaf(address wallet) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(wallet));
    }

    /**
     * @dev Generate a merkle leaf based on a wallet address and an index. This is useful when all
     * users represented in the tree are eligible for different amounts of something.
     */
    function _generateIndexedLeaf(address wallet, uint256 index)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(wallet, "_", index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {MerkleRoot} from './MerkleRoot.sol';

/**
 * @title MerkleClaimList
 * @author @NiftyMike, NFT Culture
 * @dev Basic functionality for a MerkleTree that will be used as a "Claimlist"
 *
 * "Claimlist" - an approach for validating callers that is backed by a Merkle Tree.
 * Cheap to set the master claim, not that expensive to check the claim. Requires
 * off-chain generation of the Merkle Tree.
 *
 * This library allows you to declare a member variable like:
 * MerkleClaimList.Root private _claimRoot;
 *
 * The benefit of packaging this as a library, is that if you need multiple merkle trees in your
 * contract, you can declare multiple member variables using this library, and use them in similar fashion.
 *
 * see also: NFTC Labs' MerkleLeaves.sol, which is a companion abstract contract which contains helper
 * methods for generating leaves for the Merkle Tree.
 */
library MerkleClaimList {
    using MerkleRoot for bytes32;

    struct Root {
        // This variable should never be directly accessed by users of the library. See OZ comments in other libraries for more info.
        bytes32 _root;
    }

    /**
     * @dev Validate that a leaf is part of this merkle tree.
     */
    function _checkLeaf(
        Root storage root,
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal view returns (bool) {
        return root._root.check(proof, leaf);
    }

    /**
     * @dev Set the root of this merkle tree.
     */
    function _setRoot(Root storage root, bytes32 __root) internal {
        root._root = __root;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721ABurnable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721ABurnable.
 *
 * @dev ERC721A token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is ERC721A, IERC721ABurnable {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title SlimPaymentSplitter
 * @author @NiftyMike, NFT Culture
 * @dev A drop-in slim replacement version of OZ's Payment Splitter. All ERC-20 token functionality removed.
 *
 * Based on OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
contract SlimPaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event PayeeTransferred(address oldOwner, address newOwner);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;

    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }


    /**
     * @dev Allows owner to transfer their shares to somebody else; it can only be called by of a share.
     * @notice Owner: Release funds to a specific address.
     *
     * @param newOwner Payable address which has no shares and will receive the shares of the current owner.
     */
    function transferPayee(address payable newOwner) public {
        require(newOwner != address(0), "PaymentSplitter: New payee is the zero address.");
        require(_shares[msg.sender] > 0, "PaymentSplitter: You have no shares.");
        require(
            _shares[newOwner] == 0, // why not _shares[newOwner] ??
            "PaymentSplitter: New payee already has shares."
        );

        _transferPayee(newOwner);
        emit PayeeTransferred(msg.sender, newOwner);
    }

    function _transferPayee(address newOwner) private {
        if (_payees.length == 0) return;

        for (uint i = 0; i < _payees.length - 1; i++) {
            if (_payees[i] == msg.sender) {
                _payees[i] = newOwner;
                _shares[newOwner] = _shares[msg.sender];
                _shares[msg.sender] = 0;
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from '@nftculture/nftc-open-contracts/contracts/utility/BooleanPacking.sol';

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title PhasedMintBase
 * @author @NiftyMike, NFT Culture
 * @dev PhasedMint: An approach to a standard system of controlling mint phases.
 */
abstract contract PhasedMintBase is Ownable {
    using BooleanPacking for uint256;

    // BooleanPacking used on _mintControlFlags
    uint256 internal _mintControlFlags;

    uint256 private immutable PUBLIC_MINT_PHASE;

    uint256 public publicMintPricePerNft;

    modifier isPublicMinting() {
        require(_mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(uint256 publicMintPhase, uint256 __publicMintPricePerNft) {
        PUBLIC_MINT_PHASE = publicMintPhase;

        publicMintPricePerNft = __publicMintPricePerNft;
    }

    function _setMintingState(bool __publicMintingActive, uint256 __publicMintPricePerNft)
        internal
        returns (uint256)
    {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(PUBLIC_MINT_PHASE, __publicMintingActive);

        if (__publicMintPricePerNft > 0) {
            publicMintPricePerNft = __publicMintPricePerNft;
        }

        return tempControlFlags;
    }

    function isPublicMintingActive() external view returns (bool) {
        return _isPublicMintingActive();
    }

    function _isPublicMintingActive() internal view returns (bool) {
        return _mintControlFlags.getBoolean(PUBLIC_MINT_PHASE);
    }

    function supportedPhases() external view returns (uint256) {
        return PUBLIC_MINT_PHASE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title BooleanPacking
 * @author @NiftyMike, NFT Culture
 * @dev Credit to Zimri Leijen
 * See https://ethereum.stackexchange.com/a/92235
 */
library BooleanPacking {
    function getBoolean(uint256 _packedBools, uint256 _columnNumber)
        internal
        pure
        returns (bool)
    {
        uint256 flag = (_packedBools >> _columnNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function setBoolean(
        uint256 _packedBools,
        uint256 _columnNumber,
        bool _value
    ) internal pure returns (uint256) {
        if (_value) {
            _packedBools = _packedBools | (uint256(1) << _columnNumber);
            return _packedBools;
        } else {
            _packedBools = _packedBools & ~(uint256(1) << _columnNumber);
            return _packedBools;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
 * @title MerkleRoot
 * @author @NiftyMike, NFT Culture
 * @dev Companion library to OpenZeppelin's MerkleProof.
 * Allows you to abstract away merkle functionality a bit further, you now just need to
 * worry about dealing with your merkle root.
 *
 * Using this library allows you to treat bytes32 member variables as Merkle Roots, with a
 * slightly easier to use api then the OZ library.
 */
library MerkleRoot {
    using MerkleProof for bytes32[];

    function check(
        bytes32 root,
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bool) {
        return proof.verify(root, leaf);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721ABurnable.
 */
interface IERC721ABurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}