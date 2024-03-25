// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

interface IErrors {
    /* ========== ERRORS ========== */
    /// @notice Error for if a mint ratio of 0 is passed in
    error MintRatio0();

    /// @notice Error for if pool is closed
    error PoolClosed();

    /// @notice Error for if pool is active
    error PoolActive();

    /// @notice Error for if price is not valid ex: -1
    error NotValidPrice();

    /// @notice Error for if not enough liquidity in pool
    error NotEnoughLiquidity();

    /// @notice Error for if balance is insufficient
    error InsufficientBalance();

    /// @notice Error for if address is not a pool
    error NotAPool();

    /// @notice Error for if address is different than lend token
    error DifferentLendToken();

    /// @notice Error for if address is different than collateral token
    error DifferentColToken();

    /// @notice Error for if owner addresses are different
    error DifferentPoolOwner();

    /// @notice Error for if a user has no debt
    error NoDebt();

    /// @notice Error for if user is trying to pay back more than the debt they have
    error DebtIsLess();

    /// @notice Error for if balance is not validated
    error TransferFailed();

    /// @notice Error for if user tries to interract with private pool
    error PrivatePool();

    /// @notice Error for if operations of this pool or potetntially all pools is stopped.
    error OperationsPaused();

    /// @notice Error for if lender paused borrowing.
    error BorrowingPaused();

    /// @notice Error for if Oracle not set.
    error OracleNotSet();

    /// @notice Error for if called by not owner
    error NotOwner();

    /// @notice Error for if illegal upgrade implementation
    error IllegalImplementation();

    /// @notice Error for if upgrades are not allowed at this time
    error UpgradeNotAllowed();

    /// @notice Error for if expiry is wrong
    error InvalidExpiry();

    /// @notice Error if the lender's fee is higher than what UI stated
    error FeeTooHigh();

    /// @notice Error for if address is not the pool factory or the pool owner
    error NoPermission();

    /// @notice Error for if array length is invalid
    error InvalidType();

    /// @notice Error for when the address passed as an argument is a zero address
    error ZeroAddress();

    /// @notice Error for if a mint id is not minted yet
    error LicenseNotFound();

    /// @notice Error for if a discount is too high
    error InvalidDiscount();

    ///@notice Error if not factory is trying to increment the amount of pools deployed by license
    error NotFactory();

    /// @notice Error for if address is not supported as lend token
    error LendTokenNotSupported();

    /// @notice Error for if address is not supported as collateral token
    error ColTokenNotSupported();

    /// @notice Error for if discount coming from license engine is over 100%
    error DiscountTooLarge();

    /// @notice Error for if lender fee is over 100%
    error FeeTooLarge();

    /// @notice Error for when unauthorized user tries to pause the pools or factory
    error NotAuthorized();

    /// @notice Error for when the address that was not granted the permissions is trying to claim the ownership
    error NotGranted();

    /// @notice Error for when the pegs setting on contruction of the oracle failed dur to bad arguments
    error InvalidParameters();

    /// @notice Error for when the token pair selected is not supported
    error InvalidTokenPair();

    /// @notice Error for when chainlink sent the incorrect price
    error RoundIncomplete();

    /// @notice Error for when chainlink sent the incorrect price
    error StaleAnswer();

    /// @notice Error for when the feed address is already set and owner is trying to alter it
    error FeedAlreadySet();

