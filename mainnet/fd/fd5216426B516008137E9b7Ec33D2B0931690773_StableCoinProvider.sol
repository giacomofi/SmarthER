// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

pragma solidity 0.8.9;

import "../core/AddressProvider.sol";

/**
 * @notice Contract module which provides access control mechanism, where
 * the governor account is granted with exclusive access to specific functions.
 * @dev Uses the AddressProvider to get the governor
 */
abstract contract Governable {
    IAddressProvider public constant addressProvider = IAddressProvider(0xfbA0816A81bcAbBf3829bED28618177a2bf0e82A);

    /// @dev Throws if called by any account other than the governor.
    modifier onlyGovernor() {
        require(msg.sender == addressProvider.governor(), "not-governor");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/core/IAddressProvider.sol";

contract AddressProvider is IAddressProvider, Initializable {
    /// @notice The governor account
    address public governor;

    /// @notice The proposed governor account. Becomes the new governor after acceptance
    address public proposedGovernor;

    /// @notice The PriceProvidersAggregator contract
    IPriceProvidersAggregator public override providersAggregator;

    /// @notice The StableCoinProvider contract
    IStableCoinProvider public override stableCoinProvider;

    /// @notice Emitted when providers aggregator is updated
    event ProvidersAggregatorUpdated(
        IPriceProvidersAggregator oldProvidersAggregator,
        IPriceProvidersAggregator newProvidersAggregator
    );

    /// @notice Emitted when stable coin provider is updated
    event StableCoinProviderUpdated(
        IStableCoinProvider oldStableCoinProvider,
        IStableCoinProvider newStableCoinProvider
    );

    /// @notice Emitted when governor is updated
    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == msg.sender, "not-governor");
        _;
    }

    function initialize(address governor_) external initializer {
        governor = governor_;
        emit UpdatedGovernor(address(0), governor_);
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(msg.sender == proposedGovernor, "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "proposed-governor-is-zero");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @notice Update PriceProvidersAggregator contract
     */
    function updateProvidersAggregator(IPriceProvidersAggregator providersAggregator_) external onlyGovernor {
        require(address(providersAggregator_) != address(0), "address-is-null");
        emit ProvidersAggregatorUpdated(providersAggregator, providersAggregator_);
        providersAggregator = providersAggregator_;
    }

    /**
     * @notice Update StableCoinProvider contract
     */
    function updateStableCoinProvider(IStableCoinProvider stableCoinProvider_) external onlyGovernor {
        emit StableCoinProviderUpdated(stableCoinProvider, stableCoinProvider_);
        stableCoinProvider = stableCoinProvider_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/OracleHelpers.sol";
import "../interfaces/core/IStableCoinProvider.sol";
import "../features/UsingStalePeriod.sol";
import "../features/UsingMaxDeviation.sol";

/**
 * @title Provide pegged stable coin, useful for getting USD prices reference from DEXes
 * @dev This contract mitigates a de-peg scenario by checking price against two stable coins that should be around 1
 */
contract StableCoinProvider is IStableCoinProvider, UsingStalePeriod, UsingMaxDeviation {
    using OracleHelpers for uint256;

    uint256 public constant USD_DECIMALS = 18;
    uint256 public constant ONE_USD = 10**USD_DECIMALS;

    /**
     * @notice A stable coin to use as USD price reference
     * @dev Should not be called directly from other contracts, must use `getStableCoinIfPegged`
     */
    address public primaryStableCoin;
    uint8 private __primaryStableCoinDecimals;

    /**
     * @notice A secondary stable coin used to check USD-peg against primary
     * @dev Should not be called directly from other contracts, must use `getStableCoinIfPegged`
     */
    address public secondaryStableCoin;
    uint8 private __secondaryStableCoinDecimals;

    /// @notice Emitted when stable coin is updated
    event StableCoinsUpdated(
        address oldPrimaryStableCoin,
        address oldSecondaryStableCoin,
        address newPrimaryStableCoin,
        address newSecondaryStableCoin
    );

    constructor(
        address primaryStableCoin_,
        address secondaryStableCoin_,
        uint256 stalePeriod_,
        uint256 maxDeviation_
    ) UsingStalePeriod(stalePeriod_) UsingMaxDeviation(maxDeviation_) {
        _updateStableCoins(primaryStableCoin_, secondaryStableCoin_);
    }

    /// @inheritdoc IStableCoinProvider
    function getStableCoinIfPegged() external view returns (address _stableCoin) {
        // Note: Chainlink supports DAI/USDC/USDT on all chains that we're using
        IPriceProvider _chainlink = addressProvider.providersAggregator().priceProviders(DataTypes.Provider.CHAINLINK);

        (uint256 _priceInUsd, uint256 _lastUpdatedAt) = _chainlink.getPriceInUsd(primaryStableCoin);

        if (!_priceIsStale(primaryStableCoin, _lastUpdatedAt) && _isDeviationOK(_priceInUsd, ONE_USD)) {
            return primaryStableCoin;
        }

        (_priceInUsd, _lastUpdatedAt) = _chainlink.getPriceInUsd(secondaryStableCoin);

        require(
            !_priceIsStale(secondaryStableCoin, _lastUpdatedAt) && _isDeviationOK(_priceInUsd, ONE_USD),
            "stable-prices-invalid"
        );

        return secondaryStableCoin;
    }

    /// @inheritdoc IStableCoinProvider
    function toUsdRepresentation(uint256 stableCoinAmount_) external view returns (uint256 _usdAmount) {
        uint256 _stableCoinDecimals = __primaryStableCoinDecimals;
        if (_stableCoinDecimals == USD_DECIMALS) {
            return stableCoinAmount_;
        }
        _usdAmount = stableCoinAmount_.scaleDecimal(_stableCoinDecimals, USD_DECIMALS);
    }

    /**
     * @notice Update the stable coin keeping correct decimals value
     * @dev Must have both as set or null
     */
    function _updateStableCoins(address primaryStableCoin_, address secondaryStableCoin_) private {
        require(primaryStableCoin_ != address(0) && secondaryStableCoin_ != address(0), "stable-coins-are-null");
        require(primaryStableCoin_ != secondaryStableCoin_, "stable-coins-are-the-same");

        // Update both
        primaryStableCoin = primaryStableCoin_;
        secondaryStableCoin = secondaryStableCoin_;
        __primaryStableCoinDecimals = IERC20Metadata(primaryStableCoin_).decimals();
        __secondaryStableCoinDecimals = IERC20Metadata(secondaryStableCoin_).decimals();
    }

    /**
     * @notice Update stable coin
     * @dev Used externally by the governor
     */
    function updateStableCoins(address primaryStableCoin_, address secondaryStableCoin_) external onlyGovernor {
        emit StableCoinsUpdated(primaryStableCoin, secondaryStableCoin, primaryStableCoin_, secondaryStableCoin_);
        _updateStableCoins(primaryStableCoin_, secondaryStableCoin_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Deviation check feature, useful when checking prices from different providers for the same asset
 */
abstract contract UsingMaxDeviation is Governable {
    /**
     * @notice The max acceptable deviation
     * @dev 18-decimals scale (e.g 1e17 = 10%)
     */
    uint256 public maxDeviation;

    /// @notice Emitted when max deviation is updated
    event MaxDeviationUpdated(uint256 oldMaxDeviation, uint256 newMaxDeviation);

    constructor(uint256 maxDeviation_) {
        maxDeviation = maxDeviation_;
    }

    /**
     * @notice Update max deviation
     */
    function updateMaxDeviation(uint256 maxDeviation_) external onlyGovernor {
        emit MaxDeviationUpdated(maxDeviation, maxDeviation_);
        maxDeviation = maxDeviation_;
    }

    /**
     * @notice Check if two numbers deviation is acceptable
     */
    function _isDeviationOK(uint256 a_, uint256 b_) internal view returns (bool) {
        uint256 _deviation = a_ > b_ ? ((a_ - b_) * 1e18) / a_ : ((b_ - a_) * 1e18) / b_;
        return _deviation <= maxDeviation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../access/Governable.sol";

/**
 * @title Stale price check feature, useful when checking if prices are fresh enough
 */
abstract contract UsingStalePeriod is Governable {
    /// @notice The default stale period. It's used to determine if a price is invalid (i.e. outdated)
    uint256 public defaultStalePeriod;

    /// @notice Custom stale period, used for token that has different stale window (e.g. some stable coins have 24h window)
    mapping(address => uint256) customStalePeriod;

    /// @notice Emitted when custom stale period is updated
    event CustomStalePeriodUpdated(address token, uint256 oldStalePeriod, uint256 newStalePeriod);

    /// @notice Emitted when default stale period is updated
    event DefaultStalePeriodUpdated(uint256 oldStalePeriod, uint256 newStalePeriod);

    constructor(uint256 defaultStalePeriod_) {
        defaultStalePeriod = defaultStalePeriod_;
    }

    /**
     * @notice Get stale period of a token
     */
    function stalePeriodOf(address token_) public view returns (uint256 _stalePeriod) {
        _stalePeriod = customStalePeriod[token_];
        if (_stalePeriod == 0) {
            _stalePeriod = defaultStalePeriod;
        }
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @dev Uses default stale period
     * @param timeOfLastUpdate_ The price timestamp
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(address token_, uint256 timeOfLastUpdate_) internal view returns (bool) {
        return _priceIsStale(timeOfLastUpdate_, stalePeriodOf(token_));
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @param timeOfLastUpdate_ The price timestamp
     * @param stalePeriod_ The maximum acceptable outdated period
     * @return true if price is stale (outdated)
     */
    function _priceIsStale(uint256 timeOfLastUpdate_, uint256 stalePeriod_) internal view returns (bool) {
        return block.timestamp - timeOfLastUpdate_ > stalePeriod_;
    }

    /**
     * @notice Update custom stale period
     * @dev Use `0` as `stalePeriod_` to remove custom stale period
     */
    function updateCustomStalePeriod(address token_, uint256 stalePeriod_) external onlyGovernor {
        require(token_ != address(0), "token-is-null");
        emit CustomStalePeriodUpdated(token_, customStalePeriod[token_], stalePeriod_);
        if (stalePeriod_ > 0) {
            customStalePeriod[token_] = stalePeriod_;
        } else {
            delete customStalePeriod[token_];
        }
    }

    /**
     * @notice Update default stale period
     */
    function updateDefaultStalePeriod(uint256 stalePeriod_) external onlyGovernor {
        emit DefaultStalePeriodUpdated(defaultStalePeriod, stalePeriod_);
        defaultStalePeriod = stalePeriod_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IStableCoinProvider.sol";
import "./IPriceProvidersAggregator.sol";

interface IAddressProvider {
    function governor() external view returns (address);

    function providersAggregator() external view returns (IPriceProvidersAggregator);

    function stableCoinProvider() external view returns (IStableCoinProvider);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceProvider {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     * @return _lastUpdatedAt Last updated timestamp
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _tokenInLastUpdatedAt Last updated timestamp of `tokenIn_`
     * @return _tokenOutLastUpdatedAt Last updated timestamp of `tokenOut_`
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        );

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteTokenToUsd(address token_, uint256 amountIn_)
        external
        view
        returns (uint256 amountOut_, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteUsdToToken(address token_, uint256 amountIn_)
        external
        view
        returns (uint256 _amountOut, uint256 _lastUpdatedAt);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../libraries/DataTypes.sol";
import "./IPriceProvider.sol";

/**
 * @notice PriceProvidersAggregator interface
 * @dev Worth noting that the `_lastUpdatedAt` logic depends on the underlying price provider. In summary:
 * ChainLink: returns the last updated date from the aggregator
 * UniswapV2: returns the date of the latest pair oracle update
 * UniswapV3: assumes that the price is always updated (returns block.timestamp)
 * Flux: returns the last updated date from the aggregator
 * Umbrella (FCD): returns the last updated date returned from their oracle contract
 * Umbrella (Passport): returns the date of the latest pallet submission
 * Anytime that a quote performs more than one query, it uses the oldest date as the `_lastUpdatedAt`.
 * See more: https://github.com/bloqpriv/one-oracle/issues/64
 */
interface IPriceProvidersAggregator {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param provider_ The price provider to get quote from
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     * @return _lastUpdatedAt Last updated timestamp
     */
    function getPriceInUsd(DataTypes.Provider provider_, address token_)
        external
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /**
     * @notice Provider Providers' mapping
     */
    function priceProviders(DataTypes.Provider provider_) external view returns (IPriceProvider _priceProvider);

    /**
     * @notice Get quote
     * @param provider_ The price provider to get quote from
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _tokenInLastUpdatedAt Last updated timestamp of `tokenIn_`
     * @return _tokenOutLastUpdatedAt Last updated timestamp of `tokenOut_`
     */
    function quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        );

    /**
     * @notice Get quote
     * @dev If providers aren't the same, uses native token as "bridge"
     * @param providerIn_ The price provider to get quote for the tokenIn
     * @param tokenIn_ The address of assetIn
     * @param providerOut_ The price provider to get quote for the tokenOut
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _tokenInLastUpdatedAt Last updated timestamp of `tokenIn_`
     * @return _nativeTokenLastUpdatedAt Last updated timestamp of native token (i.e. WETH) used when providers aren't the same
     * @return _tokenOutLastUpdatedAt Last updated timestamp of `tokenOut_`
     */
    function quote(
        DataTypes.Provider providerIn_,
        address tokenIn_,
        DataTypes.Provider providerOut_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        view
        returns (
            uint256 _amountOut,
            uint256 _tokenInLastUpdatedAt,
            uint256 _nativeTokenLastUpdatedAt,
            uint256 _tokenOutLastUpdatedAt
        );

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param provider_ The price provider to get quote from
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteTokenToUsd(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view returns (uint256 amountOut_, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param provider_ The price provider to get quote from
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteUsdToToken(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Set a price provider
     * @dev Administrative function
     * @param provider_ The provider (from enum)
     * @param priceProvider_ The price provider contract
     */
    function setPriceProvider(DataTypes.Provider provider_, IPriceProvider priceProvider_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStableCoinProvider {
    /**
     * @notice Return the stable coin if pegged
     * @dev Check price relation between both stable coins and revert if peg is too loose
     * @return _stableCoin The primary stable coin if pass all checks
     */
    function getStableCoinIfPegged() external view returns (address _stableCoin);

    /**
     * @notice Convert given amount of stable coin to USD representation (18 decimals)
     */
    function toUsdRepresentation(uint256 stableCoinAmount_) external view returns (uint256 _usdAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library DataTypes {
    /**
     * @notice Price providers enumeration
     */
    enum Provider {
        NONE,
        CHAINLINK,
        UNISWAP_V3,
        UNISWAP_V2,
        SUSHISWAP,
        TRADERJOE,
        PANGOLIN,
        QUICKSWAP,
        UMBRELLA_FIRST_CLASS,
        UMBRELLA_PASSPORT,
        FLUX
    }

    enum ExchangeType {
        UNISWAP_V2,
        SUSHISWAP,
        TRADERJOE,
        PANGOLIN,
        QUICKSWAP,
        UNISWAP_V3,
        PANCAKE_SWAP
    }

    enum SwapType {
        EXACT_INPUT,
        EXACT_OUTPUT
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

library OracleHelpers {
    function scaleDecimal(
        uint256 amount,
        uint256 _fromDecimal,
        uint256 _toDecimal
    ) internal pure returns (uint256) {
        if (_fromDecimal > _toDecimal) {
            return amount / (10**(_fromDecimal - _toDecimal));
        } else if (_fromDecimal < _toDecimal) {
            return amount * (10**(_toDecimal - _fromDecimal));
        }
        return amount;
    }
}