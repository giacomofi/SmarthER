/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;






/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
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
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol

pragma solidity ^0.6.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
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

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;


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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// File: contracts/interface/IKyberNetworkProxy.sol

pragma solidity 0.6.2;


interface IKyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external payable returns(uint);
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minRate) external returns(uint);
}

// File: contracts/interface/IKyberStaking.sol

pragma solidity 0.6.2;

interface IKyberStaking {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getLatestStakeBalance(address staker) external view returns(uint);
}

// File: contracts/interface/IKyberDAO.sol

pragma solidity 0.6.2;

interface IKyberDAO {
    function submitVote(uint256 proposalId, uint256 optionBitMask) external;
}

// File: contracts/interface/IKyberFeeHandler.sol

pragma solidity 0.6.2;

interface IKyberFeeHandler {
    function claimStakerReward(
        address staker,
        uint256 epoch
    ) external returns(uint256 amountWei);
}

// File: contracts/interface/INewKNC.sol

pragma solidity 0.6.2;

interface INewKNC {
    function mintWithOldKnc(uint256 amount) external;
}

// File: contracts/interface/IRewardsDistributor.sol

pragma solidity 0.6.2;


interface IRewardsDistributor {
  function claim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external returns (uint256[] memory claimAmounts);
}

// File: contracts/xKNC.sol

pragma solidity 0.6.2;













/*
 * xKNC KyberDAO Pool Token
 * Communal Staking Pool with Stated Governance Position
 */
