// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReceivePayments
 * @dev Keep track of Obscura pass payments
 */
contract ReceivePayments is Ownable {
    address payable treasury;
    mapping(uint256 => uint256) public passCost;
    mapping(uint256 => uint256) public userCount; // how many passes have been purchased
    mapping(uint256 => uint256) public maxCount;
    uint256 nextPassId;

    constructor() {
        treasury = payable(0xb94404C28FeAA59f8A3939d53E6b2901266Fa529);
    }

    event PaymentReceived(
        address sender,
        uint256 passId,
        uint256 value,
        uint256 numberOfPasses
    );
    event NewPassCreated(uint256 passId, uint256 cost);
    event TreasuryAddressChanged(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev receive payment for each of 3 Pass types
     * @param passId corresponds with type of Pass e.g. Curated SP1 (ID: 1), Foundry SP1 (ID: 2), Community SP1 (ID: 3)
     */
    function receivePassPayment(uint256 passId, uint256 numberOfPasses)
        public
        payable
    {
        require(
            (userCount[passId] + numberOfPasses) <= maxCount[passId],
            "Pass subscription is full."
        );
        userCount[passId] = userCount[passId] + numberOfPasses;

        // check that correct amount was sent
        require(
            msg.value == passCost[passId] * numberOfPasses,
            "Incorrect ETH amount provided."
        );

        (bool sent, ) = treasury.call{value: msg.value}("");

        emit PaymentReceived(msg.sender, passId, msg.value, numberOfPasses);

        require(sent, "Failed to send Ether");
    }

    /**
     * @dev create pass type
     * @param maxUsers max number of payments that can be made.
     * @param cost price of pass
     */
    function createPass(uint256 maxUsers, uint256 cost) public onlyOwner {
        passCost[nextPassId] = cost;
        maxCount[nextPassId] = maxUsers;

        emit NewPassCreated(nextPassId, cost);
        nextPassId++;
    }

    function changeTreasuryAddress(address newTreasuryAddress)
        public
        onlyOwner
    {
        emit TreasuryAddressChanged(treasury, newTreasuryAddress);
        treasury = payable(newTreasuryAddress);
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