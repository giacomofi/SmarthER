/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Ogac/OgacReferalMintCrossMint.sol


pragma solidity ^0.8.7;




interface IOgac {
	function mintBreeding(address _address, uint256 _mintAmount) external;
}


contract OgacReferalMintCrossMint is  Ownable {
  
   
    bool public paused = false;
    bool public payReferal = true;
    bool public mintWithErc20 = false;
    uint256 public maxMintAmountPerTransaction = 15;
    uint256 public maxSupply = 8420;
    uint256 public currentSupply = 4422; 
    uint256 public referalPayoutPerMint = 0.005 ether;
    uint256 public price = 0.055 ether;
    mapping(address => bool) public _allowedErc20;
    mapping(address => uint256) public _erc20MintPrice;
    mapping(address => bool) public _bridges;
    address public ERC20FUNDWALLET = 0x4fdc1E3a6c0243a089D80E90D7bd0e060044E267;
    address public crossmintAddress;
    
    IOgac public mintNft;
    
    
    constructor(address  _ogac) {
        mintNft = IOgac(_ogac);
    }


function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
    crossmintAddress = _crossmintAddress;
  }

  function crossmint(address _to, uint256 _amount) public payable {
       require(!paused, "Contract is paused");
        require((currentSupply + _amount) <= maxSupply, "Ogac Supply Passed");
        require( _amount <= maxMintAmountPerTransaction, "Passed Mint limit per transaction");
         require(msg.value >= (price * _amount), "Not enough Funds");
    // NOTE THAT the address is different for ethereum, polygon, and mumbai
    // ethereum (all)  = 0xdab1a1854214684ace522439684a145e62505233  
    require(msg.sender == crossmintAddress, 
      "This function is for Crossmint only."
    );

   
         if(_amount == 15){
             _mint(_to, _amount + 5);
              currentSupply += _amount + 5;
         }else if (_amount >= 12){
             _mint(_to, _amount + 4);
              currentSupply += _amount + 4;
         }else if(_amount >= 9) {
             _mint(_to, _amount + 3);
              currentSupply += _amount + 3;
         }else if(_amount >= 6){
             _mint(_to, _amount + 2);
              currentSupply += _amount + 2;
         }else if (_amount >= 3){
                _mint(_to, _amount + 1);
                 currentSupply += _amount +1;
         }else{
              currentSupply += _amount;
            _mint(_to, _amount);
         }   
    
  }

    function mintOgac(uint256 _amount, address payable ref) payable external {
        require(!paused, "Contract is paused");
        require((currentSupply + _amount) <= maxSupply, "Ogac Supply Passed");
        require( _amount <= maxMintAmountPerTransaction, "Passed Mint limit per transaction");
        //check price 
        if(msg.sender != owner()){
             require(msg.value >= (price * _amount), "Not enough Funds");
        }
           if(_amount == 15){
             _mint(msg.sender, _amount + 5);
              currentSupply += _amount + 5;
         }else if (_amount >= 12){
             _mint(msg.sender, _amount + 4);
              currentSupply += _amount + 4;
         }else if(_amount >= 9) {
             _mint(msg.sender, _amount + 3);
              currentSupply += _amount + 3;
         }else if(_amount >= 6){
             _mint(msg.sender, _amount + 2);
              currentSupply += _amount + 2;
         }else if (_amount >= 3){
                _mint(msg.sender, _amount + 1);
                 currentSupply += _amount +1;
         }else{
              currentSupply += _amount;
            _mint(msg.sender, _amount);
         }   

         if(ref != 0x0000000000000000000000000000000000000000 && payReferal){
            (bool sent,) = ref.call{value: _amount * referalPayoutPerMint}("");
            require(sent, "Failed to send to Referer");
         }
    }

    function mintOgacWithErc20(uint256 _amount, address _erc20) payable external {
        require(!paused, "Contract is paused");
        require(mintWithErc20, "ERC20 Payments Disabled");
        require((currentSupply + _amount) <= maxSupply, "Ogac Supply Passed");
        require( _amount <= maxMintAmountPerTransaction, "Passed Mint limit per transaction");
            //check if erc20 contract is allowed
            require(_allowedErc20[_erc20], "ERC20 is not allowed");
            //check if erc20 price is not 0
            require(_erc20MintPrice[_erc20] > 0, "ERC20 Mint price not set");
            //check allowance 
            require(IERC20(_erc20).allowance(msg.sender, address(this)) > (_erc20MintPrice[_erc20] * _amount), "Not enough Allowance");
            IERC20(_erc20).transferFrom(msg.sender,ERC20FUNDWALLET,_erc20MintPrice[_erc20] * _amount);
        
         currentSupply += _amount;
         if(_amount == 15){
             _mint(msg.sender, _amount + 5);
         }else if (_amount >= 12){
             _mint(msg.sender, _amount + 4);
         }else if(_amount >= 9) {
             _mint(msg.sender, _amount + 3);
         }else if(_amount >= 6){
             _mint(msg.sender, _amount + 2);
         }else if (_amount >= 3){
                _mint(msg.sender, _amount + 1);
         }else{
            _mint(msg.sender, _amount);
         }   
    }

    function setPause(bool _state) external  onlyOwner {
        paused = _state;
    }

    function setReferalPayout(uint256 _val) external onlyOwner {
        referalPayoutPerMint = _val;
    }

    function setErc20Paymentstate(bool _val) external onlyOwner{
       mintWithErc20 = _val;
    }

    function setReferalState(bool _val) external onlyOwner {
            payReferal = _val;
    }

    function setErc20ContractState(address _a, uint256 _p, bool _val) external onlyOwner{
        _allowedErc20[_a] = _val;
        _erc20MintPrice[_a] = _p;
    }

    function setBridges(address _a, bool _val) external onlyOwner{
        _bridges[_a] = _val;
    }
    
    function setErc20FundAddress(address _a) external onlyOwner {
        ERC20FUNDWALLET = _a;
    }

    function setMaxSupply(uint256 _val) external onlyOwner {
        maxSupply = _val;
    }

     function setPrice(uint256 _val) external onlyOwner {
        price = _val;
    }

    function setCurrentSupply(uint256 _val) external onlyOwner {
        currentSupply = _val;
    }


    function setMaxPerTransaction(uint256 _val) external onlyOwner{
        maxMintAmountPerTransaction = _val;
    }

    function _mint(address _user, uint256 _amount) internal {
            mintNft.mintBreeding(_user, _amount);
    }

     function mintExternal(address _address, uint256 _mintAmount) external {
        require(
            _bridges[msg.sender],
            "Sorry you don't have permission to mint"
        );
        mintNft.mintBreeding(_address, _mintAmount);
    }

     function gift(address _to, uint256 _mintAmount) public onlyOwner {
        mintNft.mintBreeding(_to, _mintAmount);
    }

     function withdraw() public payable onlyOwner {
        (bool hq, ) = payable(owner()).call{value: address(this).balance}("");
        require(hq);
    }

   
}