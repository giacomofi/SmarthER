// SPDX-License-Identifier: Unlicense
// Creator: 0xVeryBased

// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  /‾‾‾‾\‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  / /‾‾\ \--------------------------\  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  | |  _/ /__________________________/  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  \ \___/__________________________/  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  \                            \  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾           |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |                            |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  /   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   /  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  /   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾       /  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  /                            /  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾                    |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |                            |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾             |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛  /____________________________/  ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                ████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██          ████████        ████████▒▒▒▒▒▒
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██          ██░░░░░░░░██              ████▒▒
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██        ██░░░░░░░░██                ████
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░██          ████████            ██████  ██
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██  ██████                        ████████        ██
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██          ██████            ██████                ██
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██          ██░░░░░░██    ██████                      ██
// ▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        ████░░░░░░░░░░████                      ██████▒▒
// ▒▒▒▒▒▒▒▒▒▒▒▒██          ████░░░░░░░░░░██                      ██░░██▒▒▒▒
// ▒▒▒▒▒▒▒▒▒▒██      ██████████░░░░░░░░░░██                      ██░░██▒▒▒▒
// ▒▒▒▒▒▒▒▒██  ██████      ████░░░░░░░░░░██                        ██████▒▒
// ▒▒▒▒▒▒▒▒████                ██░░░░░░██                              ██▒▒
// ▒▒▒▒▒▒██                      ██████          ████                  ██▒▒
// ▒▒▒▒▒▒██                                    ▓▓░░░░██          ████████▒▒
// ▒▒▒▒▒▒██                                    ▓▓░░░░██        ██░░░░██▒▒▒▒
// ▒▒▒▒▒▒████████        ██                      ████        ██░░░░██▒▒▒▒▒▒
// ▒▒▒▒▒▒▒▒██░░██      ██░░████                              ██░░░░██▒▒▒▒▒▒
// ▒▒▒▒▒▒▒▒██░░░░██      ██                                  ██░░░░██▒▒▒▒▒▒
// ▒▒▒▒▒▒▒▒▒▒██░░██                                            ██░░░░██░░▒▒
// ▒▒▒▒▒▒▒▒██░░░░██                ████████                      ██████▒▒▒▒
// ▒▒▒▒▒▒▒▒██░░██                ██░░░░░░░░██                        ██▒▒▒▒
// ▒▒▒▒██████████              ██░░░░░░░░░░░░██░░              ██████▒▒▒▒▒▒
// ▒▒██                    ████░░░░░░██████░░░░██      ████████▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒██                    ████░░░░██▒▒▒▒▒▒████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒██                    ████░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒██                        ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒▒▒██                  ██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// ▒▒▒▒▒▒██████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721.sol";

contract ElixirMetadataInitial is Ownable {
    using Strings for uint256;

    address public elixirBottleContract;

    modifier onlyBottleContract() {
        _isBottleContract();
        _;
    }
    function _isBottleContract() internal view virtual {
        require(msg.sender == elixirBottleContract, "ebc req");
    }

    /*******************************************************************/
    /*** CONSTRUCTOR (Start) *******************************************/
    constructor(
        address _ebAddy
    ) {
        elixirBottleContract = _ebAddy;
    }
    /*** CONSTRUCTOR (End) *******************************************/
    /*****************************************************************/


    function registerIngredient(address ingredientContract, string memory ingredientName) public onlyOwner {}

    function getIngredientContract(uint256 ingredientType) public view returns (address) {
        return address(0);
    }

    function getCharges(uint256 elixirId) public view returns (uint256) {
        require(ElixirBottlesWithExists(elixirBottleContract).exists(elixirId), "z");
        return 0;
    }

    function setCharges(uint256 elixirId, uint256 numCharges) private {}

    function getElement(uint256 elixirId) public view returns (uint256) {
        require(ElixirBottlesWithExists(elixirBottleContract).exists(elixirId), "z");
        return 0;
    }

    function setElement(uint256 elixirId, uint256 whichElement) private {}

    function getAttributes(uint256 elixirId) public view returns (uint256[] memory) {
        require(ElixirBottlesWithExists(elixirBottleContract).exists(elixirId), "z");

        uint256[] memory toReturn = new uint256[](0);
        return toReturn;
    }

    function getElementAndAttributes(
        uint256 elixirId
    ) public view returns (uint256, uint256[] memory) {
        return (getElement(elixirId), getAttributes(elixirId));
    }

    function getChargesElementAndAttributes(
        uint256 elixirId
    ) public view returns (uint256, uint256, uint256[] memory) {
        return (getCharges(elixirId), getElement(elixirId), getAttributes(elixirId));
    }

    function getIngredientList() public view returns (string[] memory) {
        string[] memory toReturn = new string[](0);

        return toReturn;
    }

    function charge(
        uint256 elixirId,
        uint256[] memory ingredientTypes,
        uint256[] memory ingredientIDs
    ) public onlyBottleContract {}

    function drink(uint256 elixirId) public onlyBottleContract {}

    function spill(uint256 elixirId) public onlyBottleContract {}

    function getElixirMetadata(uint256 elixirId) public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"Elixir #", elixirId.toString(),"\",",
                "\"description\":\"", "An empty elixir bottle... What will it be filled with???", "\",",
                "\"image\":\"", "https://crudeborne.mypinata.cloud/ipfs/Qme96t7UMkWYatkUCMUXA5XkYjWLcLUD6sPiftY9fM96wJ", "\",",
                "\"animation_url\":\"", "https://crudeborne.mypinata.cloud/ipfs/QmRiTY3sLQAxCvRhS7HYNiyTZnfL8ETyUq7cmbMrCPBHZg", "\",",
                "\"external_link\":\"https://crudeborne.wtf\",",
                "\"attributes\":[{\"trait_type\": \"Element\", \"value\": \"Unknown\"},",
                "{\"trait_type\": \"Charges\", \"value\": 0}]}"
            )
        );
    }
}

