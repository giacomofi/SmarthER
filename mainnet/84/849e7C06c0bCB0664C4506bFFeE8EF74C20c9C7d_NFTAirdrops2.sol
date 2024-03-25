// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleProof.sol";

contract ERC20Airdrops is MerkleProof {
    using SafeERC20 for IERC20;

    mapping(address => mapping(bytes32 => uint256)) public deadlineOf;
    mapping(address => mapping(bytes32 => address)) public walletOf;
    mapping(address => mapping(bytes32 => mapping(bytes32 => bool))) internal _hasClaimed;

    event AddMerkleRoot(address indexed token, bytes32 indexed merkleRoot, address wallet, uint256 deadline);
    event Claim(
        address indexed token,
        bytes32 indexed merkleRoot,
        address wallet,
        address indexed account,
        uint256 amount
    );

    function addMerkleRoot(
        address token,
        bytes32 merkleRoot,
        uint256 deadline
    ) external {
        address wallet = walletOf[token][merkleRoot];
        require(wallet == address(0), "LEVX: DUPLICATE_ROOT");
        walletOf[token][merkleRoot] = msg.sender;
        deadlineOf[token][merkleRoot] = deadline;

        emit AddMerkleRoot(token, merkleRoot, msg.sender, deadline);
    }

    function claim(
        address token,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external {
        address wallet = walletOf[token][merkleRoot];
        require(wallet != address(0), "LEVX: INVALID_ROOT");
        require(block.timestamp < deadlineOf[token][merkleRoot], "LEVX: EXPIRED");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(!_hasClaimed[token][merkleRoot][leaf], "LEVX: FORBIDDEN");
        require(verify(merkleRoot, leaf, merkleProof), "LEVX: INVALID_PROOF");

        _hasClaimed[token][merkleRoot][leaf] = true;
        IERC20(token).safeTransferFrom(wallet, msg.sender, amount);

        emit Claim(token, merkleRoot, wallet, msg.sender, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

contract MerkleProof {
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleProof.sol";

contract LevxAirdrop is Ownable, MerkleProof {
    using SafeERC20 for IERC20;

    address public immutable levx;
    mapping(bytes32 => bool) public isValidMerkleRoot;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _hasClaimed;

    event AddMerkleRoot(bytes32 indexed merkleRoot);
    event Claim(bytes32 indexed merkleRoot, address indexed account, uint256 amount);

    constructor(address _owner, address _levx) {
        levx = _levx;
        _transferOwnership(_owner);
    }

    function addMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(!isValidMerkleRoot[merkleRoot], "SHOYU: DUPLICATE_ROOT");
        isValidMerkleRoot[merkleRoot] = true;

        emit AddMerkleRoot(merkleRoot);
    }

    function claim(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external {
        require(isValidMerkleRoot[merkleRoot], "SHOYU: INVALID_ROOT");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(!_hasClaimed[merkleRoot][leaf], "SHOYU: FORBIDDEN");
        require(verify(merkleRoot, leaf, merkleProof), "SHOYU: INVALID_PROOF");

        _hasClaimed[merkleRoot][leaf] = true;
        IERC20(levx).safeTransferFrom(owner(), msg.sender, amount);

        emit Claim(merkleRoot, msg.sender, amount);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@shoyunft/contracts/contracts/interfaces/INFT721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTAirdropsAndSales is Ownable {
    using SafeERC20 for IERC20;

    address public immutable nftContract;
    address public immutable levx;
    address public immutable wallet;
    mapping(bytes32 => Airdrop) public airdrops;
    mapping(address => bool) public isMinter;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _minted;

    struct Airdrop {
        address signer;
        uint64 deadline;
        uint256 nextTokenId;
        uint256 maxTokenId;
    }

    event SetMinter(address account, bool indexed isMinter);
    event Add(bytes32 indexed slug, address signer, uint64 deadline, uint256 fromTokenId, uint256 maxTokenId);
    event Claim(bytes32 indexed slug, bytes32 indexed id, address indexed to, uint256 tokenId, uint256 price);

    constructor(
        address _nftContract,
        address _levx,
        address _wallet
    ) {
        nftContract = _nftContract;
        levx = _levx;
        wallet = _wallet;
    }

    function setMinter(address account, bool _isMinter) external onlyOwner {
        isMinter[account] = _isMinter;

        emit SetMinter(account, _isMinter);
    }

    function transferOwnershipOfNFTContract(address newOwner) external onlyOwner {
        INFT721(nftContract).transferOwnership(newOwner);
    }

    function setRoyaltyFeeRecipient(address _royaltyFeeRecipient) external onlyOwner {
        INFT721(nftContract).setRoyaltyFeeRecipient(_royaltyFeeRecipient);
    }

    function setRoyaltyFee(uint8 _royaltyFee) external onlyOwner {
        INFT721(nftContract).setRoyaltyFee(_royaltyFee);
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        INFT721(nftContract).setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        INFT721(nftContract).setBaseURI(baseURI);
    }

    function parkTokenIds(uint256 toTokenId) external onlyOwner {
        INFT721(nftContract).parkTokenIds(toTokenId);
    }

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        require(msg.sender == owner() || isMinter[msg.sender], "LEVX: FORBIDDEN");

        INFT721(nftContract).mint(to, tokenId, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external {
        require(msg.sender == owner() || isMinter[msg.sender], "LEVX: FORBIDDEN");

        INFT721(nftContract).mintBatch(to, tokenIds, data);
    }

    function add(
        bytes32 slug,
        address signer,
        uint64 deadline,
        uint256 fromTokenId,
        uint256 maxTokenId
    ) external onlyOwner {
        Airdrop storage airdrop = airdrops[slug];
        require(airdrop.signer == address(0), "LEVX: ADDED");

        airdrop.signer = signer;
        airdrop.deadline = deadline;
        airdrop.nextTokenId = fromTokenId;
        airdrop.maxTokenId = maxTokenId;

        emit Add(slug, signer, deadline, fromTokenId, maxTokenId);
    }

    function claim(
        bytes32 slug,
        bytes32 id,
        uint256 tokenId,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to,
        bytes calldata data
    ) external {
        Airdrop storage airdrop = airdrops[slug];
        {
            (address signer, uint64 deadline) = (airdrop.signer, airdrop.deadline);

            require(signer != address(0), "LEVX: INVALID_SLUG");
            require(deadline == 0 || uint64(block.timestamp) < deadline, "LEVX: EXPIRED");
            require(!_minted[slug][id], "LEVX: MINTED");

            bytes32 message = keccak256(abi.encodePacked(slug, id, tokenId, price));
            require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }

        {
            (uint256 nextTokenId, uint256 maxTokenId) = (airdrop.nextTokenId, airdrop.maxTokenId);

            if (tokenId == 0) {
                tokenId = nextTokenId;
                while (tokenId < maxTokenId) {
                    if (INFT721(nftContract).ownerOf(tokenId) == address(0)) {
                        break;
                    }
                    tokenId++;
                }
                require(tokenId < maxTokenId, "LEVX: INVALID_TOKEN_ID");
                airdrop.nextTokenId = tokenId + 1;
            } else {
                require(tokenId >= nextTokenId && tokenId < maxTokenId, "LEVX: INVALID_TOKEN_ID");
            }
        }

        _minted[slug][id] = true;

        emit Claim(slug, id, to, tokenId, price);
        if (price > 0) IERC20(levx).safeTransferFrom(msg.sender, wallet, price);
        INFT721(nftContract).mint(to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

pragma solidity >=0.5.0;

import "./IBaseNFT721.sol";
import "./IBaseExchange.sol";

interface INFT721 is IBaseNFT721, IBaseExchange {
    event SetRoyaltyFeeRecipient(address recipient);
    event SetRoyaltyFee(uint8 fee);

    function initialize(
        address _owner,
        string calldata _name,
        string calldata _symbol,
        uint256[] calldata tokenIds,
        address royaltyFeeRecipient,
        uint8 royaltyFee
    ) external;

    function initialize(
        address _owner,
        string calldata _name,
        string calldata _symbol,
        uint256 toTokenId,
        address royaltyFeeRecipient,
        uint8 royaltyFee
    ) external;

    function DOMAIN_SEPARATOR() external view override(IBaseNFT721, IBaseExchange) returns (bytes32);

    function factory() external view override(IBaseNFT721, IBaseExchange) returns (address);

    function setRoyaltyFeeRecipient(address _royaltyFeeRecipient) external;

    function setRoyaltyFee(uint8 _royaltyFee) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./IOwnable.sol";

interface IBaseNFT721 is IERC721, IERC721Metadata, IOwnable {
    event SetTokenURI(uint256 indexed tokenId, string uri);
    event SetBaseURI(string uri);
    event ParkTokenIds(uint256 toTokenId);
    event Burn(uint256 indexed tokenId, uint256 indexed label, bytes32 data);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function PERMIT_ALL_TYPEHASH() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function factory() external view returns (address);

    function nonces(uint256 tokenId) external view returns (uint256);

    function noncesForAll(address account) external view returns (uint256);

    function parked(uint256 tokenId) external view returns (bool);

    function initialize(
        string calldata name,
        string calldata symbol,
        address _owner
    ) external;

    function setTokenURI(uint256 id, string memory uri) external;

    function setBaseURI(string memory uri) external;

    function parkTokenIds(uint256 toTokenId) external;

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function burn(
        uint256 tokenId,
        uint256 label,
        bytes32 data
    ) external;

    function burnBatch(uint256[] calldata tokenIds) external;

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../libraries/Orders.sol";

interface IBaseExchange {
    event Cancel(bytes32 indexed hash);
    event Claim(
        bytes32 indexed hash,
        address bidder,
        uint256 amount,
        uint256 price,
        address recipient,
        address referrer
    );
    event Bid(bytes32 indexed hash, address bidder, uint256 amount, uint256 price, address recipient, address referrer);
    event UpdateApprovedBidHash(
        address indexed proxy,
        bytes32 indexed askHash,
        address indexed bidder,
        bytes32 bidHash
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function factory() external view returns (address);

    function canTrade(address token) external view returns (bool);

    function bestBid(bytes32 hash)
        external
        view
        returns (
            address bidder,
            uint256 amount,
            uint256 price,
            address recipient,
            address referrer,
            uint256 blockNumber
        );

    function isCancelledOrClaimed(bytes32 hash) external view returns (bool);

    function amountFilled(bytes32 hash) external view returns (uint256);

    function approvedBidHash(
        address proxy,
        bytes32 askHash,
        address bidder
    ) external view returns (bytes32 bidHash);

    function cancel(Orders.Ask memory order) external;

    function updateApprovedBidHash(
        bytes32 askHash,
        address bidder,
        bytes32 bidHash
    ) external;

    function bid(Orders.Ask memory askOrder, Orders.Bid memory bidOrder) external returns (bool executed);

    function bid(
        Orders.Ask memory askOrder,
        uint256 bidAmount,
        uint256 bidPrice,
        address bidRecipient,
        address bidReferrer
    ) external returns (bool executed);

    function claim(Orders.Ask memory order) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
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

pragma solidity =0.8.3;

library Orders {
    // keccak256("Ask(address signer,address proxy,address token,uint256 tokenId,uint256 amount,address strategy,address currency,address recipient,uint256 deadline,bytes params)")
    bytes32 internal constant ASK_TYPEHASH = 0x5fbc9a24e1532fa5245d1ec2dc5592849ae97ac5475f361b1a1f7a6e2ac9b2fd;
    // keccak256("Bid(bytes32 askHash,address signer,uint256 amount,uint256 price,address recipient,address referrer)")
    bytes32 internal constant BID_TYPEHASH = 0xb98e1dc48988064e6dfb813618609d7da80a8841e5f277039788ac4b50d497b2;

    struct Ask {
        address signer;
        address proxy;
        address token;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        address currency;
        address recipient;
        uint256 deadline;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Bid {
        bytes32 askHash;
        address signer;
        uint256 amount;
        uint256 price;
        address recipient;
        address referrer;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function hash(Ask memory ask) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASK_TYPEHASH,
                    ask.signer,
                    ask.proxy,
                    ask.token,
                    ask.tokenId,
                    ask.amount,
                    ask.strategy,
                    ask.currency,
                    ask.recipient,
                    ask.deadline,
                    keccak256(ask.params)
                )
            );
    }

    function hash(Bid memory bid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(BID_TYPEHASH, bid.askHash, bid.signer, bid.amount, bid.price, bid.recipient, bid.referrer)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LevxStreaming is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 constant STREAMING_PERIOD = 180 days;

    struct Stream {
        address recipient;
        uint64 startedAt;
        uint256 amount;
        uint256 claimed;
    }

    address public immutable levx;
    address public immutable signer;
    address public immutable wallet;
    uint64 public immutable deadline;
    mapping(bytes32 => Stream[]) public streams;

    event Start(bytes32 indexed id, uint256 nonce, uint256 amount, address indexed recipient);
    event Claim(bytes32 indexed id, uint256 nonce, uint256 amount, address indexed recipient);

    constructor(
        address _levx,
        address _signer,
        address _wallet,
        uint64 _deadline
    ) {
        levx = _levx;
        signer = _signer;
        wallet = _wallet;
        deadline = _deadline;
    }

    function start(
        bytes32 id,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "LEVX: INVALID_AMOUNT");

        uint64 _now = uint64(block.timestamp);
        require(_now < deadline, "LEVX: EXPIRED");

        uint256 nonce = streams[id].length;
        bytes32 message = keccak256(abi.encodePacked(id, nonce, amount));
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");

        Stream storage stream = streams[id].push();
        stream.recipient = msg.sender;
        stream.startedAt = _now;
        stream.amount = amount;

        emit Start(id, nonce, amount, msg.sender);

        IERC20(levx).safeTransferFrom(wallet, address(this), amount);
    }

    function claim(
        bytes32 id,
        uint256 nonce,
        address to,
        bytes calldata callData
    ) external {
        Stream storage stream = streams[id][nonce];
        require(stream.recipient == msg.sender, "LEVX: FORBIDDEN");

        uint256 amount = _amountReleased(stream);
        uint256 pending = amount - stream.claimed;
        stream.claimed = amount;

        if (to == address(0)) {
            emit Claim(id, nonce, pending, msg.sender);

            IERC20(levx).safeTransfer(msg.sender, pending);
        } else {
            emit Claim(id, nonce, pending, to);

            IERC20(levx).safeTransfer(to, pending);
            to.functionCall(callData);
        }
    }

    function pendingAmount(bytes32 id, uint256 index) external view returns (uint256) {
        Stream storage stream = streams[id][index];
        return _amountReleased(stream) - stream.claimed;
    }

    function _amountReleased(Stream storage stream) internal view returns (uint256) {
        uint256 duration = block.timestamp - stream.startedAt;
        if (duration > STREAMING_PERIOD) duration = STREAMING_PERIOD;
        return (stream.amount * duration) / STREAMING_PERIOD;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./LevxStreaming.sol";

contract SecondLevxStreaming is LevxStreaming {
    constructor(
        address _levx,
        address _signer,
        address _wallet,
        uint64 _deadline
    ) LevxStreaming(_levx, _signer, _wallet, _deadline) {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LevxPayout is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public immutable levx;

    Payout[] public payouts;

    struct Payout {
        address wallet;
        address recipient;
        uint32 startedAt;
        uint32 duration;
        uint32 stoppedAt;
        uint256 amount;
        uint256 claimed;
    }

    event Start(uint256 indexed id, address wallet, address indexed recipient, uint32 duration, uint256 amount);
    event Stop(uint256 indexed id, uint256 pendingAmount);
    event Claim(uint256 indexed id, uint256 amount, address indexed recipient);

    constructor(address _levx) {
        levx = _levx;
    }

    function start(
        address wallet,
        address recipient,
        uint32 duration,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "LEVX: INVALID_AMOUNT");

        uint256 id = payouts.length;
        Payout storage payout = payouts.push();
        payout.wallet = wallet;
        payout.recipient = recipient;
        payout.startedAt = uint32(block.timestamp);
        payout.duration = duration;
        payout.amount = amount;

        emit Start(id, wallet, recipient, duration, amount);

        IERC20(levx).safeTransferFrom(wallet, address(this), amount);
    }

    function stop(uint256 id) external onlyOwner {
        Payout storage payout = payouts[id];
        require(payout.stoppedAt == 0, "LEVX: STOPPED");

        uint256 released = _amountReleased(payout);
        uint256 remaining = payout.amount - released;
        require(remaining > 0, "LEVX: FINISHED");

        payout.claimed = released;
        payout.stoppedAt = uint32(block.timestamp);

        uint256 pending = released - payout.claimed;
        emit Stop(id, pending);
        IERC20(levx).safeTransfer(payout.wallet, remaining);
        if (pending > 0) {
            IERC20(levx).safeTransfer(payout.recipient, pending);
        }
    }

    function claim(
        uint256 id,
        address to,
        bytes calldata callData
    ) external {
        Payout storage payout = payouts[id];
        require(payout.recipient == msg.sender, "LEVX: FORBIDDEN");

        uint256 released = _amountReleased(payout);
        uint256 pending = released - payout.claimed;
        payout.claimed = released;

        if (to == address(0)) {
            emit Claim(id, pending, msg.sender);

            IERC20(levx).safeTransfer(msg.sender, pending);
        } else {
            emit Claim(id, pending, to);

            IERC20(levx).safeTransfer(to, pending);
            to.functionCall(callData);
        }
    }

    function pendingAmount(uint256 id) external view returns (uint256) {
        Payout storage payout = payouts[id];
        return _amountReleased(payout) - payout.claimed;
    }

    function _amountReleased(Payout storage stream) internal view returns (uint256) {
        uint256 duration = block.timestamp - stream.startedAt;
        uint256 _total = uint256(stream.duration);
        if (duration >= _total) return stream.amount;
        return (stream.amount * duration) / _total;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@shoyunft/contracts/contracts/interfaces/INFT721.sol";

contract NFTAirdrops is Ownable {
    address public immutable nftContract;
    mapping(bytes32 => Airdrop) public airdrops;
    mapping(address => bool) public isMinter;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _minted;
    uint256 internal _tokenId;

    struct Airdrop {
        address signer;
        uint32 deadline;
        uint32 max;
        uint32 minted;
    }

    event SetMinter(address account, bool indexed isMinter);
    event Add(bytes32 indexed slug, address signer, uint32 deadline, uint32 max);
    event Claim(bytes32 indexed slug, bytes32 indexed id, address indexed to, uint256 tokenId);

    constructor(address _nftContract, uint256 fromTokenId) {
        nftContract = _nftContract;
        _tokenId = fromTokenId;
    }

    function setMinter(address account, bool _isMinter) external onlyOwner {
        isMinter[account] = _isMinter;

        emit SetMinter(account, _isMinter);
    }

    function transferOwnershipOfNFTContract(address newOwner) external onlyOwner {
        INFT721(nftContract).transferOwnership(newOwner);
    }

    function setRoyaltyFeeRecipient(address _royaltyFeeRecipient) external onlyOwner {
        INFT721(nftContract).setRoyaltyFeeRecipient(_royaltyFeeRecipient);
    }

    function setRoyaltyFee(uint8 _royaltyFee) external onlyOwner {
        INFT721(nftContract).setRoyaltyFee(_royaltyFee);
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        INFT721(nftContract).setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        INFT721(nftContract).setBaseURI(baseURI);
    }

    function parkTokenIds(uint256 toTokenId) external onlyOwner {
        INFT721(nftContract).parkTokenIds(toTokenId);
    }

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        require(msg.sender == owner() || isMinter[msg.sender], "LEVX: FORBIDDEN");

        INFT721(nftContract).mint(to, tokenId, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external {
        require(msg.sender == owner() || isMinter[msg.sender], "LEVX: FORBIDDEN");

        INFT721(nftContract).mintBatch(to, tokenIds, data);
    }

    function add(
        bytes32 slug,
        address signer,
        uint32 deadline,
        uint32 max
    ) external onlyOwner {
        Airdrop storage airdrop = airdrops[slug];
        require(airdrop.signer == address(0), "LEVX: ADDED");

        airdrop.signer = signer;
        airdrop.deadline = deadline;
        airdrop.max = max;

        emit Add(slug, signer, deadline, max);
    }

    function claim(
        bytes32 slug,
        bytes32 id,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to,
        bytes calldata data
    ) external {
        Airdrop storage airdrop = airdrops[slug];
        (address signer, uint32 deadline, uint32 max, uint32 minted) = (
            airdrop.signer,
            airdrop.deadline,
            airdrop.max,
            airdrop.minted
        );

        require(signer != address(0), "LEVX: INVALID_SLUG");
        require(deadline == 0 || uint32(block.timestamp) < deadline, "LEVX: EXPIRED");
        require(max == 0 || minted < max, "LEVX: FINISHED");
        require(!_minted[slug][id], "LEVX: MINTED");

        {
            bytes32 message = keccak256(abi.encodePacked(slug, id));
            require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }

        airdrop.minted = minted + 1;
        _minted[slug][id] = true;

        uint256 tokenId = _tokenId++;
        emit Claim(slug, id, to, tokenId);
        INFT721(nftContract).mint(to, tokenId, data);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./NFTAirdrops.sol";

contract NFTAirdrops2 is NFTAirdrops {
    constructor(address _nftContract, uint256 fromTokenId) NFTAirdrops(_nftContract, fromTokenId) {
        // Empty
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Router01.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import "./uniswapv2/libraries/UniswapV2Library.sol";
import "./MerkleProof.sol";

contract ETHAirdrop is Ownable, MerkleProof {
    using SafeERC20 for IERC20;

    address public immutable levx;
    address public immutable weth;
    address public immutable router;
    mapping(bytes32 => bool) public isValidMerkleRoot;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _hasClaimed;

    event Deposit(uint256 amount, address from);
    event Withdraw(uint256 amount, address to);
    event AddMerkleRoot(bytes32 indexed merkleRoot);
    event Claim(bytes32 indexed merkleRoot, address indexed account, uint256 amount, address to);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "LEVX: EXPIRED");
        _;
    }

    constructor(
        address _owner,
        address _levx,
        address _weth,
        address _router
    ) {
        levx = _levx;
        weth = _weth;
        router = _router;
        _transferOwnership(_owner);
    }

    receive() external payable {
        emit Deposit(msg.value, msg.sender);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);

        emit Withdraw(amount, msg.sender);
    }

    function addMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(!isValidMerkleRoot[merkleRoot], "SHOYU: DUPLICATE_ROOT");
        isValidMerkleRoot[merkleRoot] = true;

        emit AddMerkleRoot(merkleRoot);
    }

    function claim(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount,
        address to
    ) public {
        require(isValidMerkleRoot[merkleRoot], "SHOYU: INVALID_ROOT");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(!_hasClaimed[merkleRoot][leaf], "SHOYU: FORBIDDEN");
        require(verify(merkleRoot, leaf, merkleProof), "SHOYU: INVALID_PROOF");

        _hasClaimed[merkleRoot][leaf] = true;
        if (to != address(this)) {
            payable(to).transfer(amount);
        }

        emit Claim(merkleRoot, msg.sender, amount, to);
    }

    function batchClaim(
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata amounts,
        address to
    ) external {
        for (uint256 i; i < merkleRoots.length; i++) {
            claim(merkleRoots[i], merkleProofs[i], amounts[i], to);
        }
    }

    function claimAndSwapToLevx(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountOut) {
        claim(merkleRoot, merkleProof, amount, address(this));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = levx;
        uint256[] memory amounts = IUniswapV2Router01(router).swapExactETHForTokens{value: amount}(
            amountOutMin,
            path,
            to,
            deadline
        );
        amountOut = amounts[1];
    }

    function batchClaimAndSwapToLevx(
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata amounts,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountOut) {
        uint256 amountIn;
        for (uint256 i; i < merkleRoots.length; i++) {
            uint256 amount = amounts[i];
            claim(merkleRoots[i], merkleProofs[i], amount, address(this));
            amountIn += amount;
        }

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = levx;
        uint256[] memory _amounts = IUniswapV2Router01(router).swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            to,
            deadline
        );
        amountOut = _amounts[1];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}