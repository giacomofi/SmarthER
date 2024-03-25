//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface Minter {
    function purchase(
        address buyer,
        uint256 tokenId,
        string memory metaUri
    ) external returns (uint256);
}

/// @custom:security-contact [email protected]
contract BoogieWoogieRunOneAuction is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _printsSold;

    uint256 private _currentPrice;

    uint256 public constant MAX_ELEMENTS = 125;
    address public tokenContract;

    // Retain purchased Boogie-Woogies for lookup
    mapping(uint256 => bool) public purchased;

    event ReceivedPurchaseRequest(uint256 boogieWoogieId);
    event BoogieWoogiePurchased(address buyer, uint256 boogieWoogieId);

    constructor(address token) {
        // 1 ETH
        _currentPrice = 1 * 10**18;
        // 0.01
        // _currentPrice = 1 * 10**16;

        tokenContract = token;
    }

    function currentPrice() public view returns (uint256) {
        return _currentPrice;
    }

    function hasBeenPurchased(uint256 tokenId) public view returns (bool) {
        return purchased[tokenId];
    }

    function setCurrentPrice(uint256 price) public onlyOwner {
        _currentPrice = price;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() public onlyOwner {
        address payable to = payable(owner());

        to.transfer(getBalance());
    }

    error AlreadyPurchased();
    error OutOfBoogieWoogies();

    function purchaseBoogieWoogie(
        address buyer,
        uint256 boogieWoogieId,
        string memory metaUri
    ) external payable {
        require(msg.value >= _currentPrice, "Value is less than cost");

        require(_printsSold.current() <= MAX_ELEMENTS, "Sold Out");

        if (purchased[boogieWoogieId]) revert AlreadyPurchased();

        emit ReceivedPurchaseRequest(boogieWoogieId);

        purchased[boogieWoogieId] = true;
        _printsSold.increment();

        Minter(tokenContract).purchase(buyer, boogieWoogieId, metaUri);

        emit BoogieWoogiePurchased(buyer, boogieWoogieId);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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