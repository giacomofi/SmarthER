// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    function getOwner() external view returns (address);

    function hasReconfigurationRequest(address) external view returns (bool);

    function isAllowedBuySharesOnBehalfCaller(address) external view returns (bool);

    function isAllowedVaultCall(
        address,
        bytes4,
        bytes32
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IIntegrationManager interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the IntegrationManager
interface IIntegrationManager {
    enum SpendAssetsHandleType {None, Approve, Transfer}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../IIntegrationManager.sol";

/// @title Integration Adapter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all integration adapters
interface IIntegrationAdapter {
    function parseAssetsForAction(
        address _vaultProxy,
        bytes4 _selector,
        bytes calldata _encodedCallArgs
    )
        external
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../infrastructure/price-feeds/derivatives/feeds/AavePriceFeed.sol";
import "../utils/actions/AaveActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title AaveAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Aave Lending <https://aave.com/>
/// @dev When lending and redeeming, a small `ROUNDING_BUFFER` is subtracted from the min incoming asset amount.
/// This is a workaround for problematic quirks in `aToken` balance rounding (due to RayMath and rebasing logic),
/// which would otherwise lead to tx failures during IntegrationManager validation of incoming asset amounts.
/// Due to this workaround, an `aToken` value less than `ROUNDING_BUFFER` is not usable in this adapter,
/// which is fine because those values would not make sense (gas-wise) to lend or redeem.
contract AaveAdapter is AdapterBase, AaveActionsMixin {
    using SafeMath for uint256;

    uint256 private constant ROUNDING_BUFFER = 2;

    address private immutable AAVE_PRICE_FEED;

    constructor(
        address _integrationManager,
        address _lendingPoolAddressProvider,
        address _aavePriceFeed
    ) public AdapterBase(_integrationManager) AaveActionsMixin(_lendingPoolAddressProvider) {
        AAVE_PRICE_FEED = _aavePriceFeed;
    }

    /// @notice Lends an amount of a token to AAVE
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    ) external onlyIntegrationManager {
        (address[] memory spendAssets, uint256[] memory spendAssetAmounts, ) = __decodeAssetData(
            _assetData
        );

        __aaveLend(_vaultProxy, spendAssets[0], spendAssetAmounts[0]);
    }

    /// @notice Redeems an amount of aTokens from AAVE
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    ) external onlyIntegrationManager {
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __aaveRedeem(_vaultProxy, spendAssets[0], spendAssetAmounts[0], incomingAssets[0]);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address aToken, uint256 amount) = __decodeCallArgs(_actionData);

        // Prevent from invalid token/aToken combination
        address token = AavePriceFeed(AAVE_PRICE_FEED).getUnderlyingForDerivative(aToken);
        require(token != address(0), "__parseAssetsForLend: Unsupported aToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = token;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = amount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = aToken;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = amount.sub(ROUNDING_BUFFER);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address aToken, uint256 amount) = __decodeCallArgs(_actionData);

        // Prevent from invalid token/aToken combination
        address token = AavePriceFeed(AAVE_PRICE_FEED).getUnderlyingForDerivative(aToken);
        require(token != address(0), "__parseAssetsForRedeem: Unsupported aToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = aToken;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = amount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = token;
        minIncomingAssetAmounts_ = new uint256[](1);
        // The `ROUNDING_BUFFER` is overly cautious in this case, but it comes at minimal expense
        minIncomingAssetAmounts_[0] = amount.sub(ROUNDING_BUFFER);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (address aToken, uint256 amount)
    {
        return abi.decode(_actionData, (address, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `AAVE_PRICE_FEED` variable
    /// @return aavePriceFeed_ The `AAVE_PRICE_FEED` variable value
    function getAavePriceFeed() external view returns (address aavePriceFeed_) {
        return AAVE_PRICE_FEED;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../utils/AssetHelpers.sol";
import "../IIntegrationAdapter.sol";
import "./IntegrationSelectors.sol";

/// @title AdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract for integration adapters
abstract contract AdapterBase is IIntegrationAdapter, IntegrationSelectors, AssetHelpers {
    using SafeERC20 for ERC20;

    address internal immutable INTEGRATION_MANAGER;

    /// @dev Provides a standard implementation for transferring incoming assets
    /// from an adapter to a VaultProxy at the end of an adapter action
    modifier postActionIncomingAssetsTransferHandler(
        address _vaultProxy,
        bytes memory _assetData
    ) {
        _;

        (, , address[] memory incomingAssets) = __decodeAssetData(_assetData);

        __pushFullAssetBalances(_vaultProxy, incomingAssets);
    }

    /// @dev Provides a standard implementation for transferring unspent spend assets
    /// from an adapter to a VaultProxy at the end of an adapter action
    modifier postActionSpendAssetsTransferHandler(address _vaultProxy, bytes memory _assetData) {
        _;

        (address[] memory spendAssets, , ) = __decodeAssetData(_assetData);

        __pushFullAssetBalances(_vaultProxy, spendAssets);
    }

    modifier onlyIntegrationManager {
        require(
            msg.sender == INTEGRATION_MANAGER,
            "Only the IntegrationManager can call this function"
        );
        _;
    }

    constructor(address _integrationManager) public {
        INTEGRATION_MANAGER = _integrationManager;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to decode the _assetData param passed to adapter call
    function __decodeAssetData(bytes memory _assetData)
        internal
        pure
        returns (
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_
        )
    {
        return abi.decode(_assetData, (address[], uint256[], address[]));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `INTEGRATION_MANAGER` variable
    /// @return integrationManager_ The `INTEGRATION_MANAGER` variable value
    function getIntegrationManager() external view returns (address integrationManager_) {
        return INTEGRATION_MANAGER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IntegrationSelectors Contract
/// @author Enzyme Council <[email protected]>
/// @notice Selectors for integration actions
/// @dev Selectors are created from their signatures rather than hardcoded for easy verification
abstract contract IntegrationSelectors {
    // Trading
    bytes4 public constant TAKE_ORDER_SELECTOR = bytes4(
        keccak256("takeOrder(address,bytes,bytes)")
    );

    // Lending
    bytes4 public constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 public constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));

    // Staking
    bytes4 public constant STAKE_SELECTOR = bytes4(keccak256("stake(address,bytes,bytes)"));
    bytes4 public constant UNSTAKE_SELECTOR = bytes4(keccak256("unstake(address,bytes,bytes)"));

    // Rewards
    bytes4 public constant CLAIM_REWARDS_SELECTOR = bytes4(
        keccak256("claimRewards(address,bytes,bytes)")
    );

    // Combined
    bytes4 public constant LEND_AND_STAKE_SELECTOR = bytes4(
        keccak256("lendAndStake(address,bytes,bytes)")
    );
    bytes4 public constant UNSTAKE_AND_REDEEM_SELECTOR = bytes4(
        keccak256("unstakeAndRedeem(address,bytes,bytes)")
    );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IAaveLendingPool.sol";
import "../../../../../interfaces/IAaveLendingPoolAddressProvider.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title AaveActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Aave lending functions
abstract contract AaveActionsMixin is AssetHelpers {
    uint16 private constant AAVE_REFERRAL_CODE = 158;

    address private immutable AAVE_LENDING_POOL_ADDRESS_PROVIDER;

    constructor(address _lendingPoolAddressProvider) public {
        AAVE_LENDING_POOL_ADDRESS_PROVIDER = _lendingPoolAddressProvider;
    }

    /// @dev Helper to execute lending
    function __aaveLend(
        address _recipient,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount
    ) internal {
        address lendingPoolAddress = IAaveLendingPoolAddressProvider(
            AAVE_LENDING_POOL_ADDRESS_PROVIDER
        )
            .getLendingPool();

        __approveAssetMaxAsNeeded(_outgoingAsset, lendingPoolAddress, _outgoingAssetAmount);

        IAaveLendingPool(lendingPoolAddress).deposit(
            _outgoingAsset,
            _outgoingAssetAmount,
            _recipient,
            AAVE_REFERRAL_CODE
        );
    }

    /// @dev Helper to execute redeeming
    function __aaveRedeem(
        address _recipient,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        address _incomingAsset
    ) internal {
        address lendingPoolAddress = IAaveLendingPoolAddressProvider(
            AAVE_LENDING_POOL_ADDRESS_PROVIDER
        )
            .getLendingPool();

        __approveAssetMaxAsNeeded(_outgoingAsset, lendingPoolAddress, _outgoingAssetAmount);

        IAaveLendingPool(lendingPoolAddress).withdraw(
            _incomingAsset,
            _outgoingAssetAmount,
            _recipient
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `AAVE_LENDING_POOL_ADDRESS_PROVIDER` variable
    /// @return aaveLendingPoolAddressProvider_ The `AAVE_LENDING_POOL_ADDRESS_PROVIDER` variable value
    function getAaveLendingPoolAddressProvider()
        public
        view
        returns (address aaveLendingPoolAddressProvider_)
    {
        return AAVE_LENDING_POOL_ADDRESS_PROVIDER;
    }

    /// @notice Gets the `AAVE_REFERRAL_CODE` variable
    /// @return aaveReferralCode_ The `AAVE_REFERRAL_CODE` variable value
    function getAaveReferralCode() public pure returns (uint16 aaveReferralCode_) {
        return AAVE_REFERRAL_CODE;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDerivativePriceFeed Interface
/// @author Enzyme Council <[email protected]>
/// @notice Simple interface for derivative price source oracle implementations
interface IDerivativePriceFeed {
    function calcUnderlyingValues(address, uint256)
        external
        returns (address[] memory, uint256[] memory);

    function isSupportedAsset(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../interfaces/IAaveProtocolDataProvider.sol";
import "./utils/PeggedDerivativesPriceFeedBase.sol";

/// @title AavePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Aave
contract AavePriceFeed is PeggedDerivativesPriceFeedBase {
    address private immutable PROTOCOL_DATA_PROVIDER;

    constructor(address _fundDeployer, address _protocolDataProvider)
        public
        PeggedDerivativesPriceFeedBase(_fundDeployer)
    {
        PROTOCOL_DATA_PROVIDER = _protocolDataProvider;
    }

    function __validateDerivative(address _derivative, address _underlying) internal override {
        super.__validateDerivative(_derivative, _underlying);

        (address aTokenAddress, , ) = IAaveProtocolDataProvider(PROTOCOL_DATA_PROVIDER)
            .getReserveTokensAddresses(_underlying);

        require(
            aTokenAddress == _derivative,
            "__validateDerivative: Invalid aToken or token provided"
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `PROTOCOL_DATA_PROVIDER` variable value
    /// @return protocolDataProvider_ The `PROTOCOL_DATA_PROVIDER` variable value
    function getProtocolDataProvider() external view returns (address protocolDataProvider_) {
        return PROTOCOL_DATA_PROVIDER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../IDerivativePriceFeed.sol";
import "./SingleUnderlyingDerivativeRegistryMixin.sol";

/// @title PeggedDerivativesPriceFeedBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed base for multiple derivatives that are pegged 1:1 to their underlyings,
/// and have the same decimals as their underlying
abstract contract PeggedDerivativesPriceFeedBase is
    IDerivativePriceFeed,
    SingleUnderlyingDerivativeRegistryMixin
{
    constructor(address _fundDeployer)
        public
        SingleUnderlyingDerivativeRegistryMixin(_fundDeployer)
    {}

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address underlying = getUnderlyingForDerivative(_derivative);
        require(underlying != address(0), "calcUnderlyingValues: Not a supported derivative");

        underlyings_ = new address[](1);
        underlyings_[0] = underlying;

        underlyingAmounts_ = new uint256[](1);
        underlyingAmounts_[0] = _derivativeAmount;

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return getUnderlyingForDerivative(_asset) != address(0);
    }

    /// @dev Provides validation that the derivative and underlying have the same decimals.
    /// Can be overrode by the inheriting price feed using super() to implement further validation.
    function __validateDerivative(address _derivative, address _underlying)
        internal
        virtual
        override
    {
        require(
            ERC20(_derivative).decimals() == ERC20(_underlying).decimals(),
            "__validateDerivative: Unequal decimals"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../utils/FundDeployerOwnerMixin.sol";

/// @title SingleUnderlyingDerivativeRegistryMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin for derivative price feeds that handle multiple derivatives
/// that each have a single underlying asset
abstract contract SingleUnderlyingDerivativeRegistryMixin is FundDeployerOwnerMixin {
    event DerivativeAdded(address indexed derivative, address indexed underlying);

    event DerivativeRemoved(address indexed derivative);

    mapping(address => address) private derivativeToUnderlying;

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {}

    /// @notice Adds derivatives with corresponding underlyings to the price feed
    /// @param _derivatives The derivatives to add
    /// @param _underlyings The corresponding underlyings to add
    function addDerivatives(address[] memory _derivatives, address[] memory _underlyings)
        external
        virtual
        onlyFundDeployerOwner
    {
        require(_derivatives.length > 0, "addDerivatives: Empty _derivatives");
        require(_derivatives.length == _underlyings.length, "addDerivatives: Unequal arrays");

        for (uint256 i; i < _derivatives.length; i++) {
            require(_derivatives[i] != address(0), "addDerivatives: Empty derivative");
            require(_underlyings[i] != address(0), "addDerivatives: Empty underlying");
            require(
                getUnderlyingForDerivative(_derivatives[i]) == address(0),
                "addDerivatives: Value already set"
            );

            __validateDerivative(_derivatives[i], _underlyings[i]);

            derivativeToUnderlying[_derivatives[i]] = _underlyings[i];

            emit DerivativeAdded(_derivatives[i], _underlyings[i]);
        }
    }

    /// @notice Removes derivatives from the price feed
    /// @param _derivatives The derivatives to remove
    function removeDerivatives(address[] memory _derivatives) external onlyFundDeployerOwner {
        require(_derivatives.length > 0, "removeDerivatives: Empty _derivatives");

        for (uint256 i; i < _derivatives.length; i++) {
            require(
                getUnderlyingForDerivative(_derivatives[i]) != address(0),
                "removeDerivatives: Value not set"
            );

            delete derivativeToUnderlying[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    /// @dev Optionally allow the inheriting price feed to validate the derivative-underlying pair
    function __validateDerivative(address, address) internal virtual {
        // UNIMPLEMENTED
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the underlying asset for a given derivative
    /// @param _derivative The derivative for which to get the underlying asset
    /// @return underlying_ The underlying asset
    function getUnderlyingForDerivative(address _derivative)
        public
        view
        returns (address underlying_)
    {
        return derivativeToUnderlying[_derivative];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveLendingPool interface
/// @author Enzyme Council <[email protected]>
interface IAaveLendingPool {
    function deposit(
        address,
        uint256,
        address,
        uint16
    ) external;

    function withdraw(
        address,
        uint256,
        address
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveLendingPoolAddressProvider interface
/// @author Enzyme Council <[email protected]>
interface IAaveLendingPoolAddressProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveProtocolDataProvider interface
/// @author Enzyme Council <[email protected]>
interface IAaveProtocolDataProvider {
    function getReserveTokensAddresses(address)
        external
        view
        returns (
            address,
            address,
            address
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title AssetHelpers Contract
/// @author Enzyme Council <[email protected]>
/// @notice A util contract for common token actions
abstract contract AssetHelpers {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev Helper to approve a target account with the max amount of an asset.
    /// This is helpful for fully trusted contracts, such as adapters that
    /// interact with external protocol like Uniswap, Compound, etc.
    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        uint256 allowance = ERC20(_asset).allowance(address(this), _target);
        if (allowance < _neededAmount) {
            if (allowance > 0) {
                ERC20(_asset).safeApprove(_target, 0);
            }
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to transfer full asset balances from the current contract to a target
    function __pushFullAssetBalances(address _target, address[] memory _assets)
        internal
        returns (uint256[] memory amountsTransferred_)
    {
        amountsTransferred_ = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            ERC20 assetContract = ERC20(_assets[i]);
            amountsTransferred_[i] = assetContract.balanceOf(address(this));
            if (amountsTransferred_[i] > 0) {
                assetContract.safeTransfer(_target, amountsTransferred_[i]);
            }
        }

        return amountsTransferred_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../core/fund-deployer/IFundDeployer.sol";

/// @title FundDeployerOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract that defers ownership to the owner of FundDeployer
abstract contract FundDeployerOwnerMixin {
    address internal immutable FUND_DEPLOYER;

    modifier onlyFundDeployerOwner() {
        require(
            msg.sender == getOwner(),
            "onlyFundDeployerOwner: Only the FundDeployer owner can call this function"
        );
        _;
    }

    constructor(address _fundDeployer) public {
        FUND_DEPLOYER = _fundDeployer;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the FundDeployer contract
    function getOwner() public view returns (address owner_) {
        return IFundDeployer(FUND_DEPLOYER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FUND_DEPLOYER` variable
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    function getFundDeployer() public view returns (address fundDeployer_) {
        return FUND_DEPLOYER;
    }
}