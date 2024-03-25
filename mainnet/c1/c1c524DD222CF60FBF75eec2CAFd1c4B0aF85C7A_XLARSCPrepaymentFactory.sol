// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/revenue-share-contracts/BaseRSCPrepayment.sol";
import "contracts/revenue-share-contracts/RSCPrepayment.sol";
import "contracts/revenue-share-contracts/RSCPrepaymentUSD.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract XLARSCPrepaymentFactory is Ownable {
    address payable public immutable contractImplementation;
    address payable public immutable contractImplementationUsd;

    uint256 constant version = 1;
    uint256 public platformFee;
    address payable public platformWallet;

    struct RSCCreateData {
        string name;
        address controller;
        address distributor;
        bool immutableController;
        bool autoEthDistribution;
        uint256 minAutoDistributeAmount;
        address payable investor;
        uint256 investedAmount;
        uint256 interestRate;
        uint256 residualInterestRate;
        address payable [] initialRecipients;
        uint256[] percentages;
        string[] names;
        address[] supportedErc20addresses;
        address[] erc20PriceFeeds;
    }

    struct RSCCreateUsdData {
        string name;
        address controller;
        address distributor;
        bool immutableController;
        bool autoEthDistribution;
        uint256 minAutoDistributeAmount;
        address payable investor;
        uint256 investedAmount;
        uint256 interestRate;
        uint256 residualInterestRate;
        address ethUsdPriceFeed;
        address payable [] initialRecipients;
        uint256[] percentages;
        string[] names;
        address[] supportedErc20addresses;
        address[] erc20PriceFeeds;
    }

    event RSCPrepaymentCreated(
        address contractAddress,
        address controller,
        address distributor,
        string name,
        uint256 version,
        bool immutableController,
        bool autoEthDistribution,
        uint256 minAutoDistributeAmount,
        uint256 investedAmount,
        uint256 interestRate,
        uint256 residualInterestRate
    );

    event RSCPrepaymentUsdCreated(
        address contractAddress,
        address controller,
        address distributor,
        string name,
        uint256 version,
        bool immutableController,
        bool autoEthDistribution,
        uint256 minAutoDistributeAmount,
        uint256 investedAmount,
        uint256 interestRate,
        uint256 residualInterestRate,
        address ethUsdPriceFeed
    );

    event PlatformFeeChanged(
        uint256 oldFee,
        uint256 newFee
    );

    event PlatformWalletChanged(
        address payable oldPlatformWallet,
        address payable newPlatformWallet
    );

    constructor() {
        contractImplementation = payable(new XLARSCPrepayment());
        contractImplementationUsd = payable(new XLARSCPrepaymentUsd());
    }

    /**
     * @dev Public function for creating clone proxy pointing to RSC Investor
     * @param _data Initial data for creating new RSC Prepayment ETH contract
     * @return Address of new contract
     */
    function createRSCPrepayment(RSCCreateData memory _data) external returns(address) {
        address payable clone = payable(Clones.clone(contractImplementation));

        BaseRSCPrepayment.InitContractSetting memory contractSettings = BaseRSCPrepayment.InitContractSetting(
            msg.sender,
            _data.distributor,
            _data.controller,
            _data.immutableController,
            _data.autoEthDistribution,
            _data.minAutoDistributeAmount,
            platformFee,
            address(this),
            _data.supportedErc20addresses,
            _data.erc20PriceFeeds
        );

        XLARSCPrepayment(clone).initialize(
            contractSettings,
            _data.investor,
            _data.investedAmount,
            _data.interestRate,
            _data.residualInterestRate,
            _data.initialRecipients,
            _data.percentages,
            _data.names
        );

        emit RSCPrepaymentCreated(
            clone,
            _data.controller,
            _data.distributor,
            _data.name,
            version,
            _data.immutableController,
            _data.autoEthDistribution,
            _data.minAutoDistributeAmount,
            _data.investedAmount,
            _data.interestRate,
            _data.residualInterestRate
        );

        return clone;
    }

    /**
     * @dev Public function for creating clone proxy pointing to RSC Investor
     * @param _data Initial data for creating new RSC Prepayment USD contract
     * @return Address of new contract
     */
    function createRSCPrepaymentUsd(RSCCreateUsdData memory _data) external returns(address) {
        address payable clone = payable(Clones.clone(contractImplementationUsd));

        BaseRSCPrepayment.InitContractSetting memory contractSettings = BaseRSCPrepayment.InitContractSetting(
            msg.sender,
            _data.distributor,
            _data.controller,
            _data.immutableController,
            _data.autoEthDistribution,
            _data.minAutoDistributeAmount,
            platformFee,
            address(this),
            _data.supportedErc20addresses,
            _data.erc20PriceFeeds
        );

        XLARSCPrepaymentUsd(clone).initialize(
            contractSettings,
            _data.investor,
            _data.investedAmount,
            _data.interestRate,
            _data.residualInterestRate,
            _data.ethUsdPriceFeed,
            _data.initialRecipients,
            _data.percentages,
            _data.names
        );

        emit RSCPrepaymentUsdCreated(
            clone,
            _data.controller,
            _data.distributor,
            _data.name,
            version,
            _data.immutableController,
            _data.autoEthDistribution,
            _data.minAutoDistributeAmount,
            _data.investedAmount,
            _data.interestRate,
            _data.residualInterestRate,
            _data.ethUsdPriceFeed
        );

        return clone;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _fee Percentage define platform fee 100% == 10000
     */
    function setPlatformFee(uint256 _fee) external onlyOwner {
        emit PlatformFeeChanged(platformFee, _fee);
        platformFee = _fee;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _platformWallet New ETH wallet which will receive ETH
     */
    function setPlatformWallet(address payable _platformWallet) external onlyOwner {
        emit PlatformWalletChanged(platformWallet, _platformWallet);
        platformWallet = _platformWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IFeeFactory {
    function platformWallet() external returns(address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IFeeFactory.sol";


contract BaseRSCPrepayment is OwnableUpgradeable {
    address public distributor;
    address public controller;
    bool public immutableController;
    bool public autoEthDistribution;
    uint256 public minAutoDistributionAmount;
    uint256 public platformFee;
    IFeeFactory public factory;

    uint256 public interestRate;
    uint256 public residualInterestRate;

    address payable public investor;
    uint256 public investedAmount;
    uint256 public investorAmountToReceive;
    uint256 public investorReceivedAmount;

    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;
    uint256 public numberOfRecipients;

    struct InitContractSetting {
        address owner;
        address distributor;
        address controller;
        bool immutableController;
        bool autoEthDistribution;
        uint256 minAutoDistributionAmount;
        uint256 platformFee;
        address factoryAddress;
        address[] supportedErc20addresses;
        address[] erc20PriceFeeds;
    }

    event SetRecipients(address payable [] recipients, uint256[] percentages, string[] names);
    event DistributeToken(address token, uint256 amount);
    event DistributorChanged(address oldDistributor, address newDistributor);
    event ControllerChanged(address oldController, address newController);

    // Throw when if sender is not distributor
    error OnlyDistributorError();

    // Throw when sender is not controller
    error OnlyControllerError();

    // Throw when transaction fails
    error TransferFailedError();

    // Throw when submitted recipient with address(0)
    error NullAddressRecipientError();

    // Throw if recipient is already in contract
    error RecipientAlreadyAddedError();

    // Throw when arrays are submit without same length
    error InconsistentDataLengthError();

    // Throw when sum of percentage is not 100%
    error InvalidPercentageError();

    // Throw when RSC doesnt have any ERC20 balance for given token
    error Erc20ZeroBalanceError();

    // Throw when distributor address is same as submit one
    error DistributorAlreadyConfiguredError();

    // Throw when distributor address is same as submit one
    error ControllerAlreadyConfiguredError();

    // Throw when change is triggered for immutable controller
    error ImmutableControllerError();

    /**
     * @dev Throws if sender is not distributor
     */
    modifier onlyDistributor {
        if (msg.sender != distributor) {
            revert OnlyDistributorError();
        }
        _;
    }

    /**
     * @dev Checks whether sender is controller
     */
    modifier onlyController {
        if (msg.sender != controller) {
            revert OnlyControllerError();
        }
        _;
    }

    fallback() external payable {
        if (autoEthDistribution && msg.value >= minAutoDistributionAmount) {
            _redistributeEth(msg.value);
        }
    }

    receive() external payable {
        if (autoEthDistribution && msg.value >= minAutoDistributionAmount) {
            _redistributeEth(msg.value);
        }
    }

    /**
     * @notice Internal function to redistribute ETH based on percentages assign to the recipients
     * @param _valueToDistribute ETH amount to be distribute
     */
    function _redistributeEth(uint256 _valueToDistribute) internal virtual {}


    /**
     * @notice External function to redistribute ETH based on percentages assign to the recipients
     */
    function redistributeEth() external onlyDistributor {
        _redistributeEth(address(this).balance);
    }

    /**
     * @notice Internal function to check whether percentages are equal to 100%
     * @return valid boolean indicating whether sum of percentage == 100%
     */
    function _percentageIsValid() internal view returns (bool valid){
        uint256 recipientsLength = recipients.length;
        uint256 percentageSum;

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            percentageSum += recipientsPercentage[recipient];
            unchecked {i++;}
        }

        return percentageSum == 10000;
    }

    /**
     * @notice Internal function for adding recipient to revenue share
     * @param _recipient Fixed amount of token user want to buy
     * @param _percentage code of the affiliation partner
     */
    function _addRecipient(address payable _recipient, uint256 _percentage) internal {
        if (_recipient == address(0)) {
            revert NullAddressRecipientError();
        }
        if (recipientsPercentage[_recipient] != 0) {
            revert RecipientAlreadyAddedError();
        }
        recipients.push(_recipient);
        recipientsPercentage[_recipient] = _percentage;
    }

    /**
     * @notice function for removing all recipients
     */
    function _removeAll() internal {
        if (numberOfRecipients == 0) {
            return;
        }

        for (uint256 i = 0; i < numberOfRecipients;) {
            address recipient = recipients[i];
            recipientsPercentage[recipient] = 0;
            unchecked{i++;}
        }
        delete recipients;
        numberOfRecipients = 0;
    }

    /**
     * @notice Internal function to set recipients in one TX
     * @param _newRecipients Addresses to be added as a new recipients
     * @param _percentages new percentages for recipients
     * @param _names recipients names
     */
    function _setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) internal {
        uint256 newRecipientsLength = _newRecipients.length;
        if (
            newRecipientsLength != _percentages.length &&
            newRecipientsLength != _names.length
        ) {
            revert InconsistentDataLengthError();
        }

        _removeAll();

        for (uint256 i = 0; i < newRecipientsLength;) {
            _addRecipient(_newRecipients[i], _percentages[i]);
            unchecked{i++;}
        }

        numberOfRecipients = newRecipientsLength;
        if (_percentageIsValid() == false) {
            revert InvalidPercentageError();
        }
        emit SetRecipients(_newRecipients, _percentages, _names);
    }

    /**
     * @notice External function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for recipients
     * @param _names names for recipients
     */
    function setRecipients(
        address payable [] memory _newRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) public onlyController {
        _setRecipients(_newRecipients, _percentages, _names);
    }

    /**
     * @notice External function to set distributor address
     * @param _distributor address of new distributor
     */
    function setDistributor(address _distributor) external onlyOwner {
        if (_distributor == distributor) {
            revert DistributorAlreadyConfiguredError();
        }
        emit DistributorChanged(distributor, _distributor);
        distributor = _distributor;
    }

    /**
     * @notice External function to set controller address, if set to address(0), unable to change it
     * @param _controller address of new controller
     */
    function setController(address _controller) external onlyOwner {
        if (controller == address(0) || immutableController) {
            revert ImmutableControllerError();
        }
        emit ControllerChanged(controller, _controller);
        controller = _controller;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./BaseRSCPrepayment.sol";


contract XLARSCPrepayment is Initializable, BaseRSCPrepayment {

    mapping(address => address) tokenEthPriceFeeds;
    event TokenPriceFeedSet(address token, address priceFeed);

    // Throws when trying to fetch ETH price for token without oracle
    error TokenMissingEthPriceOracle();

    /**
     * @dev Constructor function, can be called only once
     * @param _settings Contract settings, check InitContractSetting struct
     * @param _investor Address who invested money and is gonna receive interested rates
     * @param _investedAmount Amount of invested money from investor
     * @param _interestRate Percentage how much more investor will receive upon his investment amount
     * @param _residualInterestRate Percentage how much investor will get after his investment is fulfilled
     * @param _initialRecipients Addresses to be added as a initial recipients
     * @param _percentages percentages for recipients
     * @param _names recipients names
     */
    function initialize(
        InitContractSetting memory _settings,
        address payable _investor,
        uint256 _investedAmount,
        uint256 _interestRate,
        uint256 _residualInterestRate,
        address payable [] memory _initialRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) public initializer {
        // Contract settings
        controller = _settings.controller;
        distributor = _settings.distributor;
        immutableController = _settings.immutableController;
        autoEthDistribution = _settings.autoEthDistribution;
        minAutoDistributionAmount = _settings.minAutoDistributionAmount;
        factory = IFeeFactory(_settings.factoryAddress);
        platformFee = _settings.platformFee;
        _transferOwnership(_settings.owner);
        uint256 supportedErc20Length = _settings.supportedErc20addresses.length;
        if (supportedErc20Length != _settings.erc20PriceFeeds.length) {
            revert InconsistentDataLengthError();
        }
        for (uint256 i = 0; i < supportedErc20Length;) {
            _setTokenEthPriceFeed(_settings.supportedErc20addresses[i], _settings.erc20PriceFeeds[i]);
            unchecked{i++;}
        }

        // Investor setting
        investor = _investor;
        investedAmount = _investedAmount;
        interestRate = _interestRate;
        residualInterestRate = _residualInterestRate;
        investorAmountToReceive = _investedAmount + _investedAmount / 10000 * interestRate;

        // Recipients settings
        _setRecipients(_initialRecipients, _percentages, _names);
    }

    /**
     * @notice Internal function to redistribute ETH based on percentages assign to the recipients
     * @param _valueToDistribute ETH amount to be distribute
     */
    function _redistributeEth(uint256 _valueToDistribute) internal override {
        // Platform Fee
        if (platformFee > 0) {
            uint256 fee = _valueToDistribute / 10000 * platformFee;
            _valueToDistribute -= fee;
            address payable platformWallet = factory.platformWallet();
            (bool success,) = platformWallet.call{value: fee}("");
            if (success == false) {
                revert TransferFailedError();
            }
        }

        // Distribute to investor
        uint256 investorRemainingAmount = investorAmountToReceive - investorReceivedAmount;
        uint256 amountToDistribute;
        if (investorRemainingAmount == 0) {
            // Investor was already fulfilled and is now receiving residualInterestRate
            uint256 investorInterest = _valueToDistribute / 10000 * residualInterestRate;
            amountToDistribute = _valueToDistribute - investorInterest;
            (bool success,) = payable(investor).call{value: investorInterest}("");
            if (success == false) {
                revert TransferFailedError();
            }

        } else {
            // Investor was not yet fully fulfill, we first fulfill him, and then distribute share to recipients
            if (_valueToDistribute <= investorRemainingAmount) {
                // We can send whole msg.value to investor
                (bool success,) = payable(investor).call{value: _valueToDistribute}("");
                if (success == false) {
                    revert TransferFailedError();
                }
                investorReceivedAmount += _valueToDistribute;
                return;
            } else {
                // msg.value is more than investor will receive, so we send him his part and redistribute the rest
                uint256 investorInterestBonus = (_valueToDistribute - investorRemainingAmount) / 10000 * residualInterestRate;
                (bool success,) = payable(investor).call{value: investorRemainingAmount + investorInterestBonus}("");
                if (success == false) {
                    revert TransferFailedError();
                }
                amountToDistribute = _valueToDistribute - investorRemainingAmount - investorInterestBonus;
                investorReceivedAmount += investorRemainingAmount;
            }
        }

        // Distribute to recipients
        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = amountToDistribute / 10000 * percentage;
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            if (success == false) {
                revert TransferFailedError();
            }
            unchecked{i++;}
        }
    }

    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     * @param _token Address of the ERC20 token to be distribute
     */
    function redistributeToken(address _token) external onlyDistributor {
        IERC20 erc20Token = IERC20(_token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));
        if (contractBalance == 0) {
            revert Erc20ZeroBalanceError();
        }

        // Platform Fee
        if (platformFee > 0) {
            uint256 fee = contractBalance / 10000 * platformFee;
            contractBalance -= fee;
            address payable platformWallet = factory.platformWallet();
            erc20Token.transfer(platformWallet, fee);
        }

        // Distribute to investor
        uint256 investorRemainingAmount = investorAmountToReceive - investorReceivedAmount;
        uint256 investorRemainingAmountToken = _convertEthToToken(_token, investorRemainingAmount);

        uint256 amountToDistribute;

        if (investorRemainingAmount == 0) {
            // Investor was already fulfilled and is now receiving residualInterestRate
            uint256 investorInterest = contractBalance / 10000 * residualInterestRate;
            amountToDistribute = contractBalance - investorInterest;
            erc20Token.transfer(investor, investorInterest);
        } else {
            // Investor was not yet fully fulfill, we first fulfill him, and then distribute share to recipients
            if (contractBalance <= investorRemainingAmountToken) {
                // We can send whole contract erc20 balance to investor
                erc20Token.transfer(investor, contractBalance);
                investorReceivedAmount += _convertTokenToEth(_token, contractBalance);
                emit DistributeToken(_token, contractBalance);
                return;
            } else {
                // contractBalance is more than investor will receive, so we send him his part and redistribute the rest
                uint256 investorInterestBonus = (contractBalance - investorRemainingAmountToken) / 10000 * residualInterestRate;
                erc20Token.transfer(investor, investorRemainingAmountToken + investorInterestBonus);
                amountToDistribute = contractBalance - investorRemainingAmountToken - investorInterestBonus;
                investorReceivedAmount += investorRemainingAmount;
            }
        }

        // Distribute to recipients
        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = amountToDistribute / 10000 * percentage;
            erc20Token.transfer(recipient, amountToReceive);
            unchecked{i++;}
        }
        emit DistributeToken(_token, contractBalance);
    }

    /**
     * @notice internal function that returns erc20/eth price from external oracle
     * @param _token Address of the token
     */
    function _getTokenEthPrice(address _token) private view returns (uint256) {
        address tokenOracleAddress = tokenEthPriceFeeds[_token];
        if (tokenOracleAddress == address(0)) {
            revert TokenMissingEthPriceOracle();
        }
        AggregatorV3Interface tokenEthPriceFeed = AggregatorV3Interface(tokenOracleAddress);
        (,int256 price,,,) = tokenEthPriceFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @notice Internal function to convert ETH value to ETH value
     * @param _token token address
     * @param _tokenValue Token value to be converted to USD
     */
    function _convertTokenToEth(address _token, uint256 _tokenValue) internal view returns (uint256) {
        return (_getTokenEthPrice(_token) * _tokenValue) / 1e18;
    }

    /**
     * @notice Internal function to convert Eth value to token value
     * @param _token token address
     * @param _ethValue Eth value to be converted
     */
    function _convertEthToToken(address _token, uint256 _ethValue) internal view returns (uint256) {
        return (_ethValue * 1e25 / _getTokenEthPrice(_token) * 1e25) / 1e32;
    }

    /**
     * @notice External function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of ETH price feed for given token
     */
    function setTokenEthPriceFeed(address _token, address _priceFeed) external onlyOwner {
        _setTokenEthPriceFeed(_token, _priceFeed);
    }

    /**
     * @notice internal function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of ETH price feed for given token
     */
    function _setTokenEthPriceFeed(address _token, address _priceFeed) internal {
        tokenEthPriceFeeds[_token] = _priceFeed;
        emit TokenPriceFeedSet(_token, _priceFeed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BaseRSCPrepayment.sol";


contract XLARSCPrepaymentUsd is Initializable, BaseRSCPrepayment {

    mapping(address => address) tokenUsdPriceFeeds;
    AggregatorV3Interface internal ethUsdPriceFeed;

    event TokenPriceFeedSet(address token, address priceFeed);
    event EthPriceFeedSet(address oldEthPriceFeed, address newEthPriceFeed);

    // Throws when trying to fetch USD price for token without oracle
    error TokenMissingPriceOracle();

    /**
     * @dev Constructor function, can be called only once
     * @param _settings Contract settings, check InitContractSetting struct
     * @param _investor Address who invested money and is gonna receive interested rates
     * @param _investedAmount Amount of invested money from investor
     * @param _interestRate Percentage how much more investor will receive upon his investment amount
     * @param _residualInterestRate Percentage how much investor will get after his investment is fulfilled
     * @param _ethUsdPriceFeed oracle address for ETH / USD price
     * @param _initialRecipients Addresses to be added as a initial recipients
     * @param _percentages percentages for recipients
     * @param _names recipients names
     */
    function initialize(
        InitContractSetting memory _settings,
        address payable _investor,
        uint256 _investedAmount,
        uint256 _interestRate,
        uint256 _residualInterestRate,
        address _ethUsdPriceFeed,
        address payable [] memory _initialRecipients,
        uint256[] memory _percentages,
        string[] memory _names
    ) public initializer {
        // Contract settings
        controller = _settings.controller;
        distributor = _settings.distributor;
        immutableController = _settings.immutableController;
        autoEthDistribution = _settings.autoEthDistribution;
        minAutoDistributionAmount = _settings.minAutoDistributionAmount;
        factory = IFeeFactory(_settings.factoryAddress);
        platformFee = _settings.platformFee;
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        _transferOwnership(_settings.owner);
        uint256 supportedErc20Length = _settings.supportedErc20addresses.length;
        if (supportedErc20Length != _settings.erc20PriceFeeds.length) {
            revert InconsistentDataLengthError();
        }
        for (uint256 i = 0; i < supportedErc20Length;) {
            _setTokenUsdPriceFeed(_settings.supportedErc20addresses[i], _settings.erc20PriceFeeds[i]);
            unchecked{i++;}
        }


        // Investor setting
        investor = _investor;
        investedAmount = _investedAmount;
        interestRate = _interestRate;
        residualInterestRate = _residualInterestRate;
        investorAmountToReceive = _investedAmount + _investedAmount / 10000 * interestRate;

        // Recipients settings
        _setRecipients(_initialRecipients, _percentages, _names);
    }

    /**
     * @notice Internal function to redistribute ETH based on percentages assign to the recipients
     * @param _valueToDistribute ETH amount to be distribute
     */
    function _redistributeEth(uint256 _valueToDistribute) internal override {
        // Platform Fee
        if (platformFee > 0) {
            uint256 fee = _valueToDistribute / 10000 * platformFee;
            _valueToDistribute -= fee;
            address payable platformWallet = factory.platformWallet();
            (bool success,) = platformWallet.call{value: fee}("");
            if (success == false) {
                revert TransferFailedError();
            }
        }

        // Distribute to investor
        uint256 investorRemainingAmount = investorAmountToReceive - investorReceivedAmount;
        uint256 investorRemainingAmountEth = _convertUsdToEth(investorRemainingAmount);
        uint256 amountToDistribute;

        if (investorRemainingAmount == 0) {
            // Investor was already fulfilled and is not receiving residualInterestRate
            uint256 investorInterest = _valueToDistribute / 10000 * residualInterestRate;
            amountToDistribute = _valueToDistribute - investorInterest;
            (bool success,) = payable(investor).call{value: investorInterest}("");
            if (success == false) {
                revert TransferFailedError();
            }

        } else {
            // Investor was not yet fully fulfill, we first fulfill him, and then distribute share to recipients
            if (_valueToDistribute <= investorRemainingAmountEth) {
                // We can send whole _valueToDistribute to investor
                (bool success,) = payable(investor).call{value: _valueToDistribute}("");
                if (success == false) {
                    revert TransferFailedError();
                }
                investorReceivedAmount += _convertEthToUsd(_valueToDistribute);
                return;
            } else {
                // msg.value is more than investor will receive, so we send him his part and redistribute the rest
                uint256 investorInterestBonus = (_valueToDistribute - investorRemainingAmountEth) / 10000 * residualInterestRate;
                (bool success,) = payable(investor).call{value: investorRemainingAmountEth + investorInterestBonus}("");
                if (success == false) {
                    revert TransferFailedError();
                }
                amountToDistribute = _valueToDistribute - investorRemainingAmountEth - investorInterestBonus;
                investorReceivedAmount += investorRemainingAmount;
            }
        }

        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = amountToDistribute / 10000 * percentage;
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            if (success == false) {
                revert TransferFailedError();
            }
            unchecked{i++;}
        }
    }

    /**
     * @notice Internal function to convert ETH value to Usd value
     * @param _ethValue ETH value to be converted
     */
    function _convertEthToUsd(uint256 _ethValue) internal view returns (uint256) {
        return (_getEthUsdPrice() * _ethValue) / 1e18;
    }

    /**
     * @notice Internal function to convert USD value to ETH value
     * @param _usdValue Usd value to be converted
     */
    function _convertUsdToEth(uint256 _usdValue) internal view returns (uint256) {
        return (_usdValue * 1e25 / _getEthUsdPrice() * 1e25) / 1e32;
    }

    /**
     * @notice Internal function to convert Token value to Usd value
     * @param _token token address
     * @param _tokenValue Token value to be converted to USD
     */
    function _convertTokenToUsd(address _token, uint256 _tokenValue) internal view returns (uint256) {
        return (_getTokenUsdPrice(_token) * _tokenValue) / 1e18;
    }

    /**
     * @notice Internal function to convert USD value to ETH value
     * @param _token token address
     * @param _usdValue Usd value to be converted
     */
    function _convertUsdToToken(address _token, uint256 _usdValue) internal view returns (uint256) {
        return (_usdValue * 1e25 / _getTokenUsdPrice(_token) * 1e25) / 1e32;
    }

    /**
     * @notice internal function that returns eth/usd price from external oracle
     */
    function _getEthUsdPrice() private view returns (uint256) {
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * @notice internal function that returns erc20/usd price from external oracle
     * @param _token Address of the token
     */
    function _getTokenUsdPrice(address _token) private view returns (uint256) {
        address tokenOracleAddress = tokenUsdPriceFeeds[_token];
        if (tokenOracleAddress == address(0)) {
            revert TokenMissingPriceOracle();
        }
        AggregatorV3Interface tokenUsdPriceFeed = AggregatorV3Interface(tokenOracleAddress);
        (,int256 price,,,) = tokenUsdPriceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     * @param _token Address of the token to be distributed
     */
    function redistributeToken(address _token) external onlyDistributor {
        IERC20 erc20Token = IERC20(_token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));
        if (contractBalance == 0) {
            revert Erc20ZeroBalanceError();
        }

        // Platform Fee
        if (platformFee > 0) {
            uint256 fee = contractBalance / 10000 * platformFee;
            contractBalance -= fee;
            address payable platformWallet = factory.platformWallet();
            erc20Token.transfer(platformWallet, fee);
        }

        // Distribute to investor
        uint256 investorRemainingAmount = investorAmountToReceive - investorReceivedAmount;
        uint256 investorRemainingAmountToken = _convertUsdToToken(_token, investorRemainingAmount);

        uint256 amountToDistribute;

        if (investorRemainingAmount == 0) {
            // Investor was already fulfilled and is now receiving residualInterestRate
            uint256 investorInterest = contractBalance / 10000 * residualInterestRate;
            amountToDistribute = contractBalance - investorInterest;
            erc20Token.transfer(investor, investorInterest);
        } else {
            // Investor was not yet fully fulfill, we first fulfill him, and then distribute share to recipients
            if (contractBalance <= investorRemainingAmountToken) {
                // We can send whole contract erc20 balance to investor
                erc20Token.transfer(investor, contractBalance);
                investorReceivedAmount += _convertTokenToUsd(_token, contractBalance);
                emit DistributeToken(_token, contractBalance);
                return;
            } else {
                // contractBalance is more than investor will receive, so we send him his part and redistribute the rest
                uint256 investorInterestBonus = (contractBalance - investorRemainingAmountToken) / 10000 * residualInterestRate;
                erc20Token.transfer(investor, investorRemainingAmountToken + investorInterestBonus);
                amountToDistribute = contractBalance - investorRemainingAmountToken - investorInterestBonus;
                investorReceivedAmount += investorRemainingAmount;
            }
        }

        // Distribute to recipients
        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = amountToDistribute / 10000 * percentage;
            erc20Token.transfer(recipient, amountToReceive);
            unchecked{i++;}
        }
        emit DistributeToken(_token, contractBalance);
    }

    /**
     * @notice External function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of USD price feed for given token
     */
    function setTokenUsdPriceFeed(address _token, address _priceFeed) external onlyOwner {
        _setTokenUsdPriceFeed(_token, _priceFeed);
    }

    /**
     * @notice Internal function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of USD price feed for given token
     */
    function _setTokenUsdPriceFeed(address _token, address _priceFeed) internal {
        tokenUsdPriceFeeds[_token] = _priceFeed;
        emit TokenPriceFeedSet(_token, _priceFeed);
    }

    /**
     * @notice External function for setting price feed oracle for ETH
     * @param _priceFeed address of USD price feed for ETH
     */
    function setEthPriceFeed(address _priceFeed) external onlyOwner {
        emit EthPriceFeedSet(address(ethUsdPriceFeed), _priceFeed);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
    }
}