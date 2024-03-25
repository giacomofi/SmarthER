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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBalanceController.sol";

/**
 * @dev An `Ownable` contract that can receive coins, and in which the owner has
 * the ability to withdraw coins and tokens arbitrarily.
 */
contract BalanceController is IBalanceController, Ownable {
    receive() external payable override {}

    function withdrawERC20(address token, address account, uint256 amount) external override onlyOwner {
        require(IERC20(token).transfer(account, amount), 'BalanceController: withdrawERC20 failed.');
    }

    function withdraw(address account, uint256 amount) external override onlyOwner {
        (bool sent,) = account.call{value : amount}('');
        require(sent, 'BalanceController: withdraw failed.');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IMerkleMinter.sol";
import "./BalanceController.sol";

/**
 * @dev Allows a whitelist of accounts to mint a token for a particular price.
 * The whitelist is formed into a Merkle tree and claims require a valid
 * inclusion proof in order to mint the related token.
 */
contract MerkleMinter is IMerkleMinter, BalanceController {
    /**
     * @dev The address of the token claimants will mint.
     **/
    address public immutable override mintableToken;

    /**
     * @dev The address of the token claimants will pay with.
     **/
    address public immutable override paymentToken;

    /**
     * @dev The number of claims in the tree.
    **/
    uint32 public immutable numClaims;

    /**
     * @dev The root of the tree of claims.
    **/
    bytes32 public immutable override merkleRoot;

    /**
     * @dev A packed array of booleans that tracks which leaves of the tree are
     * claimed.
     */
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address MintingToken_, address PaymentToken_, uint32 numClaims_, bytes32 merkleRoot_) {
        mintableToken = MintingToken_;
        paymentToken = PaymentToken_;
        numClaims = numClaims_;
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Returns whether the leaf with the given index has been claimed.
    **/
    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev Returns an array of booleans indicated if each index is claimed.
     */
    function claimedList() public view override returns (bool[] memory) {
        bool[] memory list = new bool[](numClaims);
        for (uint i = 0; i < numClaims; i++) {
            list[i] = isClaimed(i);
        }
        return list;
    }

    /**
     * @dev Marks the leaf with the given index as claimed in the packed array.
    **/
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
    /**
     * @dev Validates that the given information is a claim in the tree and then
     * issues the mint.
    **/
    function claim(uint256 index, address account, uint256 tokenId, uint256 price, bytes32[] calldata merkleProof) external override {
        // Check that this index is unclaimed
        require(!isClaimed(index), 'MerkleMinter: Token already claimed.');

        // Check that the merkle proof is valid
        require(MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(index, account, tokenId, price))),
            'MerkleMinter: Invalid proof.');

        // Perform the mint
        _mintClaim(index, account, tokenId, price);
    }

    /**
     * @dev Performs the payment transfer and the token mint. It marks the leaf
     * as claimed causing all future calls to `claim` for the same leaf to fail.
    **/
    function _mintClaim(uint256 index, address account, uint256 tokenId, uint256 price) internal {
        // Transfer the funds
        require(IERC20(paymentToken).transferFrom(account, address(this), price), 'MerkleMinter: Token transfer failed.');

        // Mark index as claimed
        _setClaimed(index);

        // Mint the token
        IERC721(mintableToken).mint(account, tokenId);

        // Send an event for logging
        emit Claimed(index, account, tokenId, price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

/**
 * @dev Allows users (e.g. an owner) to withdraw funds.
 */
interface IBalanceController {
    receive() external payable;

    /**
     * @dev Allows the owner to move any ERC20 tokens owned by the
     * contract.
     */
    function withdrawERC20(address token, address account, uint256 amount) external;

    /**
     * @dev Allows the owner to move any ETH held by the contract.
     */
    function withdraw(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC721 {
    function mint(address to, uint256 id) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

/**
 * Allows accounts to mint a token if they exist in a merkle root.
 */
interface IMerkleMinter {
    /**
     * Returns the address of the token minted by this contract.
     */
    function mintableToken() external view returns (address);

    /**
     * Returns the address of the payment token required by this contract.
     */
    function paymentToken() external view returns (address);

    /**
     * Returns the merkle root of the merkle tree containing account balances
     * available to claim.
     */
    function merkleRoot() external view returns (bytes32);

    /**
     * Returns true if the index has been marked claimed.
     */
    function isClaimed(uint256 index) external view returns (bool);

    /**
     * @dev Returns an array of booleans indicated if each index is claimed.
     */
    function claimedList() external view returns (bool[] memory);

    /**
     * @dev Claim the given token to the given address. Reverts if the inputs
     * are invalid.
     */
    function claim(uint256 index, address account, uint256 tokenID, uint256 price, bytes32[] calldata merkleProof) external;

    /**
     * @dev This event is triggered whenever a call to #claim succeeds.
     */
    event Claimed(uint256 index, address account, uint256 tokenId, uint256 price);
}