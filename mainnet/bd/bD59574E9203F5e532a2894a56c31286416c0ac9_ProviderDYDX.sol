// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface IWethERC20 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

interface SoloMarginContract {
  struct Info {
    address owner;
    uint256 number;
  }

  struct Price {
    uint256 value;
  }

  struct Value {
    uint256 value;
  }

  struct Rate {
    uint256 value;
  }

  enum ActionType { Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call }

  enum AssetDenomination { Wei, Par }

  enum AssetReference { Delta, Target }

  struct AssetAmount {
    bool sign;
    AssetDenomination denomination;
    AssetReference ref;
    uint256 value;
  }

  struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
  }

  struct Wei {
    bool sign;
    uint256 value;
  }

  function operate(Info[] calldata _accounts, ActionArgs[] calldata _actions) external;

  function getAccountWei(Info calldata _account, uint256 _marketId)
    external
    view
    returns (Wei memory);

  function getNumMarkets() external view returns (uint256);

  function getMarketTokenAddress(uint256 _marketId) external view returns (address);

  function getAccountValues(Info memory _account)
    external
    view
    returns (Value memory, Value memory);

  function getMarketInterestRate(uint256 _marketId) external view returns (Rate memory);
}

contract HelperFunct {
  /**
   * @dev get Dydx Solo Address
   */
  function getDydxAddress() public pure returns (address addr) {
    addr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
  }

  /**
   * @dev get WETH address
   */
  function getWETHAddr() public pure returns (address weth) {
    weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  }

  /**
   * @dev Return ethereum address
   */
  function _getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  /**
   * @dev Get Dydx Market ID from token Address
   */
  function _getMarketId(SoloMarginContract _solo, address _token)
    internal
    view
    returns (uint256 _marketId)
  {
    uint256 markets = _solo.getNumMarkets();
    address token = _token == _getEthAddr() ? getWETHAddr() : _token;
    bool check = false;
    for (uint256 i = 0; i < markets; i++) {
      if (token == _solo.getMarketTokenAddress(i)) {
        _marketId = i;
        check = true;
        break;
      }
    }
    require(check, "DYDX Market doesnt exist!");
  }

  /**
   * @dev Get Dydx Acccount arg
   */
  function _getAccountArgs() internal view returns (SoloMarginContract.Info[] memory) {
    SoloMarginContract.Info[] memory accounts = new SoloMarginContract.Info[](1);
    accounts[0] = (SoloMarginContract.Info(address(this), 0));
    return accounts;
  }

  /**
   * @dev Get Dydx Actions args.
   */
  function _getActionsArgs(
    uint256 _marketId,
    uint256 _amt,
    bool _sign
  ) internal view returns (SoloMarginContract.ActionArgs[] memory) {
    SoloMarginContract.ActionArgs[] memory actions = new SoloMarginContract.ActionArgs[](1);
    SoloMarginContract.AssetAmount memory amount =
      SoloMarginContract.AssetAmount(
        _sign,
        SoloMarginContract.AssetDenomination.Wei,
        SoloMarginContract.AssetReference.Delta,
        _amt
      );
    bytes memory empty;
    SoloMarginContract.ActionType action =
      _sign ? SoloMarginContract.ActionType.Deposit : SoloMarginContract.ActionType.Withdraw;
    actions[0] = SoloMarginContract.ActionArgs(
      action,
      0,
      amount,
      _marketId,
      0,
      address(this),
      0,
      empty
    );
    return actions;
  }
}

contract ProviderDYDX is IProvider, HelperFunct {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  bool public donothing = true;

  //Provider Core Functions

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset: token address to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());
      tweth.deposit{ value: _amount }();
      tweth.approve(getDydxAddress(), _amount);
    } else {
      IWethERC20 tweth = IWethERC20(_asset);
      tweth.approve(getDydxAddress(), _amount);
    }

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, true));
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset: token address to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, false));

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());

      tweth.approve(address(tweth), _amount);

      tweth.withdraw(_amount);
    }
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, false));

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());

      tweth.approve(address(_asset), _amount);

      tweth.withdraw(_amount);
    }
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to payback.
   */
  function payback(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());
      tweth.deposit{ value: _amount }();
      tweth.approve(getDydxAddress(), _amount);
    } else {
      IWethERC20 tweth = IWethERC20(_asset);
      tweth.approve(getDydxAddress(), _amount);
    }

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, true));
  }

  /**
   * @dev Returns the current borrowing rate (APR) of a ETH/ERC20_Token, in ray(1e27).
   * @param _asset: token address to query the current borrowing rate.
   */
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);

    SoloMarginContract.Rate memory _rate = dydxContract.getMarketInterestRate(marketId);

    return (_rate.value).mul(1e9).mul(365 days);
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Info memory account =
      SoloMarginContract.Info({ owner: msg.sender, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);

    return structbalance.value;
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   * @param _who: address of the account.
   */
  function getBorrowBalanceOf(address _asset, address _who) external override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Info memory account = SoloMarginContract.Info({ owner: _who, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);

    return structbalance.value;
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getDepositBalance(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);

    SoloMarginContract.Info memory account =
      SoloMarginContract.Info({ owner: msg.sender, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);

    return structbalance.value;
  }
}

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

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library UniERC20 {
  using SafeERC20 for IERC20;

  IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0);

  function isETH(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
  }

  function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
    if (isETH(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function uniTransfer(
    IERC20 token,
    address payable to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (isETH(token)) {
        to.transfer(amount);
      } else {
        token.safeTransfer(to, amount);
      }
    }
  }

  function uniApprove(
    IERC20 token,
    address to,
    uint256 amount
  ) internal {
    require(!isETH(token), "Approve called on ETH");

    if (amount == 0) {
      token.safeApprove(to, 0);
    } else {
      uint256 allowance = token.allowance(address(this), to);
      if (allowance < amount) {
        if (allowance > 0) {
          token.safeApprove(to, 0);
        }
        token.safeApprove(to, amount);
      }
    }
  }
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

pragma solidity >=0.4.25 <0.7.0;

interface IProvider {
  //Basic Core Functions

  function deposit(address _collateralAsset, uint256 _collateralAmount) external payable;

  function borrow(address _borrowAsset, uint256 _borrowAmount) external payable;

  function withdraw(address _collateralAsset, uint256 _collateralAmount) external payable;

  function payback(address _borrowAsset, uint256 _borrowAmount) external payable;

  // returns the borrow annualized rate for an asset in ray (1e27)
  //Example 8.5% annual interest = 0.085 x 10^27 = 85000000000000000000000000 or 85*(10**24)
  function getBorrowRateFor(address _asset) external view returns (uint256);

  function getBorrowBalance(address _asset) external view returns (uint256);

  function getDepositBalance(address _asset) external view returns (uint256);

  function getBorrowBalanceOf(address _asset, address _who) external returns (uint256);
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