////////////////////

abstract contract ElixirBottlesWithExists {
    function exists(uint256 tokenId) public view virtual returns (bool);
}

////////////////////////////////////////

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: Unlicense
// Creator: CrudeBorne
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
contract ERC721 is Context, ERC165 {//, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

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

    uint256 private currentIndex = 0;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

//    // Base URI
//    string private _baseURI;
//    string private _preRevealURI;

    mapping(uint256 => address) private _ownerships;
    mapping(address => uint256) private _balances;

    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private numTokensBurned;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
    **/
//    function totalSupply() public view override returns (uint256) {
    function totalSupply() public view returns (uint256) {
        return (currentIndex - numTokensBurned);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
//    function tokenByIndex(uint256 index) public view override returns (uint256) {
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "g");
        require(ownerOf(index) != burnAddress, "b");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
//    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "b");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            address ownership = _ownerships[i];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
//    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
//    function balanceOf(address owner) public view override returns (uint256) {
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_balances[owner]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
//    function ownerOf(uint256 tokenId) public view override returns (address) {
    function ownerOf(uint256 tokenId) public view returns (address) {
        //        return ownershipOf(tokenId);

        require(tokenId < currentIndex, "t");

        for (uint256 curr = tokenId; curr >= 0; curr--) {
            address ownership = _ownerships[curr];
            if (ownership != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
//    function name() public view virtual override returns (string memory) {
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
//    function symbol() public view virtual override returns (string memory) {
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
    * @dev See {IERC721-approve}.
     */
//    function approve(address to, uint256 tokenId) public override {
    function approve(address to, uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "o");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
//    function getApproved(uint256 tokenId) public view override returns (address) {
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
//    function setApprovalForAll(address operator, bool approved) public override {
    function setApprovalForAll(address operator, bool approved) public {
//        require(operator != _msgSender() && !(operatorRestrict[operator]), "a;r");
        require(operator != _msgSender(), "a");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
//    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
//    ) public override {
    ) public {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
//    ) public override {
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
//    ) public override {
    ) public {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "z"
        );
    }

    function burnToken(uint256 tokenId) public {
        _transfer(ownerOf(tokenId), burnAddress, tokenId);
        numTokensBurned++;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId < currentIndex && ownerOf(tokenId) != burnAddress);
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);
        require(_checkOnERC721Received(address(0), to, currentIndex - 1, _data), "z");
    }

    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");

        _balances[to] = _balances[to] + quantity;
        _ownerships[startTokenId] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            updatedIndex++;
        }

        currentIndex = updatedIndex;
    }

    /******************/

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address prevOwnership = ownerOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership ||
        getApproved(tokenId) == _msgSender() ||
        isApprovedForAll(prevOwnership, _msgSender()));

        require(isApprovedOrOwner && prevOwnership == from, "a");
        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= 1;
        _balances[to] += 1;
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /******************/

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

////////////////////////////////////////

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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