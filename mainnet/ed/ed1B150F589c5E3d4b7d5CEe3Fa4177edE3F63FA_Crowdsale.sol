// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './Structs.sol';

contract Crowdsale is Ownable, Pausable {
  using SafeERC20 for IERC20;

  // ========================================
  // State variables
  // ========================================

  uint8 internal constant ETH_DECIMALS = 18;
  uint256 internal constant USD_PRICE = 100000000;

  // Constant contract configuration
  CrowdsaleBaseConfig internal config;

  // Amount of tokens sold during SALE phase
  // and not yet claimed
  uint256 public locked;

  // Amounts of tokens each address bought
  // and that are not yet claimed
  mapping(address => uint256) public balance;

  // Amounts of tokens each address bought
  mapping(address => uint256) public maxBalance;

  // Events
  event Buy(address indexed from, uint256 indexed value);
  event Claim(address indexed from, uint256 indexed value);

  // ========================================
  // Constructor
  // ========================================

  constructor(CrowdsaleBaseConfig memory _config) {
    // Copy config from memory to storage
    _initializeConfig(_config);
  }

  // ========================================
  // Main functions
  // ========================================

  // Transfer ETH and receive tokens in exchange
  receive() external payable {
    _buy(msg.value, false);
  }

  // Transfer Stablecoin and receive tokens in exchange
  function buyForUSD(uint256 value) external {
    _buy(value, true);
  }

  // Main function for buying tokens for both ETH and stable coins
  function _buy(uint256 value, bool stable) internal onlySalePhase whenNotPaused {
    require(value != 0, 'CS: transaction value is zero');

    // match payment decimals
    uint8 decimals = stable ? config.USDDecimals : ETH_DECIMALS;

    // Fetch current price for ETH or use 1 for stablecoins
    uint256 price = stable ? USD_PRICE : _currentEthPrice();

    // // Make sure tx value does not exceed max value in USD
    // require(
    //   _toUsd(value, price, decimals) <= config.maxUsdValue,
    //   'CS: transaction value exceeds maximal value in usd'
    // );

    // Calculate how many tokens to send in exchange
    uint256 tokens = _calculateTokenAmount(
      value,
      price,
      config.rate,
      config.tokenDecimals,
      decimals
    );

    // Stop if there is nothing to send
    require(tokens > 0, 'CS: token amount is zero');

    // Make sure there is enough tokens on contract address
    // and that is does not use tokens owned by previous buyers
    uint256 availableTokens = _tokenBalance() - locked;
    require(availableTokens >= tokens, 'CS: not enough tokens on sale');

    // If stablecoin is used, transfer coins from buyer to crowdsale
    if (stable) {
      config.USD.safeTransferFrom(msg.sender, address(this), value);
    }

    // Update balances
    balance[msg.sender] += tokens;
    maxBalance[msg.sender] += tokens;
    locked += tokens;

    emit Buy(msg.sender, tokens);
  }

  // Claim tokens in vesting stages
  function claim(uint256 value) external onlyVestingPhase whenNotPaused {
    require(balance[msg.sender] != 0, 'CS: sender has 0 tokens');
    require(balance[msg.sender] >= value, 'CS: not enough tokens');

    // Disallow to claim more tokens than current unlocked percentage
    // Ex Allow to claim 50% of tokens after 3 months
    require(value <= _maxTokensToUnlock(msg.sender), 'CS: value exceeds unlocked percentage');

    // Transfer tokens to user
    config.token.safeTransfer(msg.sender, value);

    // Update balances
    balance[msg.sender] -= value;
    locked -= value;

    emit Claim(msg.sender, value);
  }

  // ========================================
  // Public views
  // ========================================

  // Fetch configuration object
  function configuration() external view returns (CrowdsaleBaseConfig memory) {
    return _configuration();
  }

  // Fetch current price from price feed
  function currentEthPrice() external view returns (uint256) {
    return _currentEthPrice();
  }

  function tokenBalance() external view returns (uint256) {
    return _tokenBalance();
  }

  // Amount of unlocked tokens on contract
  function freeBalance() external view returns (uint256) {
    return _freeBalance();
  }

  // What percent of tokens can be claim at current time
  function unlockedPercentage() external view returns (uint256) {
    return _calculateUnlockedPercentage(config.stages, block.timestamp);
  }

  // How many tokens can be bought for selected ETH value
  function calculateTokenAmountForETH(uint256 value) external view returns (uint256) {
    return
      _calculateTokenAmount(
        value,
        _currentEthPrice(),
        config.rate,
        config.tokenDecimals,
        ETH_DECIMALS
      );
  }

    // How many tokens can be bought for selected ETH value
  function calculateTokenAmountForUSD(uint256 value) external view returns (uint256) {
    return
      _calculateTokenAmount(
        value,
        USD_PRICE,
        config.rate,
        config.tokenDecimals,
        config.USDDecimals
      );
  }

  // What tx value of ETH is needed to buy selected amount of tokens
  function calculatePaymentForETH(uint256 tokens) external view returns (uint256) {
    return
      _calculatePayment(
        tokens,
        _currentEthPrice(),
        config.rate,
        config.tokenDecimals,
        ETH_DECIMALS
      );
  }

    // What value of USD is needed to buy selected amount of tokens
  function calculatePaymentForUSD(uint256 tokens) external view returns (uint256) {
    return
      _calculatePayment(
        tokens,
        USD_PRICE,
        config.rate,
        config.tokenDecimals,
        config.USDDecimals
      );
  }

  // Maximal amount of tokens user can claim at current time
  function maxTokensToUnlock(address sender) external view returns (uint256) {
    return _maxTokensToUnlock(sender);
  }

  // ========================================
  // Owner utilities
  // ========================================

  // Used to send ETH to contract from owner
  function fund() external payable onlyOwner {}

  // Use to withdraw eth
  function transferEth(address payable to, uint256 value) external onlyOwner {
    to.transfer(value);
  }

  // Owner function used to withdraw tokens
  // Disallows to claim tokens belonging to other addresses
  function transferToken(address to, uint256 value) external onlyOwner {
    uint256 free = _tokenBalance() - locked;

    require(value <= free, 'CS: value exceeds locked value');

    config.token.safeTransfer(to, value);
  }

  // OWner utility function
  // Use in case other token is send to contract address
  function transferOtherToken(
    IERC20 otherToken,
    address to,
    uint256 value
  ) external onlyOwner {
    require(config.token != otherToken, 'CS: invalid token address');

    otherToken.safeTransfer(to, value);
  }

  // OWner utility function
  function pause() external onlyOwner {
    _pause();
  }

  // OWner utility function
  function unpause() external onlyOwner {
    _unpause();
  }

  // ========================================
  // Internals
  // ========================================

  function _tokenBalance() internal view returns (uint256) {
    return config.token.balanceOf(address(this));
  }

  function _freeBalance() internal view returns (uint256) {
    return _tokenBalance() - locked;
  }

  function _currentEthPrice() internal view returns (uint256) {
    (, int256 answer, , , ) = config.priceFeed.latestRoundData();
    return uint256(answer);
  }

  function _maxTokensToUnlock(address sender) internal view returns (uint256) {
    uint256 percentage = _calculateUnlockedPercentage(config.stages, block.timestamp);
    uint256 unlocked = _calculateMaxTokensToUnlock(balance[sender], maxBalance[sender], percentage);

    return unlocked;
  }

  function _calculateTokenAmount(
    uint256 value,
    uint256 price,
    uint256 rate,
    uint8 tokenDecimals,
    uint8 paymentDecimals
  ) internal pure returns (uint256) {
    return (price * value * uint256(10)**tokenDecimals) / rate / uint256(10)**paymentDecimals;
  }

  function _calculatePayment(
    uint256 tokens,
    uint256 price,
    uint256 rate,
    uint8 tokenDecimals,
    uint8 paymentDecimals
  ) internal pure returns (uint256) {
    return (tokens * rate * uint256(10)**paymentDecimals) / uint256(10)**tokenDecimals / price;
  }

  function _toUsd(
    uint256 value,
    uint256 price,
    uint8 paymentDecimals
  ) internal pure returns (uint256) {
    return (price * value) / uint256(10)**paymentDecimals;
  }

  function _calculateMaxTokensToUnlock(
    uint256 _balance,
    uint256 _maxBalance,
    uint256 _percentage
  ) internal pure returns (uint256) {
    if (_percentage == 0) return 0;
    if (_percentage >= 100) return _balance;

    uint256 maxTotal = (_maxBalance * _percentage) / 100;
    return maxTotal - (_maxBalance - _balance);
  }

  function _calculateUnlockedPercentage(Stage[] memory stages, uint256 currentTimestamp)
    internal
    pure
    returns (uint256)
  {
    // Allow to claim all if there are no stages
    if (stages.length == 0) return 100;

    uint256 unlocked = 0;

    for (uint256 i = 0; i < stages.length; i++) {
      if (currentTimestamp >= stages[i].timestamp) {
        unlocked = stages[i].percent;
      } else {
        break;
      }
    }

    return unlocked;
  }

  // Copy array of structs from storage to memory
  function _configuration() internal view returns (CrowdsaleBaseConfig memory) {
    CrowdsaleBaseConfig memory _config = config;
    Stage[] memory _stages = new Stage[](config.stages.length);

    for (uint8 i = 0; i < config.stages.length; i++) {
      _stages[i] = config.stages[i];
    }

    _config.stages = _stages;
    return _config;
  }

  // Copy array of structs from memory to storage
  function _initializeConfig(CrowdsaleBaseConfig memory _config) internal {
    config.token = _config.token;
    config.tokenDecimals = _config.tokenDecimals;
    config.USD = _config.USD;
    config.USDDecimals = _config.USDDecimals;
    config.rate = _config.rate;
    config.phaseSwitchTimestamp = _config.phaseSwitchTimestamp;
    config.priceFeed = _config.priceFeed;
    config.priceRestrictions = _config.priceRestrictions;
    config.maxUsdValue = _config.maxUsdValue;

    for (uint256 i = 0; i < _config.stages.length; i++) {
      config.stages.push(_config.stages[i]);
    }
  }

  // ========================================
  // Modifiers
  // ========================================

  // Phase guard
  modifier onlySalePhase() {
    require(block.timestamp < config.phaseSwitchTimestamp, 'CS: invalid phase, expected sale');
    _;
  }

  // Phase guard
  modifier onlyVestingPhase() {
    require(block.timestamp >= config.phaseSwitchTimestamp, 'CS: invalid phase, expected vesting');
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

struct CrowdsaleBaseConfig {
  // ERC20 token being sold address
  IERC20 token;

  // ERC20 token being sold decimals
  uint8 tokenDecimals;

  // Stable coin address
  IERC20 USD;

  // Stable coin decimals
  uint8 USDDecimals;

  // Amount of USD (as 8 decimals integer) for single
  // Ex. rate = 5000000, tokenDecimals = 4 is equal to
  // rate = 0.05 cents for single token (10000 with decimals)
  uint256 rate;

  // Timestamp after which vesting phase is started
  uint256 phaseSwitchTimestamp;

  // Vesting stages, each stage has timestamp and percent of unlocked balance
  Stage[] stages;

  // Address of price feed. It's expected to return current price of ETH with 8 decimals
  AggregatorV3Interface priceFeed;

  // Price restrictions for priceFeed
  PriceRestrictions priceRestrictions;

  // Max value in USD transferred by user when buying tokens
  uint256 maxUsdValue;
}

struct PriceRestrictions {
  // maximal age in seconds of price value received from priceFeed
  uint256 timeDiff;

  // minimal price value
  uint256 minValue;

  // maximal price value
  uint256 maxValue;
}

struct Stage {
  uint256 timestamp;
  uint256 percent;
}

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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