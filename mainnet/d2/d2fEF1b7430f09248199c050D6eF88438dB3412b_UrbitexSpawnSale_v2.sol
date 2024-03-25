// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "./interface/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract UrbitexSpawnSale_v2 is Context, Ownable
{

  // This contract facilitates the sale of planets via spawning from a host star.
  // The intent is to be used only by the exchange owner to supply greater inventory to the 
  // marketplace without having to first spawn dozens of planets.

  //  SpawnedPurchase: sale has occurred
  //
    event SpawnedPurchase(
      uint32[] _points
    );

  //  azimuth: points state data store
  //
  IAzimuth public azimuth;

  //  price: fixed price to be set across all planets
  //
  uint256 public price;


  //  constructor(): configure the points data store and planet price
  //
  constructor(IAzimuth _azimuth, uint256 _price)
  {
    azimuth = _azimuth;
    setPrice(_price);
  }

    //  purchase(): pay the price, acquire ownership of the planets
    //

    function purchase(uint32[] calldata _points)
      external
      payable
    {
      // amount transferred must match price set by exchange owner
      require (msg.value == price*_points.length);

      //  omitting all checks here to save on gas fees (for example if transfer proxy is approved for the star)
      //  the transaction will just fail in that case regardless, which is intended.
      // 
      IEcliptic ecliptic = IEcliptic(azimuth.owner());

      //  spawn the planets, then immediately transfer to the buyer
      // 
      
      for (uint32 index; index < _points.length; index++) {
          ecliptic.spawn(_points[index], address(this));
          ecliptic.transferPoint(_points[index], _msgSender(), false);
        }

      emit SpawnedPurchase(_points);
    }


    // EXCHANGE OWNER OPERATIONS 

    function setPrice(uint256 _price) public onlyOwner {
      require(0 < _price);
      price = _price;
    }

    function withdraw(address payable _target) external onlyOwner  {
      require(address(0) != _target);
      _target.transfer(address(this).balance);
    }

    function close(address payable _target) external onlyOwner  {
      require(address(0) != _target);
      selfdestruct(_target);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAzimuth {
    function owner() external returns (address);
    function isSpawnProxy(uint32, address) external returns (bool);
    function hasBeenLinked(uint32) external returns (bool);
    function getPrefix(uint32) external returns (uint16);
    function getOwner(uint32) view external returns (address);
    function canTransfer(uint32, address) view external returns (bool);
    function isOwner(uint32, address) view external returns (bool);
    function getKeyRevisionNumber(uint32 _point) view external returns(uint32);
    function getSpawnCount(uint32 _point) view external returns(uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IEcliptic {
    function isApprovedForAll(address, address) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function spawn(uint32, address) external;
    function transferPoint(uint32, address, bool) external;


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
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