// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iczNft.sol";
import "./interfaces/iczRoar.sol";
import "./interfaces/iczSpecialEditionTraits.sol";

contract czMain is Ownable, Pausable, ReentrancyGuard {

    constructor() {
        _pause();

        // define trait categories
        traitCategory[2] = 2;  // Headwear
        traitCategory[3] = 2;  // Headwear
        traitCategory[4] = 2;  // Headwear
        traitCategory[6] = 2;  // Headwear
        traitCategory[9] = 2;  // Headwear
        traitCategory[11] = 2; // Headwear
        traitCategory[12] = 2; // Headwear

        traitCategory[1] = 1;  // Mouth
        traitCategory[5] = 1;  // Mouth
        traitCategory[8] = 1;  // Mouth

        traitCategory[7] = 3;  // Neckwear
        traitCategory[10] = 3; // Neckwear
    }

    /** CONTRACTS */
    iczNft public nftContract;
    iczRoar public roarContract;
    iczSpecialEditionTraits public setContract;

    /** EVENTS */
    event ManyGenesisMinted(address indexed owner, uint16[] tokenIds);
    event ManyGenesisStaked(address indexed owner, uint16[] tokenIds);
    event ManyGenesisClaimed(address indexed owner, uint16[] tokenIds);
    event ManySpecialTraitsMinted(address indexed owner, uint16 traitId, uint16 amount);
    event GenesisFusedWithTrait(address indexed owner, uint256 tokenId, uint16 traitId);

    /** PUBLIC VARS */
    bool public TRAIT_SALE_STARTED;
    // traitId => traitCategory
    mapping(uint16 => uint16) public traitCategory;

    uint256 public MINT_PRICE_GENESIS = 0.09 ether;

    bool public PRE_SALE_STARTED;

    bool public PUBLIC_SALE_STARTED;
    uint16 public MAX_PUBLIC_SALE_MINTS = 3;

    bool public STAKING_STARTED;
    uint256 public DAILY_ROAR_RATE = 5 ether;
    uint256 public DAILY_TRAIT_ROAR_RATE = 5 ether;
    uint256 public MINIMUM_DAYS_TO_EXIT = 1 days;

    address public wallet1Address;
    address public wallet2Address;

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;
    mapping(address => uint8) private _preSaleAddresses;
    mapping(address => uint8) private _preSaleMints;
    mapping(address => uint8) private _publicSaleMints;
    mapping(address => uint8) private _specialTraitMints;
    
    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Main: Only admins can call this");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "Main: Only EOA");
        _;
    }

    modifier requireVariablesSet() {
        require(address(nftContract) != address(0), "Main: Nft contract not set");
        require(address(roarContract) != address(0), "Main: Roar contract not set");
        require(address(setContract) != address(0), "Main: Special Edition Traits contract not set");
        require(wallet1Address != address(0), "Main: Withdrawal address wallet1Address must be set");
        require(wallet2Address != address(0), "Main: Withdrawal address wallet2Address must be set");
        _;
    }

    /** PUBLIC FUNCTIONS */
    function mintSpecialEditionTrait(uint16 traitId, uint16 amount) external payable whenNotPaused nonReentrant onlyEOA {
        require(TRAIT_SALE_STARTED, "Main: Trait sale has not started");
        iczSpecialEditionTraits.Trait memory _trait = setContract.getTrait(traitId);
        require(_trait.traitId == traitId, "Main: Trait does not exist");
        require(msg.value >= amount * _trait.price, "Main: Invalid payment amount");
        require(_specialTraitMints[_msgSender()] + amount <= 3, "Main: You cannot mint more Traits");

        for (uint i = 0; i < amount; i++) {
            _specialTraitMints[_msgSender()]++;
            setContract.mint(traitId, _msgSender());
        }

        emit ManySpecialTraitsMinted(_msgSender(), traitId, amount);
    }

    function fuseTraitWithZilla(uint16 nftTokenId, uint16 setTokenId) external whenNotPaused onlyEOA { // nonReentrant removed due to call to claimManyGenesis()
        require(nftContract.ownerOf(nftTokenId) == _msgSender(), "Main: You are not the owner of this zilla");
        require(setContract.ownerOf(setTokenId) == _msgSender(), "Main: You are not the owner of this trait");

        iczSpecialEditionTraits.Token memory setToken = setContract.getToken(setTokenId);
        uint16 traitId = setToken.traitId;
        uint16 traitCategoryNew = traitCategory[traitId];

        uint16[] memory fusedTraits = nftContract.getSpecialTraits(nftTokenId);
        for (uint i = 0; i < fusedTraits.length; i++) {
            if (fusedTraits[i] == traitId) require(false, "Main: Cannot fuse the same trait twice");
            
            uint16 traitCategoryExisting = traitCategory[fusedTraits[i]];
            if (traitCategoryNew == traitCategoryExisting) require(false, "Main: Cannot fuse the same trait category twice");
        }

        // burn the trait nft
        setContract.burn(setTokenId);

        // claim ROAR to not inflate the earnings by fusing a trait - call this BEFORE fusing the trait with the NFT
        if (nftContract.isStaked(nftTokenId)) {
            uint16[] memory tokenIds = new uint16[](1);
            tokenIds[0] = uint16(nftTokenId);
            claimManyGenesis(tokenIds, false);
        }

        // add trait to zilla permanently
        nftContract.addToSpecialTraits(nftTokenId, traitId);

        emit GenesisFusedWithTrait(_msgSender(), nftTokenId, traitId);
    }

    function mint(uint256 amount) external payable whenNotPaused nonReentrant onlyEOA {
        require(PRE_SALE_STARTED || PUBLIC_SALE_STARTED, "Main: Genesis sale has not started yet");
        if (PRE_SALE_STARTED) {
            require(_preSaleAddresses[_msgSender()] > 0, "Main: You are not on the whitelist");
            require(_preSaleMints[_msgSender()] + amount <= _preSaleAddresses[_msgSender()], "Main: You cannot mint more Genesis during pre-sale");
        } else {
            require(_publicSaleMints[_msgSender()] + amount <= MAX_PUBLIC_SALE_MINTS, "Main: You cannot mint more Genesis");
        }
        require(msg.value >= amount * MINT_PRICE_GENESIS, "Main: Invalid payment amount");

        uint16[] memory tokenIds = new uint16[](amount);

        for (uint i = 0; i < amount; i++) {
            if (PRE_SALE_STARTED) {
                _preSaleMints[_msgSender()]++;
            } else {
                _publicSaleMints[_msgSender()]++;
            }

            nftContract.mint(_msgSender());
            tokenIds[i] = nftContract.totalMinted();
        }

        emit ManyGenesisMinted(_msgSender(), tokenIds);
    }

    function stakeManyGenesis(uint16[] memory tokenIds) external whenNotPaused nonReentrant onlyEOA {
        require(STAKING_STARTED, "Main: Staking did not yet start");

        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftContract.ownerOf(tokenId) == _msgSender(), "Main: You are not the owner of this zilla");
            require(!nftContract.isStaked(tokenId), "Main: One token is already staked");

            // now inform the staking contract that the staking period has started (lockType = 1)
            nftContract.lock(tokenId, 1);
        }

        emit ManyGenesisStaked(_msgSender(), tokenIds);
    }

    function claimManyGenesis(uint16[] memory tokenIds, bool unstake) public whenNotPaused nonReentrant onlyEOA {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftContract.ownerOf(tokenId) == _msgSender(), "Main: You are not the owner of this zilla");
            require(nftContract.isStaked(tokenId), "Main: Token is not staked");

            iczNft.Locked memory myStake = nftContract.getLock(tokenId);
            require(myStake.lockType == 1, "Main: One or more tokens are not staked but bridged");

            // pay out rewards
            uint256 stakingRewards = calculateGenesisStakingRewards(tokenId);
            roarContract.mint(_msgSender(), stakingRewards);

            // unstake if the owner wishes to
            if (unstake) {    
                require((block.timestamp - myStake.lockTimestamp) >= MINIMUM_DAYS_TO_EXIT, "Main: Must remain staked for at least 24h after staking/claiming");

                // now inform the staking contract that the staking period has started
                nftContract.unlock(tokenId);
            } else {
                // refresh stake (reentrancy already checked above)
                nftContract.refreshLock(tokenId);
            }
            
        }

        emit ManyGenesisClaimed(_msgSender(), tokenIds);
    }

    function calculateAllGenesisStakingRewards(uint256[] memory tokenIds) public view returns(uint256 rewards) {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            rewards += calculateGenesisStakingRewards(tokenIds[i]);
        }
    }

    function calculateGenesisStakingRewards(uint256 tokenId) public view returns(uint256 rewards) {
        require(nftContract.isStaked(tokenId), "Main: Token is not staked");
        
        iczNft.Locked memory myStake = nftContract.getLock(tokenId);
        rewards += (block.timestamp - myStake.lockTimestamp) * DAILY_ROAR_RATE / 1 days;

        // extra rewards for golden traits fused with zilla
        uint16[] memory specialTraits = nftContract.getSpecialTraits(tokenId);
        rewards += (block.timestamp - myStake.lockTimestamp) * specialTraits.length * DAILY_TRAIT_ROAR_RATE / 1 days;

        return rewards;
    }

    /** OWNER ONLY FUNCTIONS */
    function setContracts(address _nftContract, address _roarContract, address _setContract) external onlyOwner {
        nftContract = iczNft(_nftContract);
        roarContract = iczRoar(_roarContract);
        setContract = iczSpecialEditionTraits(_setContract);
    }

    function setPaused(bool _paused) external requireVariablesSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function mintForTeam(address receiver, uint256 amount) external whenNotPaused onlyOwner {
        for (uint i = 0; i < amount; i++) {
            nftContract.mint(receiver);
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;
        
        uint256 amountWallet1 = totalAmount * 47/100;
        uint256 amountWallet2 = totalAmount - amountWallet1;

        bool sent;
        (sent, ) = wallet1Address.call{value: amountWallet1}("");
        require(sent, "Main: Failed to send funds to wallet1Address");

        (sent, ) = wallet2Address.call{value: amountWallet2}("");
        require(sent, "Main: Failed to send funds to wallet2Address");
    }
    
    function addToPresale(address[] memory addresses, uint8 allowedToMint) external onlyOwner {
         for (uint i = 0; i < addresses.length; i++) {
            _preSaleAddresses[addresses[i]] = allowedToMint;
         }
    }

    function setWallet1Address(address addr) external onlyOwner {
        wallet1Address = addr;
    }

    function setWallet2Address(address addr) external onlyOwner {
        wallet2Address = addr;
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

    function setMintPriceGenesis(uint256 number) external onlyOwner {
        MINT_PRICE_GENESIS = number;
    }

    function setTraitSaleStarted(bool started) external onlyOwner {
        TRAIT_SALE_STARTED = started;
    }

    function setPreSaleStarted(bool started) external onlyOwner {
        PRE_SALE_STARTED = started;
        if (PRE_SALE_STARTED) PUBLIC_SALE_STARTED = false;
    }

    function setPublicSaleStarted(bool started) external onlyOwner {
        PUBLIC_SALE_STARTED = started;
        if (PUBLIC_SALE_STARTED) PRE_SALE_STARTED = false;
    }

    function setStakingStarted(bool started) external onlyOwner {
        STAKING_STARTED = started;
    }

    function setMaxPublicSaleMints(uint16 number) external onlyOwner {
        MAX_PUBLIC_SALE_MINTS = number;
    }
    
    function setDailyRoarRate(uint256 number) external onlyOwner {
        DAILY_ROAR_RATE = number;
    }

    function setDailyTraitRoarRate(uint256 number) external onlyOwner {
        DAILY_TRAIT_ROAR_RATE = number;
    }

    function setMinimumDaysToExit(uint256 number) external onlyOwner {
        MINIMUM_DAYS_TO_EXIT = number;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iczSpecialEditionTraits is IERC721Enumerable {

    // traits meta data
    struct Trait {
        string name;
        uint16 traitId;
        uint256 price; // in eth
        uint16 maxMint; // max mint for this trait
        uint16 minted; // how often this trait has been minted already
    }

    struct Token {
        uint16 tokenId;
        uint16 traitId;
    }

    function totalMinted() external view returns (uint16);
    function totalBurned() external view returns (uint16);

    function mint(uint16 traitId, address recipient) external; // onlyAdmin
    function burn(uint16 tokenId) external;
    
    function getToken(uint16 tokenId) external view returns (Token memory token);
    function getTrait(uint16 traitId) external view returns (Trait memory trait);
    function getWalletOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface iczRoar is IERC20 {
    function MAX_TOKENS() external returns (uint256);
    function tokensMinted() external returns (uint256);
    function tokensBurned() external returns (uint256);
    function canBeSold() external returns (bool);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iczNft is IERC721Enumerable {

    // store lock meta data
    struct Locked {
        uint256 tokenId;
        uint8 lockType; // staking = 1; bridging = 2
        uint256 lockTimestamp;
    }

    function MAX_TOKENS() external returns (uint256);
    function totalMinted() external returns (uint16);
    function totalLocked() external returns (uint16);
    function totalStaked() external returns (uint16);
    function totalBridged() external returns (uint16);

    function mint(address recipient) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin

    function lock(uint256 tokenId, uint8 lockType) external; // onlyAdmin
    function unlock(uint256 tokenId) external; // onlyAdmin
    function refreshLock(uint256 tokenId) external; // onlyAdmin
    function getLock(uint256 tokenId) external view returns (Locked memory);

    function isLocked(uint256 tokenId) external view returns(bool);
    function isStaked(uint256 tokenId) external view returns(bool);
    function isBridged(uint256 tokenId) external view returns(bool);

    function getAllStakedOrLockedTokens(address owner, uint8 lockType) external returns (uint256[] memory);
    function getWalletOfOwner(address owner) external view returns (uint256[] memory);
    function addToSpecialTraits(uint256 tokenId, uint16 traitId) external;
    function getSpecialTraits(uint256 tokenId) external view returns (uint16[] memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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