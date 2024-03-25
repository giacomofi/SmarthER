// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ITokenVesting.sol";

/// @title JPEGAirdropClaim
/// @notice {JPEG} airdrop claim contract, whitelisted users can claim aJPEG, which is a vested airdrop token
/// which can be burnt to claim JPEG linearly. The vesting schedule is set by the owner
/// @dev This contract uses a merkle tree based whitelist.
contract JPEGAirdropClaim is Ownable {
    /// @dev see {setAirdropSchedule}
    struct AirdropSchedule {
        uint256 startTimestamp;
        uint256 cliffDuration;
        uint256 duration;
        uint256 airdropAmount;
    }

    /// @notice Root of the merkle tree used for the airdrop whitelist.
    bytes32 public immutable merkleRoot;

    ITokenVesting public immutable aJPEG;

    /// @notice The airdrop's schedule.
    AirdropSchedule public airdropSchedule;

    mapping(address => bool) public hasClaimed;

    constructor(ITokenVesting vestingToken, bytes32 root) {
        merkleRoot = root;
        aJPEG = vestingToken;
        
        IERC20(vestingToken.token()).approve(address(vestingToken), 2 ** 256 - 1);
    }

    /// @notice Allows the owner to set the airdrop's schedule. Can only be called once. Can only be called by the owner.
    /// @param startTimestamp The vesting's start timestamp. Has to be greater 0. Can be less than `block.timestamp`.
    /// @param cliffDuration The vesting's cliff duration. Can be 0.
    /// @param duration The vesting's duration. Has to be greater than `cliffDuration`.
    /// @param airdropAmount The amount of tokens to be airdropped, per address. Has to be greater than 0.
    function setAidropSchedule(
        uint256 startTimestamp,
        uint256 cliffDuration,
        uint256 duration,
        uint256 airdropAmount
    ) external onlyOwner {
        require(airdropSchedule.startTimestamp == 0, "SCHEDULE_ALREADY_SET");
        require(startTimestamp > 0, "INVALID_START_TIMESTAMP");
        require(duration > cliffDuration, "INVALID_END_TIMESTAMP");
        require(airdropAmount > 0, "INVALID_AIRDROP_AMOUNT");

        airdropSchedule.startTimestamp = startTimestamp;
        airdropSchedule.cliffDuration = cliffDuration;
        airdropSchedule.duration = duration;
        airdropSchedule.airdropAmount = airdropAmount;
    }

    /// @notice Allows whitelisted users to claim their airdrop.
    /// @param merkleProof The merkle proof to verify.
    function claimAirdrop(bytes32[] calldata merkleProof) external {
        require(airdropSchedule.startTimestamp > 0, "SCHEDULE_NOT_SET");

        require(!hasClaimed[msg.sender], "ALREADY_CLAIMED");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "INVALID_PROOF"
        );

        aJPEG.vestTokens(
            msg.sender,
            airdropSchedule.airdropAmount,
            airdropSchedule.startTimestamp,
            airdropSchedule.cliffDuration,
            airdropSchedule.duration
        );

        hasClaimed[msg.sender] = true;
    }

    /// @notice Withdraws tokens from this contract. Can only be called by the owner.
    /// @param token The token to withdraw.
    /// @param amount The amount of `token` to withdraw
    function rescueToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ITokenVesting  {
    /// @notice Allows members of `VESTING_CONTROLLER_ROLE` to vest tokens
    /// @dev Emits a {NewBeneficiary} event
    /// @param beneficiary The beneficiary of the tokens
    /// @param totalAllocation The total amount of tokens allocated to `beneficiary`
    /// @param start The start timestamp
    /// @param cliffDuration The duration of the cliff period (can be 0)
    /// @param duration The duration of the vesting period (starting from `start`)
    function vestTokens(
        address beneficiary,
        uint256 totalAllocation,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) external;

    function token() external view returns (address);
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