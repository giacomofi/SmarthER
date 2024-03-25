pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PathPrivateBClaim is Ownable{

    IERC20 immutable private token;

    uint public grandTotalClaimed = 0;
    uint immutable public startTime;

    uint private totalAllocated;
    

    struct Allocation {
        uint TGEAllocation; //tokens allocateed at TGE
        uint initialAllocation; //Initial token allocated after first cliff
        uint endInitial; // Initial token claim locked until 
        uint endCliff; // Vested Tokens are locked until
        uint endVesting; // End vesting 
        uint totalAllocated; // Total tokens allocated
        uint amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;

    event claimedToken(address indexed _recipient, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress, uint _startTime) {
        require(_startTime >= 1638896400, "start time should be larger or equal to TGE");
        token = IERC20(_tokenAddress);
        startTime = _startTime;
    }

    function getClaimTotal(address _recipient) public view returns (uint amount) {
        return  calculateClaimAmount(_recipient) - allocations[_recipient].amountClaimed;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient) internal view returns (uint amount) {
         uint newClaimAmount;

        if (block.timestamp >= allocations[_recipient].endVesting) {
            newClaimAmount = allocations[_recipient].totalAllocated;
        }
        else {
            newClaimAmount = allocations[_recipient].TGEAllocation;
            if (block.timestamp >=  allocations[_recipient].endInitial) {
                newClaimAmount += allocations[_recipient].initialAllocation;
            }
            if (block.timestamp >= allocations[_recipient].endCliff) {
                newClaimAmount += ((allocations[_recipient].totalAllocated - allocations[_recipient].initialAllocation - allocations[_recipient].TGEAllocation)
                	* (block.timestamp - allocations[_recipient].endCliff))
                    / (allocations[_recipient].endVesting - allocations[_recipient].endCliff);
            }
        }
        return newClaimAmount;
    }

    /**
    * @dev Set the minters and their corresponding allocations. Each mint gets 40000 Path Tokens with a vesting schedule
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation(
        address[] memory _addresses,
        uint[] memory _TGEAllocation,
        uint[] memory _totalAllocated,
        uint[] memory _initialAllocation,
        uint[] memory _endInitial,
        uint[] memory _endCliff,
        uint[] memory _endVesting) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length, "length of array should be the same");
        require(_addresses.length == _initialAllocation.length, "length of array should be the same");
        require(_addresses.length == _endInitial.length, "length of array should be the same");
        require(_addresses.length == _endCliff.length, "length of array should be the same");
        require(_addresses.length == _endVesting.length, "length of array should be the same");
        uint amountToTransfer;
        for (uint i = 0; i < _addresses.length; i++ ) {
            require(_endInitial[i] <= _endCliff[i], "Initial claim should be earlier than end cliff time");
            allocations[_addresses[i]] = Allocation(
                _TGEAllocation[i],
                _initialAllocation[i],
                _endInitial[i],
                _endCliff[i],
                _endVesting[i],
                _totalAllocated[i],
                0);
            amountToTransfer += _totalAllocated[i];
            totalAllocated += _totalAllocated[i];
        }
        require(token.transferFrom(msg.sender, address(this), amountToTransfer), "Token transfer failed");
    }

    /**
    * @dev Check current claimable amount
    * @param _recipient recipient of allocation
     */
    function getRemainingAmount (address _recipient) external view returns (uint amount) {
        return allocations[_recipient].totalAllocated - allocations[_recipient].amountClaimed;
    }


     /**
     * @dev transfers allocated tokens to recipient to their address
     * @param _recipient the addresss to withdraw tokens for
      */
    function transferTokens(address _recipient) external {
        require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        require(startTime <= allocations[_recipient].endInitial, "Initial claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(_recipient);
        uint tokensToClaim = getClaimTotal(_recipient);
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        allocations[_recipient].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(_recipient, tokensToClaim), "Token transfer failed");
        emit claimedToken(_recipient, tokensToClaim, allocations[_recipient].amountClaimed);
    }

    //owner restricted functions
    /**
     * @dev reclaim excess allocated tokens for claiming
     * @param _amount the amount to withdraw tokens for
      */
    function reclaimExcessTokens(uint _amount) external onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - (totalAllocated - grandTotalClaimed), "Amount of tokens to recover is more than what is allowed");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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