contract xKNC is
    Initializable,
    ERC20,
    OwnableUpgradeSafe,
    PausableUpgradeSafe,
    ReentrancyGuardUpgradeSafe
{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ERC20 private knc;
    IKyberDAO private kyberDao;
    IKyberStaking private kyberStaking;
    IKyberNetworkProxy private kyberProxy;
    IKyberFeeHandler[] private kyberFeeHandlers;

    address[] private kyberFeeTokens;

    uint256 private constant PERCENT = 100;
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;

    uint256 private withdrawableEthFees;
    uint256 private withdrawableKncFees;

    string public mandate;

    address private manager;
    address private manager2;

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);

    enum FeeTypes {MINT, BURN, CLAIM}

    // vars added for v3
    bool private v3Initialized;
    IRewardsDistributor private rewardsDistributor;


    function initialize(
        string memory _symbol,
        string memory _mandate,
        IKyberStaking _kyberStaking,
        IKyberNetworkProxy _kyberProxy,
        ERC20 _knc,
        IKyberDAO _kyberDao,
        uint256 mintFee,
        uint256 burnFee,
        uint256 claimFee
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained("xKNC", _symbol);

        mandate = _mandate;
        kyberStaking = _kyberStaking;
        kyberProxy = _kyberProxy;
        knc = _knc;
        kyberDao = _kyberDao;

        _setFeeDivisors(mintFee, burnFee, claimFee);
    }

    /*
     * @notice Called by users buying with ETH
     * @dev Swaps ETH for KNC, deposits to Staking contract
     * @dev: Mints pro rata xKNC tokens
     * @param: kyberProxy.getExpectedRate(eth => knc)
     */
    function mint(uint256 minRate) external payable whenNotPaused {
        require(msg.value > 0, "Must send eth with tx");
        // ethBalBefore checked in case of eth still waiting for exch to KNC
        uint256 ethBalBefore = getFundEthBalanceWei().sub(msg.value);
        uint256 fee = _administerEthFee(FeeTypes.MINT, ethBalBefore);

        uint256 ethValueForKnc = msg.value.sub(fee);
        uint256 kncBalanceBefore = getFundKncBalanceTwei();

        _swapEtherToKnc(ethValueForKnc, minRate);
        _deposit(getAvailableKncBalanceTwei());

        uint256 mintAmount = _calculateMintAmount(kncBalanceBefore);

        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @notice Called by users buying with KNC
     * @notice Users must submit ERC20 approval before calling
     * @dev Deposits to Staking contract
     * @dev: Mints pro rata xKNC tokens
     * @param: Number of KNC to contribue
     */
    function mintWithToken(uint256 kncAmountTwei) external whenNotPaused {
        require(kncAmountTwei > 0, "Must contribute KNC");
        knc.safeTransferFrom(msg.sender, address(this), kncAmountTwei);

        uint256 kncBalanceBefore = getFundKncBalanceTwei();
        _administerKncFee(kncAmountTwei, FeeTypes.MINT);

        _deposit(getAvailableKncBalanceTwei());

        uint256 mintAmount = _calculateMintAmount(kncBalanceBefore);

        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @notice Called by users burning their xKNC
     * @dev Calculates pro rata KNC and redeems from Staking contract
     * @dev: Exchanges for ETH if necessary and pays out to caller
     * @param tokensToRedeem
     * @param redeemForKnc bool: if true, redeem for KNC; otherwise ETH
     * @param kyberProxy.getExpectedRate(knc => eth)
     */
    function burn(
        uint256 tokensToRedeemTwei,
        bool redeemForKnc,
        uint256 minRate
    ) external nonReentrant {
        require(
            balanceOf(msg.sender) >= tokensToRedeemTwei,
            "Insufficient balance"
        );

        uint256 proRataKnc =
            getFundKncBalanceTwei().mul(tokensToRedeemTwei).div(totalSupply());
        _withdraw(proRataKnc);
        super._burn(msg.sender, tokensToRedeemTwei);

        if (redeemForKnc) {
            uint256 fee = _administerKncFee(proRataKnc, FeeTypes.BURN);
            knc.safeTransfer(msg.sender, proRataKnc.sub(fee));
        } else {
            // safeguard to not overcompensate _burn sender in case eth still awaiting for exch to KNC
            uint256 ethBalBefore = getFundEthBalanceWei();
            kyberProxy.swapTokenToEther(
                knc,
                getAvailableKncBalanceTwei(),
                minRate
            );

            _administerEthFee(FeeTypes.BURN, ethBalBefore);

            uint256 valToSend = getFundEthBalanceWei().sub(ethBalBefore);
            (bool success, ) = msg.sender.call.value(valToSend)("");
            require(success, "Burn transfer failed");
        }
    }

    /*
     * @notice Calculates proportional issuance according to KNC contribution
     * @notice Fund starts at ratio of INITIAL_SUPPLY_MULTIPLIER/1 == xKNC supply/KNC balance
     * and approaches 1/1 as rewards accrue in KNC
     * @param kncBalanceBefore used to determine ratio of incremental to current KNC
     */
    function _calculateMintAmount(uint256 kncBalanceBefore)
        private
        view
        returns (uint256 mintAmount)
    {
        uint256 kncBalanceAfter = getFundKncBalanceTwei();
        if (totalSupply() == 0)
            return kncBalanceAfter.mul(INITIAL_SUPPLY_MULTIPLIER);

        mintAmount = (kncBalanceAfter.sub(kncBalanceBefore))
            .mul(totalSupply())
            .div(kncBalanceBefore);
    }

    /*
     * @notice KyberDAO deposit
     */
    function _deposit(uint256 amount) private {
        kyberStaking.deposit(amount);
    }

    /*
     * @notice KyberDAO withdraw
     */
    function _withdraw(uint256 amount) private {
        kyberStaking.withdraw(amount);
    }

    /*
     * @notice Vote on KyberDAO campaigns
     * @dev Admin calls with relevant params for each campaign in an epoch
     * @param proposalId: DAO proposalId
     * @param optionBitMask: voting option
     */
    function vote(uint256 proposalId, uint256 optionBitMask)
        external
        onlyOwnerOrManager
    {
        kyberDao.submitVote(proposalId, optionBitMask);
    }



    /*
     * @notice Claim reward from previous epoch
     * @dev Admin calls with relevant params
     * @dev ETH/other asset rewards swapped into KNC
     * @param cycle - sourced from Kyber API
     * @param index - sourced from Kyber API
     * @param tokens - ERC20 fee tokens
     * @param merkleProof - sourced from Kyber API
     * @param minRates - kyberProxy.getExpectedRate(eth/token => knc)
     */
    function claimReward(
        uint256 cycle,
        uint256 index,
        IERC20[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32[] calldata merkleProof,
        uint256[] calldata minRates
    ) external onlyOwnerOrManager {
        require(tokens.length == minRates.length, "Must be equal length");

        rewardsDistributor.claim(
            cycle,
            index,
            address(this),
            tokens,
            cumulativeAmounts,
            merkleProof
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            if(address(tokens[i]) == address(knc)){
                continue;
            }else if(address(tokens[i]) == ETH_ADDRESS){
                _swapEtherToKnc(getFundEthBalanceWei(), minRates[i]);
            } else {
                _swapTokenToKnc(address(tokens[i]), tokens[i].balanceOf(address(this)), minRates[i]);
            }
        }

        _administerKncFee(getAvailableKncBalanceTwei(), FeeTypes.CLAIM);
        _deposit(getAvailableKncBalanceTwei());
    }

    function _swapEtherToKnc(uint256 amount, uint256 minRate) private {
        kyberProxy.swapEtherToToken.value(amount)(knc, minRate);
    }

    function _swapTokenToKnc(
        address fromAddress,
        uint256 amount,
        uint256 minRate
    ) private {
        kyberProxy.swapTokenToToken(ERC20(fromAddress), amount, knc, minRate);
    }

    /*
     * @notice Returns ETH balance belonging to the fund
     */
    function getFundEthBalanceWei() public view returns (uint256) {
        return address(this).balance.sub(withdrawableEthFees);
    }

    /*
     * @notice Returns KNC balance staked to DAO
     */
    function getFundKncBalanceTwei() public view returns (uint256) {
        return kyberStaking.getLatestStakeBalance(address(this));
    }

    /*
     * @notice Returns KNC balance available to stake
     */
    function getAvailableKncBalanceTwei() public view returns (uint256) {
        return knc.balanceOf(address(this)).sub(withdrawableKncFees);
    }

    function _administerEthFee(FeeTypes _type, uint256 ethBalBefore)
        private
        returns (uint256 fee)
    {
        uint256 feeRate = getFeeRate(_type);
        if (feeRate == 0) return 0;

        fee = (getFundEthBalanceWei().sub(ethBalBefore)).div(feeRate);
        withdrawableEthFees = withdrawableEthFees.add(fee);
    }

    function _administerKncFee(uint256 _kncAmount, FeeTypes _type)
        private
        returns (uint256 fee)
    {
        uint256 feeRate = getFeeRate(_type);
        if (feeRate == 0) return 0;

        fee = _kncAmount.div(feeRate);
        withdrawableKncFees = withdrawableKncFees.add(fee);
    }

    function getFeeRate(FeeTypes _type) public view returns (uint256) {
        if (_type == FeeTypes.MINT) return feeDivisors.mintFee;
        if (_type == FeeTypes.BURN) return feeDivisors.burnFee;
        if (_type == FeeTypes.CLAIM) return feeDivisors.claimFee;
    }

    /* UTILS */

    /*
     * @notice Called by admin on deployment for KNC
     * @dev Approves Kyber Proxy contract to trade KNC
     * @param Token to approve on proxy contract
     * @param Pass _reset as true if resetting allowance to zero
     */
    function approveKyberProxyContract(address _token, bool _reset)
        external
        onlyOwnerOrManager
    {
        _approveKyberProxyContract(_token, _reset);
    }

    function _approveKyberProxyContract(address _token, bool _reset) private {
        uint256 amount = _reset ? 0 : MAX_UINT;
        IERC20(_token).approve(address(kyberProxy), amount);
    }

    /*
     * @notice Called by admin on deployment
     * @dev (1 / feeDivisor) = % fee on mint, burn, ETH claims
     * @dev ex: A feeDivisor of 334 suggests a fee of 0.3%
     * @param feeDivisors[mint, burn, claim]:
     */
    function setFeeDivisors(
        uint256 _mintFee,
        uint256 _burnFee,
        uint256 _claimFee
    ) external onlyOwner {
        _setFeeDivisors(_mintFee, _burnFee, _claimFee);
    }

    function _setFeeDivisors(
        uint256 _mintFee,
        uint256 _burnFee,
        uint256 _claimFee
    ) private {
        require(
            _mintFee >= 100 || _mintFee == 0,
            "Mint fee must be zero or equal to or less than 1%"
        );
        require(_burnFee >= 100, "Burn fee must be equal to or less than 1%");
        require(_claimFee >= 10, "Claim fee must be less than 10%");
        feeDivisors.mintFee = _mintFee;
        feeDivisors.burnFee = _burnFee;
        feeDivisors.claimFee = _claimFee;

        emit FeeDivisorsSet(_mintFee, _burnFee, _claimFee);
    }

    function withdrawFees() external onlyOwner {
        uint256 ethFees = withdrawableEthFees;
        uint256 kncFees = withdrawableKncFees;

        withdrawableEthFees = 0;
        withdrawableKncFees = 0;

        (bool success, ) = msg.sender.call.value(ethFees)("");
        require(success, "Burn transfer failed");

        knc.safeTransfer(owner(), kncFees);
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    function setManager2(address _manager2) external onlyOwner {
        manager2 = _manager2;
    }

    function pause() external onlyOwnerOrManager {
        _pause();
    }

    function unpause() external onlyOwnerOrManager {
        _unpause();
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
                msg.sender == manager ||
                msg.sender == manager2,
            "Non-admin caller"
        );
        _;
    }

    /*
     * @notice Fallback to accommodate claimRewards function
     */
    receive() external payable {
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }

    function migrateV3(
        address _newKnc,
        IKyberDAO _newKyberDao,
        IKyberStaking _newKyberStaking,
        IRewardsDistributor _rewardsDistributor
    ) external onlyOwnerOrManager {
        require(!v3Initialized, "Initialized already");
        v3Initialized = true;

        _withdraw(getFundKncBalanceTwei());
        knc.approve(_newKnc, MAX_UINT);
        INewKNC(_newKnc).mintWithOldKnc(knc.balanceOf(address(this)));

        knc = ERC20(_newKnc);
        kyberDao = _newKyberDao;
        kyberStaking = _newKyberStaking;
        rewardsDistributor = _rewardsDistributor;

        knc.approve(address(kyberStaking), MAX_UINT);
        _deposit(getAvailableKncBalanceTwei());
    }

    function setRewardsDistributor(IRewardsDistributor _rewardsDistributor) external onlyOwner {
        rewardsDistributor = _rewardsDistributor;
    }

    function getRewardDistributor() external view returns(IRewardsDistributor){
        return rewardsDistributor;
    }
}