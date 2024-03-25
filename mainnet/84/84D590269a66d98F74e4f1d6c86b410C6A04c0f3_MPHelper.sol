// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./PunksMarket.sol";


/**
 * @title MPHelper contract
 * @author @FrankPoncelet
 * 
 */
 contract MPHelper{
    PunksMarket public mPContract;

    constructor() {
        mPContract = PunksMarket(payable(0x759c6C1923910930C18ef490B3c3DbeFf24003cE));
        }

    function getAllBids(uint256[] memory ids) external view returns (PunksMarket.Punk[] memory){
        uint tokens = 0;
        for (uint i=0; i<ids.length; i++) {
            PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
            if (punk.bid.hasBid && !isForSale(punk)){
                tokens+=1;
            }
        }
        PunksMarket.Punk[] memory punks = new PunksMarket.Punk[](tokens);
        uint index = 0;
        for (uint i=0; i<ids.length; i++) {
            PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
            if (punk.bid.hasBid && !isForSale(punk)){
                punks[index]=mPContract.getPunksDetails(ids[i]);
                index +=1;
            }
        }

        return punks;
    }

    function getAllForSale(uint256[] memory ids) external view returns (PunksMarket.Punk[] memory){
        uint tokens = 0;
        for (uint i=0; i<ids.length; i++) {
            PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
            if (isForSale(punk)){
                tokens+=1;
            }
        }
        PunksMarket.Punk[] memory punks = new PunksMarket.Punk[](tokens);
        uint index = 0;
        for (uint i=0; i<ids.length; i++) {
            PunksMarket.Punk memory punk = mPContract.getPunksDetails(ids[i]);
            if (isForSale(punk)){
                punks[index]=mPContract.getPunksDetails(ids[i]);
                index +=1;
            }
        }
        return punks;
    }

    function getDetailsForIds(uint256[] memory ids) external view returns (PunksMarket.Punk[] memory){
        PunksMarket.Punk[] memory punks = new PunksMarket.Punk[](ids.length);
        for (uint i=0; i<ids.length; i++) {
            punks[i]=mPContract.getPunksDetails(ids[i]);
        }
        return punks;
    }

    function isForSale(PunksMarket.Punk memory punk) public pure returns (bool){
        return punk.offer.isForSale && punk.owner==punk.offer.seller;
    }

 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/ReentrancyGuard.sol";
import "./library/AdminControl.sol";



/**
 * @title PunksMarket contract
 * @author @FrankPoncelet
 * 
 */
contract PunksMarket is AdminControl, Pausable , ReentrancyGuard{

    IERC721 public punksWrapperContract; // instance of the Cryptopunks contract
    ICryptoPunk public punkContract; // Instance of cryptopunk smart contract

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint256 minValue;          // in WEI
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint punkIndex;
        address bidder;
        uint256 value;
    }

    struct Punk {
        bool wrapped;
        address owner;
        Bid bid;
        Offer offer;
    }

    // keep track of the totale volume processed by this contract.
    uint256 public totalVolume;
    uint constant public TOTAL_PUNKS = 10000;

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) private punksOfferedForSale;

    // A record of the highest punk bid
    mapping (uint => Bid) private punkBids;

    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    /* 
    * Initializes contract with an instance of CryptoPunks Wrapper contract
    */
    constructor() {
        punksWrapperContract = IERC721(0x7898972F9708358ACb7Ea7d000EbDf28FCdF325C); // TODO change on deploy main net
        punkContract = ICryptoPunk(0x85252f525456D3fCe3654e56f6EAF034075e231C); // TODO change on deploy main net
    }

    /* Allows the owner of the contract to set a new Cryptopunks WRAPPER contract address */
    function setPunksWrapperContract(address newpunksAddress) public onlyOwner {
      punksWrapperContract = IERC721(newpunksAddress);
    }

    /* Allows the owner of a CryptoPunks to stop offering it for sale */
    function punkNoLongerForSale(uint punkIndex) public nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,"you are not the owner of this token");
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0x0));
        emit PunkNoLongerForSale(punkIndex);
    }

    /* Allows a CryptoPunk owner to offer it for sale */
    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) public whenNotPaused nonReentrant()  {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,"you are not the owner of this token");
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0x0));
    }

    /* Allows a Cryptopunk owner to offer it for sale to a specific address */
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,"you are not the owner of this token");
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }
    

    /* Allows users to buy a Cryptopunk offered for sale */
    function buyPunk(uint punkIndex) payable public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        Offer memory offer = punksOfferedForSale[punkIndex];
        require (offer.isForSale,"Punk is not for sale"); // punk not actually for sale
        require (offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender,"Private sale.") ;                
        require (msg.value >= offer.minValue,"Not enough ether send"); // Didn't send enough ETH
        address seller = offer.seller;
        require  (seller == punksWrapperContract.ownerOf(punkIndex),'seller no longer owner of punk'); // Seller no longer owner of punk

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0x0));
        _withdraw(seller,msg.value);
        totalVolume += msg.value;
        punksWrapperContract.safeTransferFrom(seller, msg.sender, punkIndex);

        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            _withdraw(msg.sender,bid.value);
            punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        }
    }
    /* Allows users to enter bids for any Cryptopunk */
    function enterBidForPunk(uint punkIndex) payable public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require (punksWrapperContract.ownerOf(punkIndex) != msg.sender,"You already own this punk");
        require (msg.value > 0,"Cannot enter bid of zero");
        Bid memory existing = punkBids[punkIndex];
        require (msg.value > existing.value,"your bid is too low");
        if (existing.value > 0) {
            // Refund the failing bid
            _withdraw(existing.bidder,existing.value);
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    /* Allows Cryptopunk owners to accept bids for their punks */
    function acceptBidForPunk(uint punkIndex, uint minPrice) public whenNotPaused nonReentrant() {
        require(punkIndex < 10000,"Token index not valid");
        require(punksWrapperContract.ownerOf(punkIndex) == msg.sender,'you are not the owner of this token');
        address seller = msg.sender;
        Bid memory bid = punkBids[punkIndex];
        require(bid.hasBid == true,"Punk has no bid"); 
        require (bid.value >= minPrice,"The bid is too low");

        address bidder = bid.bidder;
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bidder, 0, address(0x0));
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);

        _withdraw(seller,amount); 
        totalVolume += amount;
        punksWrapperContract.safeTransferFrom(msg.sender, bidder, punkIndex);

        emit PunkBought(punkIndex, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForPunk(uint punkIndex) public nonReentrant() {
        require(punkIndex < 10000,"token index not valid");
        Bid memory bid = punkBids[punkIndex];
        require (bid.bidder == msg.sender,"The bidder is not message sender");
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        // Refund the bid money
        _withdraw(msg.sender,amount);
    }

    ///////// Website only methods ////////////
    function getBid(uint punkIndex) external view returns (Bid memory){
        return punkBids[punkIndex];
    }

    function getOffer(uint punkIndex) external view returns (Offer memory){
        return punksOfferedForSale[punkIndex];
    }

    /**
    * Returns offer, bid and owner data for a specific punk.
    */
    function getPunksDetails(uint index) external view returns (Punk memory) {
            address owner = punkContract.punkIndexToAddress(index);
            bool wrapper = false;
            if (owner==address(punksWrapperContract)){
                owner = punksWrapperContract.ownerOf(index);
                wrapper = true;
            }
            Punk memory punks=Punk(wrapper,owner,punkBids[index],punksOfferedForSale[index]);
        return punks;
    }

    /**
    * Returns the id's of all wrapped punks.
    */
    function getAllWrappedPunks() external view returns (int[] memory){
        int[] memory ids = new int[](TOTAL_PUNKS);
        for (uint i=0; i<TOTAL_PUNKS; i++) {
            ids[i]= 11111;
        }
        uint256 j =0;
        for (uint256 i=0; i<TOTAL_PUNKS; i++) {
            if ( punkContract.punkIndexToAddress(i) == address(punksWrapperContract)) {
                ids[j] = int(i);
                j++;
            }
        }
        return ids;
    }

    /**
    * Returns the id's of the UNWRAPPED punks for an address
    */
    function getPunksForAddress(address user) external view returns(uint256[] memory) {
        uint256[] memory punks = new uint256[](punkContract.balanceOf(user));
        uint256 j =0;
        for (uint256 i=0; i<TOTAL_PUNKS; i++) {
            if ( punkContract.punkIndexToAddress(i) == user ) {
                punks[j] = i;
                j++;
            }
        }
        return punks;
    }

    /**
    * Returns the id's of the WRAPPED punks for an address
    */
    function getWrappedPunksForAddress(address user) external view returns(uint256[] memory) {
        uint256[] memory punks = new uint256[](punksWrapperContract.balanceOf(user));
        uint256 j =0;
        for (uint256 i=0; i<TOTAL_PUNKS; i++) {
            try punksWrapperContract.ownerOf(i) returns (address owner){
                if ( owner == user ) {
                    punks[j] = i;
                    j++;
                }
            } catch {
                // ignore
            }
        }
        return punks;
    }

    ////////// safe withdraw method //////////
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to send Ether");
    }

    ////////// Contract safety, emergency methods////////
    /**
    * Allow the CONTRACT owner/admin to return a bid. 
    */
    function returnBid(uint punkIndex) public adminRequired {
        Bid memory bid = punkBids[punkIndex];
        uint amount = bid.value;
        address bidder = bid.bidder;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        emit PunkBidWithdrawn(punkIndex, amount, bidder);
        _withdraw(bidder,amount);
    }
    /**
    * Allow the CONTRACT owner/admin to END an offer. 
    */
    function revokeSale(uint punkIndex) public adminRequired {
        require(punkIndex < 10000,"Token index not valid");
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, address(0x0), 0, address(0x0));
        emit PunkNoLongerForSale(punkIndex);
    }

    /////////// pause methods /////////////
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ///////// contract can recieve Ether if needed//////
    fallback() external payable { }
    receive() external payable { }

}

interface ICryptoPunk {
    function punkIndexToAddress(uint punkIndex) external view returns (address);
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
    function balanceOf(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * Based one AdminControl from manifold.xyz, but simplified.
 * @author @frankPoncelet
 */

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/structs/EnumerableSet.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";

abstract contract AdminControl is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}