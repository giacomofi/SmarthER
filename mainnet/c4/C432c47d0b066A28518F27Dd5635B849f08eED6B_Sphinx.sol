// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

 
// User submits 3 riddles, first person to get them all right wins.
// All verification is done on chain
// Keeps track of number of entries [total and per user]
// Closes 3 days/72hrs after deployment [see timestamp logic]
// Full balance will be withdrawn and 69% sent to the winner
contract Sphinx is Ownable {

  bytes32 private solution1;
  bytes32 private solution2;
  bytes32 private solution3;
  bytes32 private solution4;
  bytes32 private solution5;
  uint private price = 0.01 ether;
  uint private seedPrice = 0.1 ether;
  bool private gameClosed = false;
  uint public numEntries = 0;
  address public winner;

  event Win(string message);
  event Loss(string message);

  mapping(address => uint) public participants;

  //deploy with solutions, set 3 day time limit [16 hours for testing]
  constructor(bytes32 _solution1, bytes32 _solution2, bytes32 _solution3, bytes32 _solution4, bytes32 _solution5) {
      solution1 = _solution1;
      solution2 = _solution2;
      solution3 = _solution3;
      solution4 = _solution4;
      solution5 = _solution5;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  //Accept 3 guesses + compare to solutions
  function entry(string memory answer1, string memory answer2, string memory answer3, string memory answer4, string memory answer5) external payable callerIsUser
  {
    require(
        gameClosed == false,
        "the game has closed"
    );

    require(
        msg.value >= price,
        "entry cost too low"
    );

    bytes32 answer1Hash = sha256(abi.encodePacked((answer1)));
    bytes32 answer2Hash = sha256(abi.encodePacked((answer2)));
    bytes32 answer3Hash = sha256(abi.encodePacked((answer3)));
    bytes32 answer4Hash = sha256(abi.encodePacked((answer4)));
    bytes32 answer5Hash = sha256(abi.encodePacked((answer5)));

    if (answer1Hash == solution1 && answer2Hash == solution2 && answer3Hash == solution3 && answer4Hash == solution4 && answer5Hash == solution5) {
        gameClosed = true;
        numEntries++;
        participants[msg.sender] = participants[msg.sender] + 1;
        winner = msg.sender;
        emit Win("Win");
    }
    else {
        numEntries++;
        participants[msg.sender] = participants[msg.sender] + 1;
        emit Loss("Loss");
    }
  }

  //String comparison 
  function compareStrings (bytes32 a, bytes32 b) public pure returns (bool) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  //Withdraw entire balance
  function withdrawAll() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  //Seed prize pool initially
  function addInitialBalance() external payable {
    require(
        msg.value >= seedPrice,
        "initial seeding too low"
    );
  }

  //For testing
  function manualGameOpen() external onlyOwner {
    gameClosed = false;
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