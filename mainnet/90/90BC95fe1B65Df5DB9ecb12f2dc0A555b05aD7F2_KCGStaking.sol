// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KCGStaking is Ownable, ReentrancyGuard {
    uint256 public constant DAY = 24 * 60 * 60;
    uint256 public constant FOURTY_FIVE_DAYS = 45 * DAY;
    uint256 public constant NINETY_DAYS = 90 * DAY;
    uint256 public constant ONE_HUNDREDS_EIGHTY_DAYS = 180 * DAY;

    address public KCGAddress = 0xA302F0d51A365B18e86c291056dC265a73F19419;
    bool public emergencyUnstakePaused = true;

    struct stakeRecord {
        address tokenOwner;
        uint256 tokenId;
        uint256 endingTimestamp;
    }

    mapping(uint256 => stakeRecord) public stakingRecords;

    mapping(address => uint256) public numOfTokenStaked;

    event Staked(address owner, uint256 amount, uint256 timeframe);

    event Unstaked(address owner, uint256 amount);

    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {}

    // MODIFIER
    modifier checkArgsLength(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    ) {
        require(
            tokenIds.length == timeframe.length,
            "Token IDs and timeframes must have the same length."
        );
        _;
    }

    modifier checkStakingTimeframe(uint256[] calldata timeframe) {
        for (uint256 i = 0; i < timeframe.length; i++) {
            uint256 period = timeframe[i];
            require(
                period == FOURTY_FIVE_DAYS ||
                    period == NINETY_DAYS ||
                    period == ONE_HUNDREDS_EIGHTY_DAYS,
                "Invalid staking timeframes."
            );
        }
        _;
    }

    // STAKING
    function batchStake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            IERC721Enumerable(KCGAddress).ownerOf(_tokenId) == msg.sender,
            "You must own the NFT."
        );
        uint256 endingTimestamp = block.timestamp + _timeframe;

        stakingRecords[_tokenId] = stakeRecord(
            _user,
            _tokenId,
            endingTimestamp
        );
        numOfTokenStaked[_user] = numOfTokenStaked[_user] + 1;
        IERC721Enumerable(KCGAddress).safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId, _timeframe);
    }

    // RESTAKE
    function batchRestake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _restake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _restake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        uint256 endingTimestamp = block.timestamp + _timeframe;
        stakingRecords[_tokenId].endingTimestamp = endingTimestamp;

        emit Staked(_user, _tokenId, _timeframe);
    }

    // UNSTAKE
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        delete stakingRecords[_tokenId];
        numOfTokenStaked[_user]--;
        IERC721Enumerable(KCGAddress).safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit Unstaked(_user, _tokenId);
    }

    function getStakingRecords(address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](numOfTokenStaked[user]);
        uint256[] memory expiries = new uint256[](numOfTokenStaked[user]);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < IERC721Enumerable(KCGAddress).totalSupply();
            i++
        ) {
            if (stakingRecords[i].tokenOwner == user) {
                tokenIds[counter] = stakingRecords[i].tokenId;
                expiries[counter] = stakingRecords[i].endingTimestamp;
                counter++;
            }
        }
        return (tokenIds, expiries);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // MIGRATION ONLY.
    function setKCGNFTContract(address operator) public onlyOwner {
        KCGAddress = operator;
    }

    // EMERGENCY ONLY.
    function setEmergencyUnstakePaused(bool paused) public onlyOwner {
        emergencyUnstakePaused = paused;
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        require(
            stakingRecords[tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );
        delete stakingRecords[tokenId];
        numOfTokenStaked[msg.sender]--;
        IERC721Enumerable(KCGAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit EmergencyUnstake(msg.sender, tokenId);
    }

    function emergencyUnstakeByOwner(uint256[] calldata tokenIds)
        external
        onlyOwner
        nonReentrant
    {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address user = stakingRecords[tokenId].tokenOwner;
            require(user != address(0x0), "Need owner exists.");
            delete stakingRecords[tokenId];
            numOfTokenStaked[user]--;
            IERC721Enumerable(KCGAddress).safeTransferFrom(
                address(this),
                user,
                tokenId
            );
            emit EmergencyUnstake(user, tokenId);
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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