    /// @notice Error for when the pool is not whitelisted for rollover
    error PoolNotWhitelisted();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeesManager {
    function getFee(address _pool, uint256 _rawPayoutAmount)
        external
        view
        returns (uint256);

    function setPoolFees(
        address _pool,
        uint48 _feeRate,
        uint256 _type
    ) external;

    function getCurrentRate(address _pool) external view returns (uint48);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IStructs.sol";

interface ILendingPool is IStructs {
    struct UserReport {
        uint256 borrowAmount; // total borrowed in lend token
        uint256 colAmount; // total collateral borrowed
        uint256 totalFees; // total fees owed at the moment
    }

    event Borrow(
        address borrower,
        uint256 colDepositAmount,
        uint256 borrowAmount,
        uint48 currentFeeRate
    );
    event RollOver(address pool, uint256 colRolled);
    event Collect(uint256 treasuryLend, uint256 treasuryCol, uint256 lenderLend, uint256 lenderCol);
    event BalanceChange(address token, bool incoming, uint256 amount);
    event Repay(address borrower, uint256 colReturned, uint256 repayAmount);
    event UpdateExpiry(uint48 newExpiry);
    event AddBorrower(address newBorrower);
    event Pause(uint256 disabled);

    function initialize(Data calldata data) external;

    function undercollateralized() external view returns (uint256);

    function mintRatio() external view returns (uint256);

    function lendToken() external view returns (IERC20);

    function colToken() external view returns (IERC20);

    function expiry() external view returns (uint48);

    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint256 _rate,
        uint256 _estimate
    ) external;

    function owner() external view returns (address);

    function isPrivate() external view returns (uint256);

    function borrowers(address borrower) external view returns (uint256);

    function disabledBorrow() external view returns (uint256);

    function collect() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPoolFactory {
    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function poolImplementationAddress() external view returns (address);

    function rollBackImplementation() external view returns (address);

    function allowUpgrade() external view returns (bool);

    function isPaused(address _pool) external view returns (bool);
}

// SPDX-License-Identifier: No-License
pragma solidity ^0.8.11;

interface IStructs {
    struct Data {
        address deployer;
        uint256 mintRatio;
        address colToken;
        address lendToken;
        uint48 expiry;
        address[] borrowers;
        uint48 protocolFee;
        uint48 protocolColFee;
        address feesManager;
        address oracle;
        address factory;
        uint256 undercollateralized;
    }

    struct UserPoolData {
        uint256 _mintRatio;
        address _colToken;
        address _lendToken;
        uint48 _feeRate;
        uint256 _type;
        uint48 _expiry;
        address[] _borrowers;
        uint256 _undercollateralized;
        uint256 _licenseId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVendorOracle {
    function getPriceUSD(address base) external view returns (int256);
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "./interfaces/IVendorOracle.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IFeesManager.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IErrors.sol";
import "./utils/VendorUtils.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract LendingPool is
    IStructs,
    IErrors,
    ILendingPool,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    /* ========== CONSTANT VARIABLES ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;

    /* ========== STATE VARIABLES ========== */
    IVendorOracle public priceFeed;
    IPoolFactory public factory;
    IFeesManager public feeManager;
    IERC20 public override colToken;
    IERC20 public override lendToken;
    address public treasury;
    uint256 public mintRatio;
    uint48 public expiry;
    uint48 public protocolFee;                      // 1% = 10000
    uint48 public protocolColFee;                   // 1% = 10000
    mapping(address => uint256) public borrowers;   // List of allowed borrowers. Used only when isPrivate == true
    mapping(address => UserReport) public debt;     // Registry of all borrowers and their debt
    uint256 public totalFees;                       // Sum of all outstanding fees that lenders owes fees to Vendor. Becomes zero when fees are paid.
    address public owner;                           // Creator of the pool a.k.a lender
    uint256 public disabledBorrow;                  // If lender disables borrows, different from emergency pause
    uint256 public isPrivate;                       // If true anyone can borrow, otherwise only ones in `borrowers` mapping
    uint256 public undercollateralized;             // If allows borrowing when collateral bellow mint ratio
    address private _grantedOwner;
    mapping(address => bool) public allowedRollovers;      // Pools to which we can rollover.

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Initialize the pool with all the user provided settings
    /// @param data             See the IStructs for the layout
    function initialize(Data calldata data) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        mintRatio = data.mintRatio;
        owner = data.deployer;
        colToken = IERC20(data.colToken);
        lendToken = IERC20(data.lendToken);
        factory = IPoolFactory(data.factory);
        priceFeed = IVendorOracle(data.oracle);
        feeManager = IFeesManager(data.feesManager);
        treasury = factory.treasury();
        protocolFee = data.protocolFee;
        protocolColFee = data.protocolColFee;
        expiry = data.expiry;
        undercollateralized = data.undercollateralized;
        if (data.borrowers.length > 0) {
            isPrivate = 1;
            for (uint256 j = 0; j != data.borrowers.length; ++j) {
                borrowers[data.borrowers[j]] = 1;
            }
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    ///@notice                  Deposit the funds you would like to lend. Prior approval of lend token is required
    ///@dev                     One could simply just send the tokens directly to the pool
    ///@param _depositAmount    Amount of lend token to deposit into the pool
    function deposit(uint256 _depositAmount) external nonReentrant {
        onlyOwner();
        onlyNotPaused();
        _safeTransferFrom(lendToken, msg.sender, address(this), _depositAmount);
    }

    ///@notice                  Withdraw the lend token from the pool. Only amount minus fees owed to Vendor will be withdrawable
    ///@param _amount           Amount of lend token to withdraw from the pool
    function withdraw(uint256 _amount) external nonReentrant {
        onlyOwner();
        onlyNotPaused();
        if (
            lendToken.balanceOf(address(this)) <
            _amount + ((totalFees * protocolFee) / HUNDRED_PERCENT)
        ) revert InsufficientBalance();
        if (block.timestamp > expiry) revert PoolClosed(); // Collect instead
        _safeTransfer(lendToken, msg.sender, _amount);
    }

    ///@notice                  Borrow on behalf of a wallet
    ///@dev                     We assign the debt to the _borrower and we send the money to the borrower. 
    ///                         Collateral will be taken from the msg.sender.
    ///@param _borrower         User that will need to repay the loan. Collateral of the the msg.sender is used
    ///@param _colDepositAmount Amount of col token user wants to deposit as collateral
    ///@param _rate             The user expected rate should be larger than or equal to the effective rate
    ///@param _estimate         Suggested amount of debt the user should have in this pool. Used on rollovers
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint256 _rate,
        uint256 _estimate
    ) external nonReentrant {
        if (disabledBorrow == 1) revert BorrowingPaused(); // If lender disabled borrowing
        onlyNotPaused();
        if (
            undercollateralized == 0 &&
            !VendorUtils._isValidPrice(address(priceFeed), address(colToken), address(lendToken), mintRatio)
        ) revert NotValidPrice();
        if (block.timestamp > expiry) revert PoolClosed();
        if (isPrivate == 1 && borrowers[msg.sender] == 0) revert PrivatePool();
        uint48 borrowRate = feeManager.getCurrentRate(address(this));
        if (_rate < borrowRate)
            revert FeeTooHigh();

        UserReport storage userReport = debt[_borrower];
        uint256 rawPayoutAmount;

        // If msg.sender is the other pool deployed by the same factory then we can use the passed _estimate as long as it is in the error range
        if (factory.pools(msg.sender)) {
            rawPayoutAmount = VendorUtils._computePayoutAmountWithEstimate(
                _colDepositAmount,
                mintRatio,
                address(colToken),
                address(lendToken),
                _estimate
            );
        } else {
            rawPayoutAmount = VendorUtils._computePayoutAmount(
                _colDepositAmount,
                mintRatio,
                address(colToken),
                address(lendToken)
            );
        }

        userReport.borrowAmount += rawPayoutAmount;
        uint256 fee = feeManager.getFee(address(this), rawPayoutAmount);
        userReport.totalFees += fee;
        _safeTransferFrom(colToken, msg.sender, address(this), _colDepositAmount);
        userReport.colAmount += _colDepositAmount;

        if (!factory.pools(msg.sender)) {
            // If this is not rollover
            if (lendToken.balanceOf(address(this)) < rawPayoutAmount)
                revert NotEnoughLiquidity();

            _safeTransfer(lendToken, _borrower, rawPayoutAmount);
        }
        emit Borrow(_borrower, _colDepositAmount, rawPayoutAmount, borrowRate);
    }

    ///@notice                  Rollover loan into a pool that has been deployed by the same lender as the original one
    ///@dev                     Pools should have same lend/col tokens and lender. New pool should have longer expiry
    ///@param _newPool          Address of the destination pool
    ///
    /// After the rollover the new pool attempts to have the same amount of debt for the user as the old one. For
    /// that reason there are three cases that we need to consider: new and old pools have same mint ratio,
    /// new pool has higher mint ratio or new pool has lower mint ratio.
    /// Same Mint Ratio - In this case we simply move the old collateral to the new pool and pass old debt.
    /// New MR > Old MR - In this case new pool gives more lend token per unit of collateral so we need less collateral to 
    /// maintain same debt. We compute the collateral amount to reimburse using the following formula:
    ///             oldColAmount * (newMR-oldMR)
    ///             ---------------------------- ;
    ///                       newMR
    /// Derivation:
    /// Assuming we have a mint ratio of pool A that is m and we also have a new pool that has a mint ratio 3m, 
    /// that we would like to rollover into, then m/3m=1/3 is the amount of collateral required to borrow the same amount
    /// of lend token in pool B. If we give 3 times more debt for unit of collateral, then we need 3 times less collateral
    /// to maintain same debt level.
    /// Now if we do that with a slightly different notation:
    /// Assuming we have a mint ratio of pool A that is m and we also have a new pool that has a mint ratio M, 
    /// that we would like to rollover into. Then m/M is the amount of collateral required to borrow the same amount of lend token in pool B. 
    /// In that case fraction of the collateral amount to reimburse is: 
    ///            m            M     m           (M-m) 
    ///       1 - ----    OR   --- - ----   OR   ------ ;
    ///            M            M     M            M
    /// If we multiply this fraction by the original collateral amount, we will get the formula above. 
    /// New MR < Old MR - In this case we need more collateral to maintain the same debt. Since we can not expect borrower
    /// to have more collateral token on hand it is easier to ask them to return a fraction of borrowed funds using formula:
    ///             oldColAmount * (oldMR - newMR) ;
    /// This formula basically computes how much over the new mint ratio you were lent given you collateral deposit.
    function rollOver(address _newPool, uint256 _rate) external nonReentrant {
        onlyNotPaused();
        if (!allowedRollovers[_newPool]) revert PoolNotWhitelisted();
        UserReport storage userReport = debt[msg.sender];
        if (block.timestamp > expiry) revert PoolClosed();
        if (userReport.borrowAmount == 0) revert NoDebt();
        ILendingPool newPool = ILendingPool(_newPool);
        VendorUtils._validateNewPool(
            _newPool,
            address(factory),
            address(lendToken),
            owner,
            expiry
        );
        if (address(newPool.colToken()) != address(colToken))
            revert DifferentColToken();
        if (newPool.isPrivate() == 1 && newPool.borrowers(msg.sender) == 0)
            revert PrivatePool();

        if (newPool.disabledBorrow() == 1) revert BorrowingPaused();
        if (
            newPool.undercollateralized() == 0 &&
            !VendorUtils._isValidPrice(
                address(priceFeed),
                address(newPool.colToken()),
                address(newPool.lendToken()),
                newPool.mintRatio()
            )
        ) revert NotValidPrice();

        uint256 borrowRate = feeManager.getCurrentRate(_newPool);
        if (_rate < borrowRate)
            revert FeeTooHigh();

        colToken.approve(_newPool, userReport.colAmount);
        uint256 diffToReimburse;
        if (newPool.mintRatio() <= mintRatio) {
            // Need to repay some loan since you can not borrow as much in a new pool
            uint256 diffToRepay = VendorUtils._computePayoutAmount(
                userReport.colAmount,
                mintRatio - newPool.mintRatio(),
                address(colToken),
                address(lendToken)
            );
            _safeTransferFrom(
                lendToken,
                msg.sender,
                address(this),
                diffToRepay + userReport.totalFees
            );
            newPool.borrowOnBehalfOf(
                msg.sender,
                userReport.colAmount,
                borrowRate,
                userReport.borrowAmount - diffToRepay
            );
        } else {
            // Reimburse the borrower
            diffToReimburse = VendorUtils._computeReimbursement(
                userReport.colAmount,
                mintRatio,
                newPool.mintRatio()
            );
            _safeTransferFrom(
                lendToken,
                msg.sender,
                address(this),
                userReport.totalFees
            );
            _safeTransfer(colToken, msg.sender, diffToReimburse);
            newPool.borrowOnBehalfOf(
                msg.sender,
                userReport.colAmount - diffToReimburse,
                borrowRate,
                userReport.borrowAmount
            );
        }
        totalFees += userReport.totalFees;

        emit RollOver(_newPool, userReport.colAmount - diffToReimburse);
        //Clean users debt in current pool
        userReport.colAmount = 0;
        userReport.borrowAmount = 0;
        userReport.totalFees = 0;
    }

    ///@notice                  Repay the loan on behalf of a different wallet
    ///@dev                     Fees are repaid first thing and then remainder is used to cover the debt
    ///@param _borrower         Wallet who's loan is going to be repaid
    ///@param _repayAmount      Amount of lend token that will be repaid
    function repayOnBehalfOf(address _borrower, uint256 _repayAmount)
        external
        nonReentrant
    {
        onlyNotPaused();
        UserReport memory userReport = debt[_borrower];
        if (block.timestamp > expiry) revert PoolClosed();
        if (_repayAmount > userReport.borrowAmount + userReport.totalFees)
            revert DebtIsLess();
        if (userReport.borrowAmount == 0) revert NoDebt();

        uint256 repayRemainder = _repayAmount;

        //Repay the fee first.
        uint256 initialFeeOwed = userReport.totalFees;
        _safeTransferFrom(lendToken, msg.sender, address(this), _repayAmount);
        if (repayRemainder <= userReport.totalFees) {
            userReport.totalFees -= repayRemainder;
            totalFees += initialFeeOwed - userReport.totalFees;
            debt[_borrower] = userReport;
            return;
        } else if (userReport.totalFees > 0) {
            repayRemainder -= userReport.totalFees;
            userReport.totalFees = 0;
        }

        totalFees += initialFeeOwed - userReport.totalFees; // Increment the lenders debt to Vendor by the fraction of fees repaid by borrower

        // If we are repaying the whole debt, then the borrow amount should be set to 0 and all collateral should be returned
        // without computation to avoid  dust remaining in the pool
        uint256 colReturnAmount = repayRemainder == userReport.borrowAmount
            ? userReport.colAmount
            : VendorUtils._computeCollateralReturn(
                repayRemainder,
                mintRatio,
                address(colToken),
                address(lendToken)
            );

        userReport.borrowAmount -= repayRemainder;
        userReport.colAmount -= colReturnAmount;
        debt[_borrower] = userReport;
        _safeTransfer(colToken, _borrower, colReturnAmount);
        emit Repay(_borrower, colReturnAmount, repayRemainder);
    }

    ///@notice                  Collect the interest, defaulted collateral and pay vendor fee
    function collect() external nonReentrant {
        onlyNotPaused();
        if (block.timestamp <= expiry) revert PoolActive();
        // Send the protocol fee to treasury
        uint256 treasuryLend = (totalFees * protocolFee) / HUNDRED_PERCENT;
        uint256 treasuryCol = (colToken.balanceOf(address(this)) * protocolColFee) / HUNDRED_PERCENT;
        _safeTransfer(
            lendToken,
            treasury,
            treasuryLend
        );
        totalFees = 0;
        _safeTransfer(
            colToken,
            treasury,
            treasuryCol
        );

        // Send the remaining funds to the lender
        uint256 lenderLend = lendToken.balanceOf(address(this));
        uint256 lenderCol = colToken.balanceOf(address(this));
        _safeTransfer(lendToken, owner, lenderLend);
        _safeTransfer(colToken, owner, lenderCol);
        emit Collect(treasuryLend, treasuryCol, lenderLend, lenderCol);
    }

    /* ========== SETTERS ========== */
    ///@notice                  Allow users to extend expiry by three days in case of emergency
    function extendExpiry() external {
        onlyOwner();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed(); //Only allow extension when we allow upgrade.
        if (block.timestamp + 3 days <= expiry) revert PoolActive();
        expiry = uint48(block.timestamp + 3 days);
        emit UpdateExpiry(expiry);
    }

    ///@notice                  Lender can stop the borrowing from this pool
    function setBorrow(uint256 _disabled) external {
        onlyOwner();
        disabledBorrow = _disabled;
        emit Pause(_disabled);
    }

    ///@notice                  Allow the lender to add a private borrower
    ///@dev                     Will not affect anything if the pool is not private
    function addBorrower(address _newBorrower) external {
        onlyOwner();
        borrowers[_newBorrower] = 1;
        emit AddBorrower(_newBorrower);
    }

    ///@notice                  Allow the lender to select rollover pools
    function setRolloverPool(address _pool, bool _enabled) external {
        onlyOwner();
        allowedRollovers[_pool] = _enabled;
    }

    /* ========== UTILITY ========== */
    ///@notice                  Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        onlyOwner();
        if (
            newImplementation != factory.poolImplementationAddress() &&
            newImplementation != factory.rollBackImplementation()
        ) revert IllegalImplementation();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed();
    }

    ///@notice                  Transfer tokens with overflow protection
    ///@param _token            ERC20 token to send
    ///@param _account          Address of an account to send to
    ///@param _amount           Amount of _token to send
    function _safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) private {
        uint256 bal = _token.balanceOf(address(this));
        if (bal < _amount) {
            _token.safeTransfer(_account, bal);
            emit BalanceChange(address(_token), false, bal);
        } else {
            _token.safeTransfer(_account, _amount);
            emit BalanceChange(address(_token), false, _amount);
        }
    }

    function _safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        _token.safeTransferFrom(_from, _to, _amount);
        emit BalanceChange(address(_token), true, _amount);
    }

    ///@notice                  First step in a process of changing the owner
    function grantOwnership(address _newOwner) external {
        onlyOwner();
        _grantedOwner = _newOwner;
    }

    ///@notice                  Second step in a process of changing the owner
    function claimOwnership() external {
        if (_grantedOwner != msg.sender) revert NotGranted();
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /* ========== MODIFIERS ========== */
    ///@notice                  Owner is the deployer of the pool, not Vendor
    function onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    ///@notice                  This pause will be triggered by Vendor 
    function onlyNotPaused() private view {
        if (factory.isPaused(address(this))) revert OperationsPaused();
    }
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Utility Functions
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "../interfaces/ILendingPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IVendorOracle.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library VendorUtils {
    using SafeERC20Upgradeable for IERC20;

    error NotAPool();

    error DifferentPoolOwner();

    error InvalidExpiry();

    error DifferentLendToken();

    error OracleNotSet();

    ///@notice                  Make sure new pool can be rolled into
    ///@param _pool             Address of the pool you are about rollover into
    ///@param _factory          Address of the factory that deployed the new pool
    ///@param _lendToken        A lend toke that we will make sure the same as in the original pool
    ///@param _owner            Owner of the original pool to ensure new pool has the same owner
    ///@param _expiry           Expiry of the original pool, to ensure it is shorter than the new once
    function _validateNewPool(
        address _pool,
        address _factory,
        address _lendToken,
        address _owner,
        uint48 _expiry
    ) external view {
        if (!IPoolFactory(_factory).pools(_pool)) revert NotAPool();
        ILendingPool pool = ILendingPool(_pool);
        if (address(pool.lendToken()) != _lendToken)
            revert DifferentLendToken();

        if (pool.owner() != _owner) revert DifferentPoolOwner();

        if (pool.expiry() <= _expiry) revert InvalidExpiry();
    }

    /// @notice                     Compute the amount of lend tokens to send given collateral deposited
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _mintRatio           MintRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           lend token that is being paid out for collateral
    /// @return                     Lend token amount in lend decimals
    ///
    /// In this function we will need to compute the amount of lend token to send
    /// based on collateral and mint ratio.
    /// Mint Ratio dictates how many lend tokens we send per unit of collateral.
    /// MintRatio must always be passed as 18 decimals.
    /// So:
    ///    lentAmount = mintRatio * colAmount
    /// Given the above information, there are only 2 cases to consider when adjusting decimals:
    ///    lendDecimals > colDecimals + 18 OR lendDecimals <= colDecimals + 18
    /// Based on the situation we will either multiply or divide by 10**x where x is difference between desired decimals
    /// and the decimals we actually have. This way we minimize the number of divisions to at most one and
    /// impact of such division is minimal as it is a division by 10**x and only acts as a mean of reducing decimals count.
    function _computePayoutAmount(
        uint256 _colDepositAmount,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken
    ) public view returns (uint256) {
        IERC20 lendToken = IERC20(_lendToken);
        IERC20 colToken = IERC20(_colToken);
        uint8 lendDecimals = lendToken.decimals();
        uint8 colDecimals = colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals >= lendDecimals) {
            return
                (_colDepositAmount * _mintRatio) /
                (10**(colDecimals + mintDecimals - lendDecimals));
        } else {
            return
                (_colDepositAmount * _mintRatio) *
                (10**(lendDecimals - colDecimals - mintDecimals));
        }
    }

    /// @notice                     Compute the amount of debt to assign to the user during the borrow or rollover
    /// @dev                        Uses the estimate sent from previous pool if it is within 1% of computed payout value
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _mintRatio           MintRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @param _estimate            Amount of lend token that is suggested by the previous pool to avoid additional division
    /// @return                     Lend token amount in lend decimals
    ///
    /// This function is used exclusively on rollover.
    /// Rollover process entails that we pay off all our fees and send all of our
    /// available or required (in case where MintRatio is higher in the second pool)
    /// collateral to a borrow function of the new pool.
    /// Basically our goal is to make borrow amount (without fees) in the second pool the same as in the first pool.
    /// Since we are performing a regular borrow in the second pool we will end up computing the amount of debt again.
    /// This will potentially result in truncation errors and potentially bad debt.
    /// For this reason we should be able to pass the amount owed from the first pool directly to the second pool.
    /// In order to prevent pools sending arbitrary debt amounts, we still perform the computation and check that the passed
    /// debt amount is within the allowed threshold from the computed amount.
    function _computePayoutAmountWithEstimate(
        uint256 _colDepositAmount,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken,
        uint256 _estimate
    ) external view returns (uint256) {
        uint256 compute = _computePayoutAmount(
            _colDepositAmount,
            _mintRatio,
            _colToken,
            _lendToken
        );
        uint256 threshold = (compute * 1_0000) / 100_0000; // Suggested debt should be within 1% of the computed debt
        if (
            compute + threshold <= _estimate || compute - threshold >= _estimate
        ) {
            return _estimate;
        } else {
            return compute;
        }
    }


    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _mintRatio           MintRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    // Amount of collateral to return is always computed as:
    //                                 lendTokenAmount
    // amountOfCollateralReturned  =   ---------------
    //                                    mintRatio
    // 
    // We also need to ensure that the correct amount of decimals are used. Output should always be in
    // collateral token decimals.
    function _computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken
    ) external view returns (uint256) {
        IERC20 lendToken = IERC20(_lendToken);
        IERC20 colToken = IERC20(_colToken);
        uint8 lendDecimals = lendToken.decimals();
        uint8 colDecimals = colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_mintRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _mintRatio;
        }
    }

    ///@notice                  Compute the amount fo collateral that needs to be sent to user when rolling into a pool with higher mint ratio
    ///@param _colAmount        Collateral amount deposited into the original pool
    ///@param _mintRatio        MintRatio of the original pool
    ///@param _newMintRatio     MintRatio of the new pool
    function _computeReimbursement(
        uint256 _colAmount,
        uint256 _mintRatio,
        uint256 _newMintRatio
    ) external pure returns (uint256) {
        return (_colAmount * (_newMintRatio - _mintRatio)) / _newMintRatio;
    }

    ///@notice                  Check if col price is below mint ratio
    ///@dev                     We need to ensure that 1 unit of collateral is worth more than what 1 unit of collateral allows to borrow
    ///@param _priceFeed        Address of the oracle to use
    ///@param _colToken         Address of the collateral token
    ///@param _lendToken        Address of the lend token
    ///@param _mintRatio        Mint ratio of the pool
    function _isValidPrice(
        address _priceFeed,
        address _colToken,
        address _lendToken,
        uint256 _mintRatio
    ) external view returns (bool) {
        IVendorOracle priceFeed  = IVendorOracle(_priceFeed);
        if (_priceFeed == address(0)) revert OracleNotSet();
        int256 priceLend = priceFeed.getPriceUSD(_lendToken);
        int256 priceCol = priceFeed.getPriceUSD(_colToken);
        if (priceLend != -1 && priceCol != -1) {
            return (priceCol > ((int256(_mintRatio) * priceLend) / 1e18));
        }
        return false;
    }
}