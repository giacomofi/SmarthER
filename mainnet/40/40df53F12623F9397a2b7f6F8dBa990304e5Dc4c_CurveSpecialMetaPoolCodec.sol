// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICodec.sol";
import "../interfaces/ICurvePool.sol";
import "./CurveTokenAddresses.sol";

/**
 * @title a special codec for pools that implement exchange_underlying() slightly differently than others.
 * e.g. "sUSD" pool on Ethereum and "aave" on Polygon
 * @author padoriku
 * @notice encode/decode calldata
 */
contract CurveSpecialMetaPoolCodec is ICodec, CurveTokenAddresses {
    struct SwapCalldata {
        int128 i;
        int128 j;
        uint256 dx;
        uint256 min_dy;
    }

    constructor(address[] memory _pools, address[][] memory _poolTokens) CurveTokenAddresses(_pools, _poolTokens) {}

    function decodeCalldata(ICodec.SwapDescription calldata _swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        )
    {
        SwapCalldata memory data = abi.decode((_swap.data[4:]), (SwapCalldata));
        amountIn = data.dx;
        uint256 i = uint256(uint128(data.i));
        uint256 j = uint256(uint128(data.j));

        address[] memory tokens = poolToTokens[_swap.dex];
        if (tokens.length > 0) {
            // some pool(sUSD)'s implementation of underlying_coins takes uint128 instead of uint256 as input
            // register these pool's token addresses manually to workaround this.
            tokenIn = tokens[i];
            tokenOut = tokens[j];
        } else {
            tokenIn = ICurvePool(_swap.dex).underlying_coins(i);
            tokenOut = ICurvePool(_swap.dex).underlying_coins(j);
        }
    }

    function encodeCalldataWithOverride(
        bytes calldata _data,
        uint256 _amountInOverride,
        address // _receiverOverride
    ) external pure returns (bytes memory swapCalldata) {
        bytes4 selector = bytes4(_data);
        SwapCalldata memory data = abi.decode((_data[4:]), (SwapCalldata));
        data.dx = _amountInOverride;
        return abi.encodeWithSelector(selector, data);
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ICodec {
    struct SwapDescription {
        address dex; // the DEX to use for the swap, zero address implies no swap needed
        bytes data; // the data to call the dex with
    }

    function decodeCalldata(SwapDescription calldata swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        );

    function encodeCalldataWithOverride(
        bytes calldata data,
        uint256 amountInOverride,
        address receiverOverride
    ) external pure returns (bytes memory swapCalldata);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function underlying_coins(uint256 i) external view returns (address);

    // plain & meta pool
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    // meta pool
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    // plain & meta pool
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    // meta pool
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    // special function signature that is only used by the sUSD pool on Ethereum 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CurveTokenAddresses is Ownable {
    event PoolTokensSet(address[] pools, address[][] poolTokens);

    // Pool address to *underlying* token addresses. position sensitive.
    // This is needed because some of the metapools fail to implement curve's underlying_coins() spec,
    // therefore no consistant way to query token addresses by their indices.
    mapping(address => address[]) public poolToTokens;

    constructor(address[] memory _pools, address[][] memory _poolTokens) {
        _setPoolTokens(_pools, _poolTokens);
    }

    function setPoolTokens(address[] calldata _pools, address[][] calldata _poolTokens) external onlyOwner {
        _setPoolTokens(_pools, _poolTokens);
    }

    function _setPoolTokens(address[] memory _pools, address[][] memory _poolTokens) private {
        require(_pools.length == _poolTokens.length, "len mm");
        for (uint256 i = 0; i < _pools.length; i++) {
            poolToTokens[_pools[i]] = _poolTokens[i];
        }
        emit PoolTokensSet(_pools, _poolTokens);
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