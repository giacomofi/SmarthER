// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IPriceFeed } from "./utils/IPriceFeed.sol";
import { Market } from "./Market.sol";

contract Auditor is Initializable, AccessControlUpgradeable {
  using FixedPointMathLib for uint256;

  /// @notice Address that a market should have as price feed to consider as base price and avoid external price call.
  address public constant BASE_FEED = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  /// @notice Target health factor that the account should have after it's liquidated to prevent cascade liquidations.
  uint256 public constant TARGET_HEALTH = 1.25e18;
  /// @notice Maximum value the liquidator can send and still have granular control of max assets.
  /// Above this threshold, they should send `type(uint256).max`.
  uint256 public constant ASSETS_THRESHOLD = type(uint256).max / 1e18;

  /// @notice Decimals that the answer of all price feeds should have.
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  uint256 public immutable priceDecimals;
  /// @notice Base factor to scale the price returned by the feed to 18 decimals.
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  uint256 internal immutable baseFactor;
  /// @notice Base price used if the feed to fetch the price from is `BASE_FEED`.
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  uint256 internal immutable basePrice;

  /// @notice Tracks the markets' indexes that an account has entered as collateral.
  mapping(address => uint256) public accountMarkets;
  /// @notice Stores market parameters per each enabled market.
  mapping(Market => MarketData) public markets;
  /// @notice Array of all enabled markets.
  Market[] public marketList;

  /// @notice Liquidation incentive factors for the liquidator and the lenders of the market where the debt is repaid.
  LiquidationIncentive public liquidationIncentive;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(uint256 priceDecimals_) {
    priceDecimals = priceDecimals_;
    baseFactor = 10**(18 - priceDecimals_);
    basePrice = 10**priceDecimals_;

    _disableInitializers();
  }

  /// @notice Initializes the contract.
  /// @dev can only be called once.
  function initialize(LiquidationIncentive memory liquidationIncentive_) external initializer {
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    setLiquidationIncentive(liquidationIncentive_);
  }

  /// @notice Allows assets of a certain market to be used as collateral for borrowing other assets.
  /// @param market market to enabled as collateral.
  function enterMarket(Market market) external {
    MarketData storage m = markets[market];
    if (!m.isListed) revert MarketNotListed();

    uint256 marketMap = accountMarkets[msg.sender];
    uint256 marketMask = 1 << m.index;

    if ((marketMap & marketMask) != 0) return;
    accountMarkets[msg.sender] = marketMap | marketMask;

    emit MarketEntered(market, msg.sender);
  }

  /// @notice Removes market from sender's account liquidity calculation.
  /// @dev Sender must not have an outstanding borrow balance in the asset, or be providing necessary collateral
  /// for an outstanding borrow.
  /// @param market market to be disabled as collateral.
  function exitMarket(Market market) external {
    MarketData storage m = markets[market];
    if (!m.isListed) revert MarketNotListed();

    (uint256 assets, uint256 debt) = market.accountSnapshot(msg.sender);

    // fail if the sender has a borrow balance
    if (debt != 0) revert RemainingDebt();

    // fail if the sender is not permitted to redeem all of their assets
    checkShortfall(market, msg.sender, assets);

    uint256 marketMap = accountMarkets[msg.sender];
    uint256 marketMask = 1 << m.index;

    if ((marketMap & marketMask) == 0) return;
    accountMarkets[msg.sender] = marketMap & ~marketMask;

    emit MarketExited(market, msg.sender);
  }

  /// @notice Returns account's liquidity calculation.
  /// @param account account in which the liquidity will be calculated.
  /// @param marketToSimulate market in which to simulate withdraw operation.
  /// @param withdrawAmount amount to simulate as withdraw.
  /// @return sumCollateral sum of all collateral, already multiplied by each adjust factor (denominated in base).
  /// @return sumDebtPlusEffects sum of all debt divided by adjust factor considering withdrawal (denominated in base).
  function accountLiquidity(
    address account,
    Market marketToSimulate,
    uint256 withdrawAmount
  ) public view returns (uint256 sumCollateral, uint256 sumDebtPlusEffects) {
    AccountLiquidity memory vars; // holds all our calculation results

    // for each asset the account is in
    uint256 marketMap = accountMarkets[account];
    for (uint256 i = 0; marketMap != 0; marketMap >>= 1) {
      if (marketMap & 1 != 0) {
        Market market = marketList[i];
        MarketData storage m = markets[market];
        uint256 baseUnit = 10**m.decimals;
        uint256 adjustFactor = m.adjustFactor;

        // read the balances
        (vars.balance, vars.borrowBalance) = market.accountSnapshot(account);

        // get the normalized price of the asset (18 decimals)
        vars.price = assetPrice(m.priceFeed);

        // sum all the collateral prices
        sumCollateral += vars.balance.mulDivDown(vars.price, baseUnit).mulWadDown(adjustFactor);

        // sum all the debt
        sumDebtPlusEffects += vars.borrowBalance.mulDivUp(vars.price, baseUnit).divWadUp(adjustFactor);

        // simulate the effects of withdrawing from a pool
        if (market == marketToSimulate) {
          // calculate the effects of redeeming markets
          // (having less collateral is the same as having more debt for this calculation)
          if (withdrawAmount != 0) {
            sumDebtPlusEffects += withdrawAmount.mulDivDown(vars.price, baseUnit).mulWadDown(adjustFactor);
          }
        }
      }
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Validates that the current state of the position and system are valid.
  /// @dev To be called after adding the borrowed debt to the account position.
  /// @param market address of the market where the borrow is made.
  /// @param borrower address of the account that will repay the debt.
  function checkBorrow(Market market, address borrower) external {
    MarketData storage m = markets[market];
    if (!m.isListed) revert MarketNotListed();

    uint256 marketMap = accountMarkets[borrower];
    uint256 marketMask = 1 << m.index;

    // validate borrow state
    if ((marketMap & marketMask) == 0) {
      // only markets may call checkBorrow if borrower not in market
      if (msg.sender != address(market)) revert NotMarket();

      accountMarkets[borrower] = marketMap | marketMask;
      emit MarketEntered(market, borrower);
    }

    // verify that current liquidity is not short
    (uint256 collateral, uint256 debt) = accountLiquidity(borrower, Market(address(0)), 0);
    if (collateral < debt) revert InsufficientAccountLiquidity();
  }

  /// @notice Checks if the account has liquidity shortfall.
  /// @param market address of the market where the operation will happen.
  /// @param account address of the account to check for possible shortfall.
  /// @param amount amount that the account wants to withdraw or transfer.
  function checkShortfall(
    Market market,
    address account,
    uint256 amount
  ) public view {
    // if the account is not 'in' the market, bypass the liquidity check
    if ((accountMarkets[account] & (1 << markets[market].index)) == 0) return;

    // otherwise, perform a hypothetical liquidity check to guard against shortfall
    (uint256 collateral, uint256 debt) = accountLiquidity(account, market, amount);
    if (collateral < debt) revert InsufficientAccountLiquidity();
  }

  /// @notice Allows/rejects liquidation of assets.
  /// @dev This function can be called externally, but only will have effect when called from a market.
  /// @param repayMarket market from where the debt is being repaid.
  /// @param seizeMarket market from where the liquidator will seize assets.
  /// @param borrower address in which the assets are being liquidated.
  /// @param maxLiquidatorAssets maximum amount of debt the liquidator is willing to accept.
  /// @return maxRepayAssets capped amount of debt the liquidator is allowed to repay.
  function checkLiquidation(
    Market repayMarket,
    Market seizeMarket,
    address borrower,
    uint256 maxLiquidatorAssets
  ) external view returns (uint256 maxRepayAssets) {
    // if markets are listed, they have the same auditor
    if (!markets[repayMarket].isListed || !markets[seizeMarket].isListed) revert MarketNotListed();

    MarketVars memory repay;
    LiquidityVars memory base;
    uint256 marketMap = accountMarkets[borrower];
    for (uint256 i = 0; marketMap != 0; marketMap >>= 1) {
      if (marketMap & 1 != 0) {
        Market market = marketList[i];
        MarketData storage marketData = markets[market];
        MarketVars memory m = MarketVars({
          price: assetPrice(marketData.priceFeed),
          adjustFactor: marketData.adjustFactor,
          baseUnit: 10**marketData.decimals
        });

        if (market == repayMarket) repay = m;

        (uint256 collateral, uint256 debt) = market.accountSnapshot(borrower);

        uint256 value = debt.mulDivUp(m.price, m.baseUnit);
        base.totalDebt += value;
        base.adjustedDebt += value.divWadUp(m.adjustFactor);

        value = collateral.mulDivDown(m.price, m.baseUnit);
        base.totalCollateral += value;
        base.adjustedCollateral += value.mulWadDown(m.adjustFactor);
        if (market == seizeMarket) base.seizeAvailable = value;
      }
      unchecked {
        ++i;
      }
    }

    if (base.adjustedCollateral >= base.adjustedDebt) revert InsufficientShortfall();

    LiquidationIncentive memory memIncentive = liquidationIncentive;
    uint256 adjustFactor = base.adjustedCollateral.mulWadDown(base.totalDebt).divWadUp(
      base.adjustedDebt.mulWadUp(base.totalCollateral)
    );
    uint256 closeFactor = (TARGET_HEALTH - base.adjustedCollateral.divWadUp(base.adjustedDebt)).divWadUp(
      TARGET_HEALTH - adjustFactor.mulWadDown(1e18 + memIncentive.liquidator + memIncentive.lenders)
    );
    maxRepayAssets = Math.min(
      Math
        .min(
          base.totalDebt.mulWadUp(Math.min(1e18, closeFactor)),
          base.seizeAvailable.divWadUp(1e18 + memIncentive.liquidator + memIncentive.lenders)
        )
        .mulDivUp(repay.baseUnit, repay.price),
      maxLiquidatorAssets < ASSETS_THRESHOLD
        ? maxLiquidatorAssets.divWadDown(1e18 + memIncentive.lenders)
        : maxLiquidatorAssets
    );
  }

  /// @notice Allow/rejects seizing of assets.
  /// @dev This function can be called externally, but only will have effect when called from a market.
  /// @param repayMarket market from where the debt will be repaid.
  /// @param seizeMarket market where the assets will be seized.
  function checkSeize(Market repayMarket, Market seizeMarket) external view {
    // if markets are listed, they also point to the same Auditor
    if (!markets[seizeMarket].isListed || !markets[repayMarket].isListed) revert MarketNotListed();
  }

  /// @notice Calculates the amount of collateral to be seized when a position is undercollateralized.
  /// @param repayMarket market from where the debt will be repaid.
  /// @param seizeMarket market from where the assets will be seized by the liquidator.
  /// @param borrower account in which assets are being seized.
  /// @param actualRepayAssets amount being repaid.
  /// @return lendersAssets amount to be added for other lenders as a compensation of bad debt clearing.
  /// @return seizeAssets amount that can be seized by the liquidator.
  function calculateSeize(
    Market repayMarket,
    Market seizeMarket,
    address borrower,
    uint256 actualRepayAssets
  ) external view returns (uint256 lendersAssets, uint256 seizeAssets) {
    LiquidationIncentive memory memIncentive = liquidationIncentive;
    lendersAssets = actualRepayAssets.mulWadDown(memIncentive.lenders);

    // read prices for borrowed and collateral markets
    uint256 priceBorrowed = assetPrice(markets[repayMarket].priceFeed);
    uint256 priceCollateral = assetPrice(markets[seizeMarket].priceFeed);
    uint256 baseAmount = actualRepayAssets.mulDivUp(priceBorrowed, 10**markets[repayMarket].decimals);

    seizeAssets = Math.min(
      baseAmount.mulDivUp(10**markets[seizeMarket].decimals, priceCollateral).mulWadUp(
        1e18 + memIncentive.liquidator + memIncentive.lenders
      ),
      seizeMarket.maxWithdraw(borrower)
    );
  }

  /// @notice Checks if account has debt with no collateral, if so then call `clearBadDebt` from each market.
  /// @dev Collateral is multiplied by price and adjust factor to be accurately evaluated as positive collateral asset.
  /// @param account account in which debt is being checked.
  function handleBadDebt(address account) external {
    uint256 memMarketMap = accountMarkets[account];
    uint256 marketMap = memMarketMap;
    for (uint256 i = 0; marketMap != 0; marketMap >>= 1) {
      if (marketMap & 1 != 0) {
        Market market = marketList[i];
        MarketData storage m = markets[market];
        uint256 assets = market.maxWithdraw(account);
        if (assets.mulDivDown(assetPrice(m.priceFeed), 10**m.decimals).mulWadDown(m.adjustFactor) > 0) return;
      }
      unchecked {
        ++i;
      }
    }

    marketMap = memMarketMap;
    for (uint256 i = 0; marketMap != 0; marketMap >>= 1) {
      if (marketMap & 1 != 0) marketList[i].clearBadDebt(account);
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Gets the asset price of a price feed.
  /// @dev If Chainlink's asset price is <= 0 the call is reverted.
  /// @param priceFeed address of Chainlink's Price Feed aggregator used to query the asset price.
  /// @return The price of the asset scaled to 18-digit decimals.
  function assetPrice(IPriceFeed priceFeed) public view returns (uint256) {
    if (address(priceFeed) == BASE_FEED) return basePrice;

    int256 price = priceFeed.latestAnswer();
    if (price <= 0) revert InvalidPrice();
    return uint256(price) * baseFactor;
  }

  /// @notice Retrieves all markets.
  function allMarkets() external view returns (Market[] memory) {
    return marketList;
  }

  /// @notice Enables a certain market.
  /// @dev Enabling more than 256 markets will cause an overflow when casting market index to uint8.
  /// @param market market to add to the protocol.
  /// @param priceFeed address of Chainlink's Price Feed aggregator used to query the asset price in base.
  /// @param adjustFactor market's adjust factor for the underlying asset.
  /// @param decimals decimals of the market's underlying asset.
  function enableMarket(
    Market market,
    IPriceFeed priceFeed,
    uint128 adjustFactor,
    uint8 decimals
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (market.auditor() != this) revert AuditorMismatch();
    if (markets[market].isListed) revert MarketAlreadyListed();
    if (address(priceFeed) != BASE_FEED && priceFeed.decimals() != priceDecimals) revert InvalidPriceFeed();

    markets[market] = MarketData({
      isListed: true,
      adjustFactor: adjustFactor,
      decimals: decimals,
      index: uint8(marketList.length),
      priceFeed: priceFeed
    });

    marketList.push(market);

    emit MarketListed(market, decimals);
    emit PriceFeedSet(market, priceFeed);
    emit AdjustFactorSet(market, adjustFactor);
  }

  /// @notice Sets the adjust factor for a certain market.
  /// @param market address of the market to change adjust factor for.
  /// @param adjustFactor adjust factor for the underlying asset.
  function setAdjustFactor(Market market, uint128 adjustFactor) public onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!markets[market].isListed) revert MarketNotListed();

    markets[market].adjustFactor = adjustFactor;
    emit AdjustFactorSet(market, adjustFactor);
  }

  /// @notice Sets the Chainlink Price Feed Aggregator source for a market.
  /// @param market market address of the asset.
  /// @param priceFeed address of Chainlink's Price Feed aggregator used to query the asset price in base.
  function setPriceFeed(Market market, IPriceFeed priceFeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (address(priceFeed) != BASE_FEED && priceFeed.decimals() != priceDecimals) revert InvalidPriceFeed();
    markets[market].priceFeed = priceFeed;
    emit PriceFeedSet(market, priceFeed);
  }

  /// @notice Sets liquidation incentive (liquidator and lenders) for the whole ecosystem.
  /// @param liquidationIncentive_ new liquidation incentive.
  function setLiquidationIncentive(LiquidationIncentive memory liquidationIncentive_)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    liquidationIncentive = liquidationIncentive_;
    emit LiquidationIncentiveSet(liquidationIncentive_);
  }

  /// @notice Emitted when a new market is listed for borrow/lending.
  /// @param market address of the market that was listed.
  /// @param decimals decimals of the market's underlying asset.
  event MarketListed(Market indexed market, uint8 decimals);

  /// @notice Emitted when an account enters a market to use his deposit as collateral for a loan.
  /// @param market address of the market that the account entered.
  /// @param account address of the account that just entered a market.
  event MarketEntered(Market indexed market, address indexed account);

  /// @notice Emitted when an account leaves a market.
  /// Means that they would stop using their deposit as collateral and won't ask for any loans in this market.
  /// @param market address of the market that the account just left.
  /// @param account address of the account that just left a market.
  event MarketExited(Market indexed market, address indexed account);

  /// @notice Emitted when a adjust factor is changed by admin.
  /// @param market address of the market that has a new adjust factor.
  /// @param adjustFactor adjust factor for the underlying asset.
  event AdjustFactorSet(Market indexed market, uint256 adjustFactor);

  /// @notice Emitted when a new liquidationIncentive has been set.
  /// @param liquidationIncentive represented with 18 decimals.
  event LiquidationIncentiveSet(LiquidationIncentive liquidationIncentive);

  /// @notice Emitted when a market and prie feed is changed by admin.
  /// @param market address of the asset used to get the price.
  /// @param priceFeed address of Chainlink's Price Feed aggregator used to query the asset price in base.
  event PriceFeedSet(Market indexed market, IPriceFeed indexed priceFeed);

  /// @notice Stores the market parameters used for liquidity calculations.
  /// @param adjustFactor used to asses the lending power of the market's underlying asset.
  /// @param decimals number of decimals of the market's underlying asset.
  /// @param index index of the market in the `marketList`.
  /// @param isListed true if the market is enabled.
  /// @param priceFeed address of the price feed used to query the asset's price.
  struct MarketData {
    uint128 adjustFactor;
    uint8 decimals;
    uint8 index;
    bool isListed;
    IPriceFeed priceFeed;
  }

  /// @notice Stores the liquidator and lenders factors used in liquidations to calculate the amount to seize.
  /// @param liquidator factor used to calculate the extra bonus a liquidator can seize.
  /// @param lenders factor used to calculate the bonus that the pool lenders receive.
  struct LiquidationIncentive {
    uint128 liquidator;
    uint128 lenders;
  }

  /// @notice Used as memory access to temporary store account liquidity data.
  /// @param balance collateral balance of the account.
  /// @param borrowBalance borrow balance of the account.
  /// @param price asset price returned by the price feed with 18 decimals.
  struct AccountLiquidity {
    uint256 balance;
    uint256 borrowBalance;
    uint256 price;
  }
}

error AuditorMismatch();
error InsufficientAccountLiquidity();
error InsufficientShortfall();
error InvalidPrice();
error InvalidPriceFeed();
error MarketAlreadyListed();
error MarketNotListed();
error NotMarket();
error RemainingDebt();

struct MarketVars {
  uint256 price;
  uint256 baseUnit;
  uint128 adjustFactor;
}

struct LiquidityVars {
  uint256 totalDebt;
  uint256 totalCollateral;
  uint256 adjustedDebt;
  uint256 adjustedCollateral;
  uint256 seizeAvailable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";

contract InterestRateModel {
  using FixedPointMathLib for uint256;
  using FixedPointMathLib for int256;

  /// @notice Threshold to define which method should be used to calculate the interest rates.
  /// @dev When `eta` (`delta / alpha`) is lower than this value, use simpson's rule for approximation.
  uint256 internal constant PRECISION_THRESHOLD = 7.5e14;

  /// @notice Scale factor of the fixed curve.
  uint256 public immutable fixedCurveA;
  /// @notice Origin intercept of the fixed curve.
  int256 public immutable fixedCurveB;
  /// @notice Asymptote of the fixed curve.
  uint256 public immutable fixedMaxUtilization;

  /// @notice Scale factor of the floating curve.
  uint256 public immutable floatingCurveA;
  /// @notice Origin intercept of the floating curve.
  int256 public immutable floatingCurveB;
  /// @notice Asymptote of the floating curve.
  uint256 public immutable floatingMaxUtilization;

  constructor(
    uint256 fixedCurveA_,
    int256 fixedCurveB_,
    uint256 fixedMaxUtilization_,
    uint256 floatingCurveA_,
    int256 floatingCurveB_,
    uint256 floatingMaxUtilization_
  ) {
    fixedCurveA = fixedCurveA_;
    fixedCurveB = fixedCurveB_;
    fixedMaxUtilization = fixedMaxUtilization_;

    floatingCurveA = floatingCurveA_;
    floatingCurveB = floatingCurveB_;
    floatingMaxUtilization = floatingMaxUtilization_;

    // reverts if it's an invalid curve (such as one yielding a negative interest rate).
    fixedRate(0, 0);
    floatingRate(0, 0);
  }

  /// @notice Gets the rate to borrow a certain amount at a certain maturity with supply/demand values in the fixed rate
  /// pool and assets from the backup supplier.
  /// @param maturity maturity date for calculating days left to maturity.
  /// @param amount the current borrow's amount.
  /// @param borrowed ex-ante amount borrowed from this fixed rate pool.
  /// @param supplied deposits in the fixed rate pool.
  /// @param backupAssets backup supplier assets.
  /// @return rate of the fee that the borrower will have to pay (represented with 18 decimals).
  function fixedBorrowRate(
    uint256 maturity,
    uint256 amount,
    uint256 borrowed,
    uint256 supplied,
    uint256 backupAssets
  ) external view returns (uint256) {
    if (block.timestamp >= maturity) revert AlreadyMatured();

    uint256 potentialAssets = supplied + backupAssets;
    uint256 utilizationAfter = (borrowed + amount).divWadUp(potentialAssets);

    if (utilizationAfter > 1e18) revert UtilizationExceeded();

    uint256 utilizationBefore = borrowed.divWadDown(potentialAssets);

    return fixedRate(utilizationBefore, utilizationAfter).mulDivDown(maturity - block.timestamp, 365 days);
  }

  /// @notice Returns the interest rate integral from utilizationBefore to utilizationAfter.
  /// @dev Minimum and maximum checks to avoid negative rate.
  /// @param utilizationBefore ex-ante utilization rate, with 18 decimals precision.
  /// @param utilizationAfter ex-post utilization rate, with 18 decimals precision.
  /// @return the interest rate, with 18 decimals precision.
  function floatingBorrowRate(uint256 utilizationBefore, uint256 utilizationAfter) external view returns (uint256) {
    if (utilizationAfter > 1e18) revert UtilizationExceeded();

    return floatingRate(Math.min(utilizationBefore, utilizationAfter), Math.max(utilizationBefore, utilizationAfter));
  }

  /// @notice Returns the interest rate integral from `u0` to `u1`, using the analytical solution (ln).
  /// @dev Uses the fixed rate curve parameters.
  /// Handles special case where delta utilization tends to zero, using simpson's rule.
  /// @param utilizationBefore ex-ante utilization rate, with 18 decimals precision.
  /// @param utilizationAfter ex-post utilization rate, with 18 decimals precision.
  /// @return the interest rate, with 18 decimals precision.
  function fixedRate(uint256 utilizationBefore, uint256 utilizationAfter) internal view returns (uint256) {
    uint256 alpha = fixedMaxUtilization - utilizationBefore;
    uint256 delta = utilizationAfter - utilizationBefore;
    int256 r = int256(
      delta.divWadDown(alpha) < PRECISION_THRESHOLD
        ? (fixedCurveA.divWadDown(alpha) +
          fixedCurveA.mulDivDown(4e18, fixedMaxUtilization - ((utilizationAfter + utilizationBefore) / 2)) +
          fixedCurveA.divWadDown(fixedMaxUtilization - utilizationAfter)) / 6
        : fixedCurveA.mulDivDown(
          uint256(int256(alpha.divWadDown(fixedMaxUtilization - utilizationAfter)).lnWad()),
          delta
        )
    ) + fixedCurveB;
    assert(r >= 0);
    return uint256(r);
  }

  /// @notice Returns the interest rate integral from `u0` to `u1`, using the analytical solution (ln).
  /// @dev Uses the floating rate curve parameters.
  /// Handles special case where delta utilization tends to zero, using simpson's rule.
  /// @param utilizationBefore ex-ante utilization rate, with 18 decimals precision.
  /// @param utilizationAfter ex-post utilization rate, with 18 decimals precision.
  /// @return the interest rate, with 18 decimals precision.
  function floatingRate(uint256 utilizationBefore, uint256 utilizationAfter) internal view returns (uint256) {
    uint256 alpha = floatingMaxUtilization - utilizationBefore;
    uint256 delta = utilizationAfter - utilizationBefore;
    int256 r = int256(
      delta.divWadDown(alpha) < PRECISION_THRESHOLD
        ? (floatingCurveA.divWadDown(alpha) +
          floatingCurveA.mulDivDown(4e18, floatingMaxUtilization - ((utilizationAfter + utilizationBefore) / 2)) +
          floatingCurveA.divWadDown(floatingMaxUtilization - utilizationAfter)) / 6
        : floatingCurveA.mulDivDown(
          uint256(int256(alpha.divWadDown(floatingMaxUtilization - utilizationAfter)).lnWad()),
          delta
        )
    ) + floatingCurveB;
    assert(r >= 0);
    return uint256(r);
  }
}

error AlreadyMatured();
error UtilizationExceeded();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC4626, ERC20, SafeTransferLib } from "solmate/src/mixins/ERC4626.sol";
import { InterestRateModel } from "./InterestRateModel.sol";
import { FixedLib } from "./utils/FixedLib.sol";
import { Auditor } from "./Auditor.sol";

contract Market is Initializable, AccessControlUpgradeable, PausableUpgradeable, ERC4626 {
  using FixedPointMathLib for int256;
  using FixedPointMathLib for uint256;
  using FixedPointMathLib for uint128;
  using SafeTransferLib for ERC20;
  using FixedLib for FixedLib.Pool;
  using FixedLib for FixedLib.Position;
  using FixedLib for uint256;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  Auditor public immutable auditor;

  /// @notice Tracks account's fixed deposit positions by maturity, account and position.
  mapping(uint256 => mapping(address => FixedLib.Position)) public fixedDepositPositions;
  /// @notice Tracks account's fixed borrow positions by maturity, account and position.
  mapping(uint256 => mapping(address => FixedLib.Position)) public fixedBorrowPositions;
  /// @notice Tracks fixed pools state by maturity.
  mapping(uint256 => FixedLib.Pool) public fixedPools;

  /// @notice Tracks fixed deposit and borrow map and floating borrow shares of an account.
  mapping(address => Account) public accounts;

  /// @notice Amount of assets lent by the floating pool to the fixed pools.
  uint256 public floatingBackupBorrowed;
  /// @notice Amount of assets lent by the floating pool to accounts.
  uint256 public floatingDebt;

  /// @notice Accumulated earnings from extraordinary sources to be gradually distributed.
  uint256 public earningsAccumulator;
  /// @notice Rate per second to be charged to delayed fixed pools borrowers after maturity.
  uint256 public penaltyRate;
  /// @notice Rate charged to the fixed pool to be retained by the floating pool for initially providing liquidity.
  uint256 public backupFeeRate;
  /// @notice Damp speed factor to update `floatingAssetsAverage` when `floatingAssets` is higher.
  uint256 public dampSpeedUp;
  /// @notice Damp speed factor to update `floatingAssetsAverage` when `floatingAssets` is lower.
  uint256 public dampSpeedDown;

  /// @notice Number of fixed pools to be active at the same time.
  uint8 public maxFuturePools;
  /// @notice Last time the accumulator distributed earnings.
  uint32 public lastAccumulatorAccrual;
  /// @notice Last time the floating debt was updated.
  uint32 public lastFloatingDebtUpdate;
  /// @notice Last time the floating assets average was updated.
  uint32 public lastAverageUpdate;

  /// @notice Interest rate model contract used to get the borrow rates.
  InterestRateModel public interestRateModel;

  /// @notice Factor used for gradual accrual of earnings to the floating pool.
  uint128 public earningsAccumulatorSmoothFactor;
  /// @notice Percentage factor that represents the liquidity reserves that can't be borrowed.
  uint128 public reserveFactor;

  /// @notice Amount of floating assets deposited to the pool.
  uint256 public floatingAssets;
  /// @notice Average of the floating assets to get fixed borrow rates and prevent rate manipulation.
  uint256 public floatingAssetsAverage;

  /// @notice Total amount of floating borrow shares assigned to floating borrow accounts.
  uint256 public totalFloatingBorrowShares;
  /// @notice Current floating utilization used to get the new floating borrow rate.
  uint256 public floatingUtilization;

  /// @notice Address of the treasury that will receive the allocated earnings.
  address public treasury;
  /// @notice Rate to be charged by the treasury to floating and fixed borrows.
  uint256 public treasuryFeeRate;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(ERC20 asset_, Auditor auditor_) ERC4626(asset_, "", "") {
    auditor = auditor_;

    _disableInitializers();
  }

  /// @notice Initializes the contract.
  /// @dev can only be called once.
  function initialize(
    uint8 maxFuturePools_,
    uint128 earningsAccumulatorSmoothFactor_,
    InterestRateModel interestRateModel_,
    uint256 penaltyRate_,
    uint256 backupFeeRate_,
    uint128 reserveFactor_,
    uint256 dampSpeedUp_,
    uint256 dampSpeedDown_
  ) external initializer {
    __AccessControl_init();
    __Pausable_init();

    string memory assetSymbol = asset.symbol();
    name = string.concat("exactly ", assetSymbol);
    symbol = string.concat("e", assetSymbol);
    lastAccumulatorAccrual = uint32(block.timestamp);
    lastFloatingDebtUpdate = uint32(block.timestamp);
    lastAverageUpdate = uint32(block.timestamp);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    setMaxFuturePools(maxFuturePools_);
    setEarningsAccumulatorSmoothFactor(earningsAccumulatorSmoothFactor_);
    setInterestRateModel(interestRateModel_);
    setPenaltyRate(penaltyRate_);
    setBackupFeeRate(backupFeeRate_);
    setReserveFactor(reserveFactor_);
    setDampSpeed(dampSpeedUp_, dampSpeedDown_);
  }

  /// @notice Borrows a certain amount from the floating pool.
  /// @param assets amount to be sent to receiver and repaid by borrower.
  /// @param receiver address that will receive the borrowed assets.
  /// @param borrower address that will repay the borrowed assets.
  /// @return borrowShares shares corresponding to the borrowed assets.
  function borrow(
    uint256 assets,
    address receiver,
    address borrower
  ) external whenNotPaused returns (uint256 borrowShares) {
    spendAllowance(borrower, assets);

    depositToTreasury(updateFloatingDebt());

    borrowShares = previewBorrow(assets);

    uint256 newFloatingDebt = floatingDebt + assets;
    floatingDebt = newFloatingDebt;
    // check if the underlying liquidity that the account wants to withdraw is borrowed, also considering the reserves
    if (floatingBackupBorrowed + newFloatingDebt > floatingAssets.mulWadDown(1e18 - reserveFactor)) {
      revert InsufficientProtocolLiquidity();
    }

    totalFloatingBorrowShares += borrowShares;
    accounts[borrower].floatingBorrowShares += borrowShares;

    emit Borrow(msg.sender, receiver, borrower, assets, borrowShares);
    emitMarketUpdate();

    auditor.checkBorrow(this, borrower);
    asset.safeTransfer(receiver, assets);
  }

  /// @notice Repays a certain amount of assets to the floating pool.
  /// @param assets assets to be subtracted from the borrower's accountability.
  /// @param borrower address of the account that has the debt.
  /// @return actualRepay the actual amount that should be transferred into the protocol.
  /// @return borrowShares subtracted shares from the borrower's accountability.
  function repay(uint256 assets, address borrower)
    external
    whenNotPaused
    returns (uint256 actualRepay, uint256 borrowShares)
  {
    (actualRepay, borrowShares) = noTransferRefund(previewRepay(assets), borrower);
    emitMarketUpdate();
    asset.safeTransferFrom(msg.sender, address(this), actualRepay);
  }

  /// @notice Repays a certain amount of shares to the floating pool.
  /// @param borrowShares shares to be subtracted from the borrower's accountability.
  /// @param borrower address of the account that has the debt.
  /// @return assets subtracted assets from the borrower's accountability.
  /// @return actualShares actual subtracted shares from the borrower's accountability.
  function refund(uint256 borrowShares, address borrower)
    external
    whenNotPaused
    returns (uint256 assets, uint256 actualShares)
  {
    (assets, actualShares) = noTransferRefund(borrowShares, borrower);
    emitMarketUpdate();
    asset.safeTransferFrom(msg.sender, address(this), assets);
  }

  /// @notice Allows to (partially) repay a floating borrow. It does not transfer assets.
  /// @param borrowShares shares to be subtracted from the borrower's accountability.
  /// @param borrower the address of the account that has the debt.
  /// @return assets the actual amount that should be transferred into the protocol.
  /// @return actualShares actual subtracted shares from the borrower's accountability.
  function noTransferRefund(uint256 borrowShares, address borrower)
    internal
    returns (uint256 assets, uint256 actualShares)
  {
    depositToTreasury(updateFloatingDebt());
    Account storage account = accounts[borrower];
    uint256 accountBorrowShares = account.floatingBorrowShares;
    actualShares = Math.min(borrowShares, accountBorrowShares);
    assets = previewRefund(actualShares);

    if (assets == 0) revert ZeroRepay();

    floatingDebt -= assets;
    account.floatingBorrowShares = accountBorrowShares - actualShares;
    totalFloatingBorrowShares -= actualShares;

    emit Repay(msg.sender, borrower, assets, actualShares);
  }

  /// @notice Deposits a certain amount to a maturity.
  /// @param maturity maturity date where the assets will be deposited.
  /// @param assets amount to receive from the msg.sender.
  /// @param minAssetsRequired minimum amount of assets required by the depositor for the transaction to be accepted.
  /// @param receiver address that will be able to withdraw the deposited assets.
  /// @return positionAssets total amount of assets (principal + fee) to be withdrawn at maturity.
  function depositAtMaturity(
    uint256 maturity,
    uint256 assets,
    uint256 minAssetsRequired,
    address receiver
  ) external whenNotPaused returns (uint256 positionAssets) {
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.NONE);

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    (uint256 fee, uint256 backupFee) = pool.calculateDeposit(assets, backupFeeRate);
    positionAssets = assets + fee;
    if (positionAssets < minAssetsRequired) revert Disagreement();

    floatingBackupBorrowed -= pool.deposit(assets);
    pool.unassignedEarnings -= fee + backupFee;
    earningsAccumulator += backupFee;

    // update account's position
    FixedLib.Position storage position = fixedDepositPositions[maturity][receiver];

    // if account doesn't have a current position, add it to the list
    if (position.principal == 0) {
      Account storage account = accounts[receiver];
      account.fixedDeposits = account.fixedDeposits.setMaturity(maturity);
    }

    position.principal += assets;
    position.fee += fee;

    floatingAssets += backupEarnings;

    emit DepositAtMaturity(maturity, msg.sender, receiver, assets, fee);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);

    asset.safeTransferFrom(msg.sender, address(this), assets);
  }

  /// @notice Borrows a certain amount from a maturity.
  /// @param maturity maturity date for repayment.
  /// @param assets amount to be sent to receiver and repaid by borrower.
  /// @param maxAssets maximum amount of debt that the account is willing to accept.
  /// @param receiver address that will receive the borrowed assets.
  /// @param borrower address that will repay the borrowed assets.
  /// @return assetsOwed total amount of assets (principal + fee) to be repaid at maturity.
  function borrowAtMaturity(
    uint256 maturity,
    uint256 assets,
    uint256 maxAssets,
    address receiver,
    address borrower
  ) external whenNotPaused returns (uint256 assetsOwed) {
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.NONE);

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    uint256 fee = assets.mulWadDown(
      interestRateModel.fixedBorrowRate(maturity, assets, pool.borrowed, pool.supplied, previewFloatingAssetsAverage())
    );
    assetsOwed = assets + fee;

    // validate that the account is not taking arbitrary fees
    if (assetsOwed > maxAssets) revert Disagreement();

    spendAllowance(borrower, assetsOwed);

    {
      uint256 backupDebtAddition = pool.borrow(assets);
      if (backupDebtAddition > 0) {
        uint256 newFloatingBackupBorrowed = floatingBackupBorrowed + backupDebtAddition;
        depositToTreasury(updateFloatingDebt());
        if (newFloatingBackupBorrowed + floatingDebt > floatingAssets.mulWadDown(1e18 - reserveFactor)) {
          revert InsufficientProtocolLiquidity();
        }
        floatingBackupBorrowed = newFloatingBackupBorrowed;
      }
    }

    {
      // if account doesn't have a current position, add it to the list
      FixedLib.Position storage position = fixedBorrowPositions[maturity][borrower];
      if (position.principal == 0) {
        Account storage account = accounts[borrower];
        account.fixedBorrows = account.fixedBorrows.setMaturity(maturity);
      }

      // calculate what portion of the fees are to be accrued and what portion goes to earnings accumulator
      (uint256 newUnassignedEarnings, uint256 newBackupEarnings) = pool.distributeEarnings(
        chargeTreasuryFee(fee),
        assets
      );
      if (newUnassignedEarnings > 0) pool.unassignedEarnings += newUnassignedEarnings;
      collectFreeLunch(newBackupEarnings);

      fixedBorrowPositions[maturity][borrower] = FixedLib.Position(position.principal + assets, position.fee + fee);
    }

    floatingAssets += backupEarnings;

    emit BorrowAtMaturity(maturity, msg.sender, receiver, borrower, assets, fee);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);

    auditor.checkBorrow(this, borrower);
    asset.safeTransfer(receiver, assets);
  }

  /// @notice Withdraws a certain amount from a maturity.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// @param maturity maturity date where the assets will be withdrawn.
  /// @param positionAssets position size to be reduced.
  /// @param minAssetsRequired minimum amount required by the account (if discount included for early withdrawal).
  /// @param receiver address that will receive the withdrawn assets.
  /// @param owner address that previously deposited the assets.
  /// @return assetsDiscounted amount of assets withdrawn (can include a discount for early withdraw).
  function withdrawAtMaturity(
    uint256 maturity,
    uint256 positionAssets,
    uint256 minAssetsRequired,
    address receiver,
    address owner
  ) external returns (uint256 assetsDiscounted) {
    if (positionAssets == 0) revert ZeroWithdraw();
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.MATURED);

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    FixedLib.Position memory position = fixedDepositPositions[maturity][owner];

    if (positionAssets > position.principal + position.fee) positionAssets = position.principal + position.fee;

    // verify if there are any penalties/fee for the account because of early withdrawal, if so discount
    if (block.timestamp < maturity) {
      assetsDiscounted = positionAssets.divWadDown(
        1e18 +
          interestRateModel.fixedBorrowRate(
            maturity,
            positionAssets,
            pool.borrowed,
            pool.supplied,
            previewFloatingAssetsAverage()
          )
      );
    } else {
      assetsDiscounted = positionAssets;
    }

    if (assetsDiscounted < minAssetsRequired) revert Disagreement();

    spendAllowance(owner, assetsDiscounted);

    {
      // remove the supply from the fixed rate pool
      uint256 newFloatingBackupBorrowed = floatingBackupBorrowed +
        pool.withdraw(
          FixedLib.Position(position.principal, position.fee).scaleProportionally(positionAssets).principal
        );
      if (newFloatingBackupBorrowed + floatingDebt > floatingAssets) revert InsufficientProtocolLiquidity();
      floatingBackupBorrowed = newFloatingBackupBorrowed;
    }

    // all the fees go to unassigned or to the floating pool
    (uint256 unassignedEarnings, uint256 newBackupEarnings) = pool.distributeEarnings(
      chargeTreasuryFee(positionAssets - assetsDiscounted),
      assetsDiscounted
    );
    pool.unassignedEarnings += unassignedEarnings;
    collectFreeLunch(newBackupEarnings);

    // the account gets discounted the full amount
    position.reduceProportionally(positionAssets);
    if (position.principal | position.fee == 0) {
      delete fixedDepositPositions[maturity][owner];
      Account storage account = accounts[owner];
      account.fixedDeposits = account.fixedDeposits.clearMaturity(maturity);
    } else {
      // proportionally reduce the values
      fixedDepositPositions[maturity][owner] = position;
    }

    floatingAssets += backupEarnings;

    emit WithdrawAtMaturity(maturity, msg.sender, receiver, owner, positionAssets, assetsDiscounted);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);

    asset.safeTransfer(receiver, assetsDiscounted);
  }

  /// @notice Repays a certain amount to a maturity.
  /// @param maturity maturity date where the assets will be repaid.
  /// @param positionAssets amount to be paid for the borrower's debt.
  /// @param maxAssets maximum amount of debt that the account is willing to accept to be repaid.
  /// @param borrower address of the account that has the debt.
  /// @return actualRepayAssets the actual amount that was transferred into the protocol.
  function repayAtMaturity(
    uint256 maturity,
    uint256 positionAssets,
    uint256 maxAssets,
    address borrower
  ) external whenNotPaused returns (uint256 actualRepayAssets) {
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.MATURED);

    actualRepayAssets = noTransferRepayAtMaturity(maturity, positionAssets, maxAssets, borrower, true);
    emitMarketUpdate();

    asset.safeTransferFrom(msg.sender, address(this), actualRepayAssets);
  }

  /// @notice Allows to (partially) repay a fixed rate position. It does not transfer assets.
  /// @param maturity the maturity to access the pool.
  /// @param positionAssets the amount of debt of the pool that should be paid.
  /// @param maxAssets maximum amount of debt that the account is willing to accept to be repaid.
  /// @param borrower the address of the account that has the debt.
  /// @param canDiscount should early repay discounts be applied.
  /// @return actualRepayAssets the actual amount that should be transferred into the protocol.
  function noTransferRepayAtMaturity(
    uint256 maturity,
    uint256 positionAssets,
    uint256 maxAssets,
    address borrower,
    bool canDiscount
  ) internal returns (uint256 actualRepayAssets) {
    if (positionAssets == 0) revert ZeroRepay();

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    FixedLib.Position memory position = fixedBorrowPositions[maturity][borrower];

    uint256 debtCovered = Math.min(positionAssets, position.principal + position.fee);

    uint256 principalCovered = FixedLib
      .Position(position.principal, position.fee)
      .scaleProportionally(debtCovered)
      .principal;

    // early repayment allows a discount from the unassigned earnings
    if (block.timestamp < maturity) {
      if (canDiscount) {
        // calculate the deposit fee considering the amount of debt the account'll pay
        (uint256 discountFee, uint256 backupFee) = pool.calculateDeposit(principalCovered, backupFeeRate);

        // remove the fee from unassigned earnings
        pool.unassignedEarnings -= discountFee + backupFee;

        // the fee charged to the fixed pool supplier goes to the earnings accumulator
        earningsAccumulator += backupFee;

        // the fee gets discounted from the account through `actualRepayAssets`
        actualRepayAssets = debtCovered - discountFee;
      } else {
        actualRepayAssets = debtCovered;
      }
    } else {
      actualRepayAssets = debtCovered + debtCovered.mulWadDown((block.timestamp - maturity) * penaltyRate);

      // all penalties go to the earnings accumulator
      earningsAccumulator += actualRepayAssets - debtCovered;
    }

    // verify that the account agrees to this discount or penalty
    if (actualRepayAssets > maxAssets) revert Disagreement();

    // reduce the borrowed from the pool and might decrease the floating backup borrowed
    floatingBackupBorrowed -= pool.repay(principalCovered);

    // update the account position
    position.reduceProportionally(debtCovered);
    if (position.principal | position.fee == 0) {
      delete fixedBorrowPositions[maturity][borrower];
      Account storage account = accounts[borrower];
      account.fixedBorrows = account.fixedBorrows.clearMaturity(maturity);
    } else {
      // proportionally reduce the values
      fixedBorrowPositions[maturity][borrower] = position;
    }

    floatingAssets += backupEarnings;

    emit RepayAtMaturity(maturity, msg.sender, borrower, actualRepayAssets, debtCovered);
    emitFixedEarningsUpdate(maturity);
  }

  /// @notice Liquidates undercollateralized position(s).
  /// @dev Msg.sender liquidates borrower's position(s) and repays a certain amount of debt for multiple maturities,
  /// seizing a part of borrower's collateral.
  /// @param borrower wallet that has an outstanding debt across all maturities.
  /// @param maxAssets maximum amount of debt that the liquidator is willing to accept. (it can be less)
  /// @param seizeMarket market from which the collateral will be seized to give the liquidator.
  /// @return repaidAssets actual amount repaid.
  function liquidate(
    address borrower,
    uint256 maxAssets,
    Market seizeMarket
  ) external whenNotPaused returns (uint256 repaidAssets) {
    if (msg.sender == borrower) revert SelfLiquidation();

    maxAssets = auditor.checkLiquidation(this, seizeMarket, borrower, maxAssets);
    if (maxAssets == 0) revert ZeroRepay();

    Account storage account = accounts[borrower];

    {
      uint256 packedMaturities = account.fixedBorrows;
      uint256 maturity = packedMaturities & ((1 << 32) - 1);
      packedMaturities = packedMaturities >> 32;
      while (packedMaturities != 0 && maxAssets != 0) {
        if (packedMaturities & 1 != 0) {
          uint256 actualRepay;
          if (block.timestamp < maturity) {
            actualRepay = noTransferRepayAtMaturity(maturity, maxAssets, maxAssets, borrower, false);
            maxAssets -= actualRepay;
          } else {
            uint256 position;
            {
              FixedLib.Position storage p = fixedBorrowPositions[maturity][borrower];
              position = p.principal + p.fee;
            }
            uint256 debt = position + position.mulWadDown((block.timestamp - maturity) * penaltyRate);
            actualRepay = debt > maxAssets ? maxAssets.mulDivDown(position, debt) : maxAssets;

            if (actualRepay == 0) maxAssets = 0;
            else {
              actualRepay = noTransferRepayAtMaturity(maturity, actualRepay, maxAssets, borrower, false);
              maxAssets -= actualRepay;
            }
          }
          repaidAssets += actualRepay;
        }
        packedMaturities >>= 1;
        maturity += FixedLib.INTERVAL;
      }
    }

    if (maxAssets > 0 && account.floatingBorrowShares > 0) {
      uint256 borrowShares = previewRepay(maxAssets);
      if (borrowShares > 0) {
        (uint256 actualRepayAssets, ) = noTransferRefund(borrowShares, borrower);
        repaidAssets += actualRepayAssets;
      }
    }

    // reverts on failure
    (uint256 lendersAssets, uint256 seizeAssets) = auditor.calculateSeize(this, seizeMarket, borrower, repaidAssets);
    earningsAccumulator += lendersAssets;

    if (address(seizeMarket) == address(this)) {
      internalSeize(this, msg.sender, borrower, seizeAssets);
    } else {
      seizeMarket.seize(msg.sender, borrower, seizeAssets);

      emitMarketUpdate();
    }

    emit Liquidate(msg.sender, borrower, repaidAssets, lendersAssets, seizeMarket, seizeAssets);

    auditor.handleBadDebt(borrower);

    asset.safeTransferFrom(msg.sender, address(this), repaidAssets + lendersAssets);
  }

  /// @notice Clears floating and fixed debt for an account spreading the losses to the `earningsAccumulator`.
  /// @dev Can only be called from the auditor.
  /// @param borrower account with insufficient collateral to be cleared the debt.
  function clearBadDebt(address borrower) external {
    if (msg.sender != address(auditor)) revert NotAuditor();

    floatingAssets += accrueAccumulatedEarnings();
    Account storage account = accounts[borrower];
    uint256 accumulator = earningsAccumulator;
    uint256 totalBadDebt = 0;
    uint256 packedMaturities = account.fixedBorrows;
    uint256 maturity = packedMaturities & ((1 << 32) - 1);
    packedMaturities = packedMaturities >> 32;
    while (packedMaturities != 0) {
      if (packedMaturities & 1 != 0) {
        FixedLib.Position storage position = fixedBorrowPositions[maturity][borrower];
        uint256 badDebt = position.principal + position.fee;
        if (accumulator >= badDebt) {
          accumulator -= badDebt;
          totalBadDebt += badDebt;
          floatingBackupBorrowed -= fixedPools[maturity].repay(position.principal);
          delete fixedBorrowPositions[maturity][borrower];
          account.fixedBorrows = account.fixedBorrows.clearMaturity(maturity);

          emit RepayAtMaturity(maturity, msg.sender, borrower, badDebt, badDebt);
        }
      }
      packedMaturities >>= 1;
      maturity += FixedLib.INTERVAL;
    }
    if (account.floatingBorrowShares > 0 && (accumulator = previewRepay(accumulator)) > 0) {
      (uint256 badDebt, ) = noTransferRefund(accumulator, borrower);
      totalBadDebt += badDebt;
    }
    if (totalBadDebt > 0) {
      earningsAccumulator -= totalBadDebt;
      emit SpreadBadDebt(borrower, totalBadDebt);
    }
    emitMarketUpdate();
  }

  /// @notice Public function to seize a certain amount of assets.
  /// @dev Public function for liquidator to seize borrowers assets in the floating pool.
  /// This function will only be called from another Market, on `liquidation` calls.
  /// That's why msg.sender needs to be passed to the private function (to be validated as a market)
  /// @param liquidator address which will receive the seized assets.
  /// @param borrower address from which the assets will be seized.
  /// @param assets amount to be removed from borrower's possession.
  function seize(
    address liquidator,
    address borrower,
    uint256 assets
  ) external whenNotPaused {
    internalSeize(Market(msg.sender), liquidator, borrower, assets);
  }

  /// @notice Internal function to seize a certain amount of assets.
  /// @dev Internal function for liquidator to seize borrowers assets in the floating pool.
  /// Will only be called from this Market on `liquidation` or through `seize` calls from another Market.
  /// That's why msg.sender needs to be passed to the internal function (to be validated as a market).
  /// @param seizeMarket address which is calling the seize function (see `seize` public function).
  /// @param liquidator address which will receive the seized assets.
  /// @param borrower address from which the assets will be seized.
  /// @param assets amount to be removed from borrower's possession.
  function internalSeize(
    Market seizeMarket,
    address liquidator,
    address borrower,
    uint256 assets
  ) internal {
    if (assets == 0) revert ZeroWithdraw();

    // reverts on failure
    auditor.checkSeize(seizeMarket, this);

    uint256 shares = previewWithdraw(assets);
    beforeWithdraw(assets, shares);
    _burn(borrower, shares);
    emit Withdraw(msg.sender, liquidator, borrower, assets, shares);
    emit Seize(liquidator, borrower, assets);
    emitMarketUpdate();

    asset.safeTransfer(liquidator, assets);
  }

  /// @notice Hook to update the floating pool average, floating pool balance and distribute earnings from accumulator.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// @param assets amount of assets to be withdrawn from the floating pool.
  function beforeWithdraw(uint256 assets, uint256) internal override {
    updateFloatingAssetsAverage();
    depositToTreasury(updateFloatingDebt());
    uint256 earnings = accrueAccumulatedEarnings();
    uint256 newFloatingAssets = floatingAssets + earnings - assets;
    // check if the underlying liquidity that the account wants to withdraw is borrowed
    if (floatingBackupBorrowed + floatingDebt > newFloatingAssets) revert InsufficientProtocolLiquidity();
    floatingAssets = newFloatingAssets;
  }

  /// @notice Hook to update the floating pool average, floating pool balance and distribute earnings from accumulator.
  /// @param assets amount of assets to be deposited to the floating pool.
  function afterDeposit(uint256 assets, uint256) internal override whenNotPaused {
    updateFloatingAssetsAverage();
    uint256 treasuryFee = updateFloatingDebt();
    uint256 earnings = accrueAccumulatedEarnings();
    floatingAssets += earnings + assets;
    depositToTreasury(treasuryFee);
    emitMarketUpdate();
  }

  /// @notice Withdraws the owner's floating pool assets to the receiver address.
  /// @dev Makes sure that the owner doesn't have shortfall after withdrawing.
  /// @param assets amount of underlying to be withdrawn.
  /// @param receiver address to which the assets will be transferred.
  /// @param owner address which owns the floating pool assets.
  /// @return shares amount of shares redeemed for underlying asset.
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public override returns (uint256 shares) {
    auditor.checkShortfall(this, owner, assets);
    shares = super.withdraw(assets, receiver, owner);
    emitMarketUpdate();
  }

  /// @notice Redeems the owner's floating pool assets to the receiver address.
  /// @dev Makes sure that the owner doesn't have shortfall after withdrawing.
  /// @param shares amount of shares to be redeemed for underlying asset.
  /// @param receiver address to which the assets will be transferred.
  /// @param owner address which owns the floating pool assets.
  /// @return assets amount of underlying asset that was withdrawn.
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public override returns (uint256 assets) {
    auditor.checkShortfall(this, owner, previewRedeem(shares));
    assets = super.redeem(shares, receiver, owner);
    emitMarketUpdate();
  }

  /// @notice Moves amount of shares from the caller's account to `to`.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// Makes sure that the caller doesn't have shortfall after transferring.
  /// @param to address to which the assets will be transferred.
  /// @param shares amount of shares to be transferred.
  function transfer(address to, uint256 shares) public override returns (bool) {
    auditor.checkShortfall(this, msg.sender, previewRedeem(shares));
    return super.transfer(to, shares);
  }

  /// @notice Moves amount of shares from `from` to `to` using the allowance mechanism.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// Makes sure that `from` address doesn't have shortfall after transferring.
  /// @param from address from which the assets will be transferred.
  /// @param to address to which the assets will be transferred.
  /// @param shares amount of shares to be transferred.
  function transferFrom(
    address from,
    address to,
    uint256 shares
  ) public override returns (bool) {
    auditor.checkShortfall(this, from, previewRedeem(shares));
    return super.transferFrom(from, to, shares);
  }

  /// @notice Gets current snapshot for an account across all maturities.
  /// @param account account to return status snapshot in the specified maturity date.
  /// @return the amount the account deposited to the floating pool and the total money it owes from maturities.
  function accountSnapshot(address account) external view returns (uint256, uint256) {
    return (convertToAssets(balanceOf[account]), previewDebt(account));
  }

  /// @notice Gets all borrows and penalties for an account.
  /// @param borrower account to return status snapshot for fixed and floating borrows.
  /// @return debt the total debt, denominated in number of assets.
  function previewDebt(address borrower) public view returns (uint256 debt) {
    Account storage account = accounts[borrower];
    uint256 memPenaltyRate = penaltyRate;
    uint256 packedMaturities = account.fixedBorrows;
    uint256 maturity = packedMaturities & ((1 << 32) - 1);
    packedMaturities = packedMaturities >> 32;
    // calculate all maturities using the base maturity and the following bits representing the following intervals
    while (packedMaturities != 0) {
      if (packedMaturities & 1 != 0) {
        FixedLib.Position storage position = fixedBorrowPositions[maturity][borrower];
        uint256 positionAssets = position.principal + position.fee;

        debt += positionAssets;

        if (block.timestamp > maturity) {
          debt += positionAssets.mulWadDown((block.timestamp - maturity) * memPenaltyRate);
        }
      }
      packedMaturities >>= 1;
      maturity += FixedLib.INTERVAL;
    }
    // calculate floating borrowed debt
    uint256 shares = account.floatingBorrowShares;
    if (shares > 0) debt += previewRefund(shares);
  }

  /// @notice Charges treasury fee to certain amount of earnings.
  /// @param earnings amount of earnings.
  /// @return earnings minus the fees charged by the treasury.
  function chargeTreasuryFee(uint256 earnings) internal returns (uint256) {
    uint256 fee = earnings.mulWadDown(treasuryFeeRate);
    depositToTreasury(fee);
    return earnings - fee;
  }

  /// @notice Collects all earnings that are charged to borrowers that make use of fixed pool deposits' assets.
  /// @param earnings amount of earnings.
  function collectFreeLunch(uint256 earnings) internal {
    if (earnings == 0) return;

    if (treasuryFeeRate > 0) {
      depositToTreasury(earnings);
    } else {
      earningsAccumulator += earnings;
    }
  }

  /// @notice Deposits amount of assets on behalf of the treasury address.
  /// @param fee amount of assets to be deposited.
  function depositToTreasury(uint256 fee) internal {
    if (fee > 0) {
      _mint(treasury, previewDeposit(fee));
      floatingAssets += fee;
    }
  }

  /// @notice Calculates the earnings to be distributed from the accumulator given the current timestamp.
  /// @return earnings to be distributed from the accumulator.
  function accumulatedEarnings() internal view returns (uint256 earnings) {
    uint256 elapsed = block.timestamp - lastAccumulatorAccrual;
    if (elapsed == 0) return 0;
    return
      earningsAccumulator.mulDivDown(
        elapsed,
        elapsed + earningsAccumulatorSmoothFactor.mulWadDown(maxFuturePools * FixedLib.INTERVAL)
      );
  }

  /// @notice Accrues the earnings to be distributed from the accumulator given the current timestamp.
  /// @return earnings distributed from the accumulator.
  function accrueAccumulatedEarnings() internal returns (uint256 earnings) {
    earnings = accumulatedEarnings();

    earningsAccumulator -= earnings;
    lastAccumulatorAccrual = uint32(block.timestamp);
    emit AccumulatorAccrual(block.timestamp);
  }

  /// @notice Updates the `floatingAssetsAverage`.
  function updateFloatingAssetsAverage() internal {
    floatingAssetsAverage = previewFloatingAssetsAverage();
    lastAverageUpdate = uint32(block.timestamp);
  }

  /// @notice Gets the current `floatingAssetsAverage` without updating the storage variable.
  /// @return projected `floatingAssetsAverage`.
  function previewFloatingAssetsAverage() public view returns (uint256) {
    uint256 memFloatingAssets = floatingAssets;
    uint256 memFloatingAssetsAverage = floatingAssetsAverage;
    uint256 dampSpeedFactor = memFloatingAssets < memFloatingAssetsAverage ? dampSpeedDown : dampSpeedUp;
    uint256 averageFactor = uint256(1e18 - (-int256(dampSpeedFactor * (block.timestamp - lastAverageUpdate))).expWad());
    return memFloatingAssetsAverage.mulWadDown(1e18 - averageFactor) + averageFactor.mulWadDown(memFloatingAssets);
  }

  /// @notice Updates the floating pool borrows' variables.
  /// @return treasuryFee amount of fees charged by the treasury to the new calculated floating debt.
  function updateFloatingDebt() internal returns (uint256 treasuryFee) {
    uint256 memFloatingDebt = floatingDebt;
    uint256 memFloatingAssets = floatingAssets;
    uint256 newFloatingUtilization = memFloatingAssets > 0 ? memFloatingDebt.divWadUp(memFloatingAssets) : 0;
    uint256 newDebt = memFloatingDebt.mulWadDown(
      interestRateModel.floatingBorrowRate(floatingUtilization, newFloatingUtilization).mulDivDown(
        block.timestamp - lastFloatingDebtUpdate,
        365 days
      )
    );

    memFloatingDebt += newDebt;
    treasuryFee = newDebt.mulWadDown(treasuryFeeRate);
    floatingAssets = memFloatingAssets + newDebt - treasuryFee;
    floatingDebt = memFloatingDebt;
    floatingUtilization = newFloatingUtilization;
    lastFloatingDebtUpdate = uint32(block.timestamp);
    emit FloatingDebtUpdate(block.timestamp, newFloatingUtilization);
  }

  /// @notice Calculates the total floating debt, considering elapsed time since last update and current interest rate.
  /// @return actual floating debt plus projected interest.
  function totalFloatingBorrowAssets() public view returns (uint256) {
    uint256 memFloatingDebt = floatingDebt;
    uint256 memFloatingAssets = floatingAssets;
    uint256 newFloatingUtilization = memFloatingAssets > 0 ? memFloatingDebt.divWadUp(memFloatingAssets) : 0;
    uint256 newDebt = memFloatingDebt.mulWadDown(
      interestRateModel.floatingBorrowRate(floatingUtilization, newFloatingUtilization).mulDivDown(
        block.timestamp - lastFloatingDebtUpdate,
        365 days
      )
    );
    return memFloatingDebt + newDebt;
  }

  /// @notice Calculates the floating pool balance plus earnings to be accrued at current timestamp
  /// from maturities and accumulator.
  /// @return actual floatingAssets plus earnings to be accrued at current timestamp.
  function totalAssets() public view override returns (uint256) {
    unchecked {
      uint256 memMaxFuturePools = maxFuturePools;
      uint256 backupEarnings = 0;

      uint256 latestMaturity = block.timestamp - (block.timestamp % FixedLib.INTERVAL);
      uint256 maxMaturity = latestMaturity + memMaxFuturePools * FixedLib.INTERVAL;

      for (uint256 maturity = latestMaturity; maturity <= maxMaturity; maturity += FixedLib.INTERVAL) {
        FixedLib.Pool storage pool = fixedPools[maturity];
        uint256 lastAccrual = pool.lastAccrual;

        if (maturity > lastAccrual) {
          backupEarnings += block.timestamp < maturity
            ? pool.unassignedEarnings.mulDivDown(block.timestamp - lastAccrual, maturity - lastAccrual)
            : pool.unassignedEarnings;
        }
      }

      return
        floatingAssets +
        backupEarnings +
        accumulatedEarnings() +
        (totalFloatingBorrowAssets() - floatingDebt).mulWadDown(1e18 - treasuryFeeRate);
    }
  }

  /// @notice Simulates the effects of a borrow at the current time, given current contract conditions.
  /// @param assets amount of assets to borrow.
  /// @return amount of shares that will be asigned to the account after the borrow.
  function previewBorrow(uint256 assets) public view returns (uint256) {
    uint256 supply = totalFloatingBorrowShares; // Saves an extra SLOAD if totalFloatingBorrowShares is non-zero.

    return supply == 0 ? assets : assets.mulDivUp(supply, totalFloatingBorrowAssets());
  }

  /// @notice Simulates the effects of a repay at the current time, given current contract conditions.
  /// @param assets amount of assets to repay.
  /// @return amount of shares that will be subtracted from the account after the repay.
  function previewRepay(uint256 assets) public view returns (uint256) {
    uint256 supply = totalFloatingBorrowShares; // Saves an extra SLOAD if totalFloatingBorrowShares is non-zero.

    return supply == 0 ? assets : assets.mulDivDown(supply, totalFloatingBorrowAssets());
  }

  /// @notice Simulates the effects of a refund at the current time, given current contract conditions.
  /// @param shares amount of shares to subtract from caller's accountability.
  /// @return amount of assets that will be repaid.
  function previewRefund(uint256 shares) public view returns (uint256) {
    uint256 supply = totalFloatingBorrowShares; // Saves an extra SLOAD if totalFloatingBorrowShares is non-zero.

    return supply == 0 ? shares : shares.mulDivUp(totalFloatingBorrowAssets(), supply);
  }

  /// @notice Checks msg.sender's allowance over account's assets.
  /// @param account account in which the allowance will be checked.
  /// @param assets assets from account that msg.sender wants to operate on.
  function spendAllowance(address account, uint256 assets) internal {
    if (msg.sender != account) {
      uint256 allowed = allowance[account][msg.sender]; // saves gas for limited approvals.

      if (allowed != type(uint256).max) allowance[account][msg.sender] = allowed - previewWithdraw(assets);
    }
  }

  /// @notice Emits MarketUpdate event.
  /// @dev Internal function to avoid code duplication.
  function emitMarketUpdate() internal {
    emit MarketUpdate(
      block.timestamp,
      totalSupply,
      floatingAssets,
      totalFloatingBorrowShares,
      floatingDebt,
      earningsAccumulator
    );
  }

  /// @notice Emits FixedEarningsUpdate event.
  /// @dev Internal function to avoid code duplication.
  function emitFixedEarningsUpdate(uint256 maturity) internal {
    emit FixedEarningsUpdate(block.timestamp, maturity, fixedPools[maturity].unassignedEarnings);
  }

  /// @notice Sets the rate charged to the fixed depositors that the floating pool suppliers will retain for initially
  /// providing liquidity.
  /// @dev Value can only be set between 20% and 0%.
  /// @param backupFeeRate_ percentage amount represented with 18 decimals.
  function setBackupFeeRate(uint256 backupFeeRate_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    backupFeeRate = backupFeeRate_;
    emit BackupFeeRateSet(backupFeeRate_);
  }

  /// @notice Sets the damp speed used to update the floatingAssetsAverage.
  /// @dev Values can only be set between 0 and 100%.
  /// @param up damp speed up, represented with 18 decimals.
  /// @param down damp speed down, represented with 18 decimals.
  function setDampSpeed(uint256 up, uint256 down) public onlyRole(DEFAULT_ADMIN_ROLE) {
    updateFloatingAssetsAverage();
    dampSpeedUp = up;
    dampSpeedDown = down;
    emit DampSpeedSet(up, down);
  }

  /// @notice Sets the factor used when smoothly accruing earnings to the floating pool.
  /// @dev Value cannot be higher than 4. If set at 0, then all remaining accumulated earnings are
  /// distributed in following operation to the floating pool.
  /// @param earningsAccumulatorSmoothFactor_ represented with 18 decimals.
  function setEarningsAccumulatorSmoothFactor(uint128 earningsAccumulatorSmoothFactor_)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    floatingAssets += accrueAccumulatedEarnings();
    emitMarketUpdate();
    earningsAccumulatorSmoothFactor = earningsAccumulatorSmoothFactor_;
    emit EarningsAccumulatorSmoothFactorSet(earningsAccumulatorSmoothFactor_);
  }

  /// @notice Sets the interest rate model to be used to calculate rates.
  /// @param interestRateModel_ new interest rate model.
  function setInterestRateModel(InterestRateModel interestRateModel_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    interestRateModel = interestRateModel_;
    depositToTreasury(updateFloatingDebt());
    emitMarketUpdate();
    emit InterestRateModelSet(interestRateModel_);
  }

  /// @notice Sets the protocol's max future pools for fixed borrowing and lending.
  /// @dev Value can not be 0 or higher than 224. If value is decreased, VALID maturities will become NOT_READY.
  /// @param futurePools number of pools to be active at the same time.
  function setMaxFuturePools(uint8 futurePools) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxFuturePools = futurePools;
    emit MaxFuturePoolsSet(futurePools);
  }

  /// @notice Sets the penalty rate per second.
  /// @dev Value can only be set approximately between 5% and 1% daily.
  /// @param penaltyRate_ percentage represented with 18 decimals.
  function setPenaltyRate(uint256 penaltyRate_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    penaltyRate = penaltyRate_;
    emit PenaltyRateSet(penaltyRate_);
  }

  /// @notice Sets the percentage that represents the liquidity reserves that can't be borrowed.
  /// @dev Value can only be set between 20% and 0%.
  /// @param reserveFactor_ parameter represented with 18 decimals.
  function setReserveFactor(uint128 reserveFactor_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    reserveFactor = reserveFactor_;
    emit ReserveFactorSet(reserveFactor_);
  }

  /// @notice Sets the treasury variables.
  /// @param treasury_ address of the treasury that will receive the minted eTokens.
  /// @param treasuryFeeRate_ represented with 18 decimals.
  function setTreasury(address treasury_, uint256 treasuryFeeRate_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    treasury = treasury_;
    treasuryFeeRate = treasuryFeeRate_;
    emit TreasurySet(treasury_, treasuryFeeRate_);
  }

  /// @notice Sets the pause state to true in case of emergency, triggered by an authorized account.
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /// @notice Sets the pause state to false when threat is gone, triggered by an authorized account.
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /// @notice Event emitted when an account borrows amount of assets from a floating pool.
  /// @param caller address which borrowed the asset.
  /// @param receiver address that received the borrowed assets.
  /// @param borrower address which will be repaying the borrowed assets.
  /// @param assets amount of assets that were borrowed.
  /// @param shares amount of borrow shares assigned to the account.
  event Borrow(
    address indexed caller,
    address indexed receiver,
    address indexed borrower,
    uint256 assets,
    uint256 shares
  );

  /// @notice Emitted when an account repays amount of assets to a floating pool.
  /// @param caller address which repaid the previously borrowed amount.
  /// @param borrower address which had the original debt.
  /// @param assets amount of assets that was repaid.
  /// @param shares amount of borrow shares that were subtracted from the account's accountability.
  event Repay(address indexed caller, address indexed borrower, uint256 assets, uint256 shares);

  /// @notice Emitted when an account deposits an amount of an asset to a certain fixed rate pool,
  /// collecting fees at the end of the period.
  /// @param maturity maturity at which the account will be able to collect his deposit + his fee.
  /// @param caller address which deposited the assets.
  /// @param owner address that will be able to withdraw the deposited assets.
  /// @param assets amount of the asset that were deposited.
  /// @param fee is the extra amount that it will be collected at maturity.
  event DepositAtMaturity(
    uint256 indexed maturity,
    address indexed caller,
    address indexed owner,
    uint256 assets,
    uint256 fee
  );

  /// @notice Emitted when an account withdraws from a fixed rate pool.
  /// @param maturity maturity where the account withdraw its deposits.
  /// @param caller address which withdraw the asset.
  /// @param receiver address which will be collecting the assets.
  /// @param owner address which had the assets withdrawn.
  /// @param positionAssets position size reduced.
  /// @param assetsDiscounted amount of assets withdrawn (can include a discount for early withdraw).
  event WithdrawAtMaturity(
    uint256 indexed maturity,
    address caller,
    address indexed receiver,
    address indexed owner,
    uint256 positionAssets,
    uint256 assetsDiscounted
  );

  /// @notice Emitted when an account borrows amount of an asset from a certain maturity date.
  /// @param maturity maturity in which the account will have to repay the loan.
  /// @param caller address which borrowed the asset.
  /// @param receiver address that received the borrowed assets.
  /// @param borrower address which will be repaying the borrowed assets.
  /// @param assets amount of the asset that were borrowed.
  /// @param fee extra amount that will need to be paid at maturity.
  event BorrowAtMaturity(
    uint256 indexed maturity,
    address caller,
    address indexed receiver,
    address indexed borrower,
    uint256 assets,
    uint256 fee
  );

  /// @notice Emitted when an account repays its borrows after maturity.
  /// @param maturity maturity where the account repaid its borrowed amounts.
  /// @param caller address which repaid the previously borrowed amount.
  /// @param borrower address which had the original debt.
  /// @param assets amount that was repaid.
  /// @param positionAssets amount of the debt that was covered in this repayment (penalties could have been repaid).
  event RepayAtMaturity(
    uint256 indexed maturity,
    address indexed caller,
    address indexed borrower,
    uint256 assets,
    uint256 positionAssets
  );

  /// @notice Emitted when an account's position had a liquidation.
  /// @param receiver address which repaid the previously borrowed amount.
  /// @param borrower address which had the original debt.
  /// @param assets amount of the asset that were repaid.
  /// @param lendersAssets incentive paid to lenders.
  /// @param seizeMarket address of the asset that were seized by the liquidator.
  /// @param seizedAssets amount seized of the collateral.
  event Liquidate(
    address indexed receiver,
    address indexed borrower,
    uint256 assets,
    uint256 lendersAssets,
    Market indexed seizeMarket,
    uint256 seizedAssets
  );

  /// @notice Emitted when an account's collateral has been seized.
  /// @param liquidator address which seized this collateral.
  /// @param borrower address which had the original debt.
  /// @param assets amount seized of the collateral.
  event Seize(address indexed liquidator, address indexed borrower, uint256 assets);

  /// @notice Emitted when an account is cleared from bad debt.
  /// @param borrower address which was cleared from bad debt.
  /// @param assets amount that was subtracted from the borrower's debt and spread to the `earningsAccumulator`.
  event SpreadBadDebt(address indexed borrower, uint256 assets);

  /// @notice Emitted when the backupFeeRate parameter is changed by admin.
  /// @param backupFeeRate rate charged to the fixed pools to be accrued by the floating depositors.
  event BackupFeeRateSet(uint256 backupFeeRate);

  /// @notice Emitted when the damp speeds are changed by admin.
  /// @param dampSpeedUp represented with 18 decimals.
  /// @param dampSpeedDown represented with 18 decimals.
  event DampSpeedSet(uint256 dampSpeedUp, uint256 dampSpeedDown);

  /// @notice Emitted when the earningsAccumulatorSmoothFactor is changed by admin.
  /// @param earningsAccumulatorSmoothFactor factor represented with 18 decimals.
  event EarningsAccumulatorSmoothFactorSet(uint256 earningsAccumulatorSmoothFactor);

  /// @notice Emitted when the interestRateModel is changed by admin.
  /// @param interestRateModel new interest rate model to be used to calculate rates.
  event InterestRateModelSet(InterestRateModel indexed interestRateModel);

  /// @notice Emitted when the maxFuturePools is changed by admin.
  /// @param maxFuturePools represented with 0 decimals.
  event MaxFuturePoolsSet(uint256 maxFuturePools);

  /// @notice Emitted when the penaltyRate is changed by admin.
  /// @param penaltyRate penaltyRate percentage per second represented with 18 decimals.
  event PenaltyRateSet(uint256 penaltyRate);

  /// @notice Emitted when the reserveFactor is changed by admin.
  /// @param reserveFactor reserveFactor percentage.
  event ReserveFactorSet(uint256 reserveFactor);

  /// @notice Emitted when the treasury variables are changed by admin.
  /// @param treasury address of the treasury that will receive the minted eTokens.
  /// @param treasuryFeeRate represented with 18 decimals.
  event TreasurySet(address indexed treasury, uint256 treasuryFeeRate);

  /// @notice Emitted when market state is updated.
  /// @param timestamp current timestamp.
  /// @param floatingDepositShares total floating supply shares.
  /// @param floatingAssets total floating supply assets.
  /// @param floatingBorrowShares total floating borrow shares.
  /// @param floatingDebt total floating borrow assets.
  /// @param earningsAccumulator earnings accumulator.
  event MarketUpdate(
    uint256 timestamp,
    uint256 floatingDepositShares,
    uint256 floatingAssets,
    uint256 floatingBorrowShares,
    uint256 floatingDebt,
    uint256 earningsAccumulator
  );

  /// @notice Emitted when the earnings of a maturity are updated.
  /// @param timestamp current timestamp.
  /// @param maturity maturity date where the earnings were updated.
  /// @param unassignedEarnings pending unassigned earnings.
  event FixedEarningsUpdate(uint256 timestamp, uint256 indexed maturity, uint256 unassignedEarnings);

  /// @notice Emitted when accumulator distributes earnings.
  /// @param timestamp current timestamp.
  event AccumulatorAccrual(uint256 timestamp);

  /// @notice Emitted when the floating debt is updated.
  /// @param timestamp current timestamp.
  /// @param utilization new floating utilization.
  event FloatingDebtUpdate(uint256 timestamp, uint256 utilization);

  /// @notice Stores fixed deposits and fixed borrows map and floating borrow shares of an account.
  /// @param fixedDeposits encoded map maturity dates where the account supplied to.
  /// @param fixedBorrows encoded map maturity dates where the account borrowed from.
  /// @param floatingBorrowShares number of floating borrow shares assigned to the account.
  struct Account {
    uint256 fixedDeposits;
    uint256 fixedBorrows;
    uint256 floatingBorrowShares;
  }
}

error Disagreement();
error InsufficientProtocolLiquidity();
error NotAuditor();
error SelfLiquidation();
error ZeroWithdraw();
error ZeroRepay();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { WETH, SafeTransferLib } from "solmate/src/tokens/WETH.sol";
import { Market } from "./Market.sol";

/// @notice To be used by Exactly's web-app so accounts can operate with ETH on MarketWETH.
contract MarketETHRouter is Initializable {
  using SafeTransferLib for address;
  using SafeTransferLib for WETH;

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  Market public immutable market;
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  WETH public immutable weth;

  modifier wrap() {
    weth.deposit{ value: msg.value }();
    _;
  }

  modifier unwrap(uint256 assets) {
    _;
    unwrapAndTransfer(assets);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(Market market_) {
    market = market_;
    weth = WETH(payable(address(market_.asset())));

    _disableInitializers();
  }

  /// @notice Initializes the contract.
  /// @dev can only be called once.
  function initialize() external initializer {
    weth.safeApprove(address(market), type(uint256).max);
  }

  /// @notice Receives ETH when unwrapping WETH.
  /// @dev Prevents other accounts from mistakenly sending ETH to this contract.
  receive() external payable {
    if (msg.sender != address(weth)) revert NotFromWETH();
  }

  /// @notice Wraps ETH and deposits WETH into the floating pool's market.
  /// @return shares number of minted shares.
  function deposit() external payable wrap returns (uint256 shares) {
    return market.deposit(msg.value, msg.sender);
  }

  /// @notice Unwraps WETH from the floating pool and withdraws to caller.
  /// @param assets amount of assets to withdraw.
  /// @return shares number of burned shares.
  function withdraw(uint256 assets) external unwrap(assets) returns (uint256 shares) {
    return market.withdraw(assets, address(this), msg.sender);
  }

  /// @notice Unwraps WETH from the floating pool and withdraws to caller.
  /// @param shares amount of shares to be burned in exchange of assets.
  /// @return assets amount of assets withdrawn.
  function redeem(uint256 shares) external returns (uint256 assets) {
    assets = market.redeem(shares, address(this), msg.sender);
    unwrapAndTransfer(assets);
  }

  /// @notice Unwraps WETH from the floating pool and borrows to caller.
  /// @param assets amount of assets to borrow.
  /// @return borrowShares number of borrowed shares.
  function borrow(uint256 assets) external unwrap(assets) returns (uint256 borrowShares) {
    return market.borrow(assets, address(this), msg.sender);
  }

  /// @notice Wraps ETH and repays to the floating pool.
  /// @param assets amount of assets to repay.
  /// @return repaidAssets number of repaid assets (can be lower than `assets`).
  /// @return borrowShares number of borrowed shares subtracted from the debt.
  function repay(uint256 assets) external payable wrap returns (uint256 repaidAssets, uint256 borrowShares) {
    (repaidAssets, borrowShares) = market.repay(assets, msg.sender);

    if (msg.value > repaidAssets) unwrapAndTransfer(msg.value - repaidAssets);
  }

  /// @notice Wraps ETH and repays to the floating pool.
  /// @param borrowShares shares to be subtracted from the caller's debt.
  /// @return repaidAssets number of repaid assets.
  /// @return actualShares number of borrowed shares subtracted from the debt (can be lower than `borrowShares`).
  function refund(uint256 borrowShares) external payable wrap returns (uint256 repaidAssets, uint256 actualShares) {
    (repaidAssets, actualShares) = market.refund(borrowShares, msg.sender);

    if (msg.value > repaidAssets) unwrapAndTransfer(msg.value - repaidAssets);
  }

  /// @notice Wraps ETH and deposits to a maturity.
  /// @param maturity maturity date where the assets will be deposited.
  /// @param minAssetsRequired minimum amount of assets required by the caller for the transaction to be accepted.
  /// @return maturityAssets total amount of assets (principal + fee) to be withdrawn at maturity.
  function depositAtMaturity(uint256 maturity, uint256 minAssetsRequired)
    external
    payable
    wrap
    returns (uint256 maturityAssets)
  {
    return market.depositAtMaturity(maturity, msg.value, minAssetsRequired, msg.sender);
  }

  /// @notice Unwraps WETH from a maturity and withdraws to caller.
  /// @param maturity maturity date where the assets will be withdrawn.
  /// @param assets position size to be reduced.
  /// @param minAssetsRequired minimum amount required by the caller (if discount included for early withdrawal).
  /// @return actualAssets amount of assets withdrawn (can include a discount for early withdraw).
  function withdrawAtMaturity(
    uint256 maturity,
    uint256 assets,
    uint256 minAssetsRequired
  ) external returns (uint256 actualAssets) {
    actualAssets = market.withdrawAtMaturity(maturity, assets, minAssetsRequired, address(this), msg.sender);
    unwrapAndTransfer(actualAssets);
  }

  /// @notice Unwraps WETH from a maturity and borrows to caller.
  /// @param maturity maturity date for repayment.
  /// @param assets amount to be sent to caller.
  /// @param maxAssetsAllowed maximum amount of debt that the caller is willing to accept.
  /// @return assetsOwed total amount of assets (principal + fee) to be repaid at maturity.
  function borrowAtMaturity(
    uint256 maturity,
    uint256 assets,
    uint256 maxAssetsAllowed
  ) external unwrap(assets) returns (uint256 assetsOwed) {
    return market.borrowAtMaturity(maturity, assets, maxAssetsAllowed, address(this), msg.sender);
  }

  /// @notice Wraps ETH and repays to a maturity.
  /// @param maturity maturity date where the assets will be repaid.
  /// @param assets amount to be paid for the caller's debt.
  /// @return repaidAssets the actual amount that was transferred into the Market.
  function repayAtMaturity(uint256 maturity, uint256 assets) external payable wrap returns (uint256 repaidAssets) {
    repaidAssets = market.repayAtMaturity(maturity, assets, msg.value, msg.sender);

    if (msg.value > repaidAssets) unwrapAndTransfer(msg.value - repaidAssets);
  }

  function unwrapAndTransfer(uint256 assets) internal {
    weth.withdraw(assets);
    msg.sender.safeTransferETH(assets);
  }
}

error NotFromWETH();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";

library FixedLib {
  using FixedPointMathLib for uint256;

  uint256 internal constant INTERVAL = 4 weeks;

  /// @notice Gets the amount of revenue sharing between the backup supplier and the new fixed pool supplier.
  /// @param pool fixed rate pool.
  /// @param amount amount being provided by the fixed pool supplier.
  /// @param backupFeeRate rate charged to the fixed pool supplier to be accrued by the backup supplier.
  /// @return yield amount to be offered to the fixed pool supplier.
  /// @return backupFee yield to be accrued by the backup supplier for initially providing the liquidity.
  function calculateDeposit(
    Pool memory pool,
    uint256 amount,
    uint256 backupFeeRate
  ) internal pure returns (uint256 yield, uint256 backupFee) {
    uint256 memBackupSupplied = backupSupplied(pool);
    if (memBackupSupplied != 0) {
      yield = pool.unassignedEarnings.mulDivDown(Math.min(amount, memBackupSupplied), memBackupSupplied);
      backupFee = yield.mulWadDown(backupFeeRate);
      yield -= backupFee;
    }
  }

  /// @notice Registers an operation to add supply to a fixed rate pool and potentially reduce backup debt.
  /// @param pool fixed rate pool where an amount will be added to the supply.
  /// @param amount amount to be added to the supply.
  /// @return backupDebtReduction amount that will be reduced from the backup debt.
  function deposit(Pool storage pool, uint256 amount) internal returns (uint256 backupDebtReduction) {
    uint256 borrowed = pool.borrowed;
    uint256 supplied = pool.supplied;
    pool.supplied = supplied + amount;
    backupDebtReduction = Math.min(borrowed - Math.min(borrowed, supplied), amount);
  }

  /// @notice Registers an operation to reduce borrowed amount from a fixed rate pool
  /// and potentially reduce backup debt.
  /// @param pool fixed rate pool where an amount will be repaid.
  /// @param amount amount to be added to the fixed rate pool.
  /// @return backupDebtReduction amount that will be reduced from the backup debt.
  function repay(Pool storage pool, uint256 amount) internal returns (uint256 backupDebtReduction) {
    uint256 borrowed = pool.borrowed;
    uint256 supplied = pool.supplied;
    pool.borrowed = borrowed - amount;
    backupDebtReduction = Math.min(borrowed - Math.min(borrowed, supplied), amount);
  }

  /// @notice Registers an operation to increase borrowed amount of a fixed rate pool
  /// and potentially increase backup debt.
  /// @param pool fixed rate pool where an amount will be borrowed.
  /// @param amount amount to be borrowed from the fixed rate pool.
  /// @return backupDebtAddition amount of new debt that needs to be borrowed from the backup supplier.
  function borrow(Pool storage pool, uint256 amount) internal returns (uint256 backupDebtAddition) {
    uint256 borrowed = pool.borrowed;
    uint256 newBorrowed = borrowed + amount;

    backupDebtAddition = newBorrowed - Math.min(Math.max(borrowed, pool.supplied), newBorrowed);
    pool.borrowed = newBorrowed;
  }

  /// @notice Registers an operation to reduce supply from a fixed rate pool and potentially increase backup debt.
  /// @param pool fixed rate pool where amount will be withdrawn.
  /// @param amountToDiscount amount to be withdrawn from the fixed rate pool.
  /// @return backupDebtAddition amount of new debt that needs to be borrowed from the backup supplier.
  function withdraw(Pool storage pool, uint256 amountToDiscount) internal returns (uint256 backupDebtAddition) {
    uint256 borrowed = pool.borrowed;
    uint256 supplied = pool.supplied;
    uint256 newSupply = supplied - amountToDiscount;

    backupDebtAddition = Math.min(supplied, borrowed) - Math.min(newSupply, borrowed);
    pool.supplied = newSupply;
  }

  /// @notice Accrues backup earnings from `unassignedEarnings` based on the `lastAccrual` time.
  /// @param pool fixed rate pool where earnings will be accrued.
  /// @param maturity maturity date of the pool.
  /// @return backupEarnings amount of earnings to be distributed to the backup supplier.
  function accrueEarnings(Pool storage pool, uint256 maturity) internal returns (uint256 backupEarnings) {
    uint256 lastAccrual = pool.lastAccrual;

    if (block.timestamp < maturity) {
      uint256 unassignedEarnings = pool.unassignedEarnings;
      pool.lastAccrual = block.timestamp;
      backupEarnings = unassignedEarnings.mulDivDown(block.timestamp - lastAccrual, maturity - lastAccrual);
      pool.unassignedEarnings = unassignedEarnings - backupEarnings;
    } else if (lastAccrual == maturity) {
      backupEarnings = 0;
    } else {
      pool.lastAccrual = maturity;
      backupEarnings = pool.unassignedEarnings;
      pool.unassignedEarnings = 0;
    }
  }

  /// @notice Calculates the amount that a fixed rate pool borrowed from the backup supplier.
  /// @param pool fixed rate pool.
  /// @return amount borrowed from the fixed rate pool.
  function backupSupplied(Pool memory pool) internal pure returns (uint256) {
    uint256 borrowed = pool.borrowed;
    uint256 supplied = pool.supplied;
    return borrowed - Math.min(borrowed, supplied);
  }

  /// @notice Modify positions based on a certain amount, keeping the original principal/fee ratio.
  /// @dev modifies the original struct and returns it. Needs for the amount to be less than the principal and the fee
  /// @param position original position to be scaled.
  /// @param amount to be used as a full value (principal + interest).
  /// @return scaled position.
  function scaleProportionally(Position memory position, uint256 amount) internal pure returns (Position memory) {
    uint256 principal = amount.mulDivDown(position.principal, position.principal + position.fee);
    position.principal = principal;
    position.fee = amount - principal;
    return position;
  }

  /// @notice Reduce positions based on a certain amount, keeping the original principal/fee ratio.
  /// @dev modifies the original struct and returns it.
  /// @param position original position to be reduced.
  /// @param amount to be used as a full value (principal + interest).
  /// @return reduced position.
  function reduceProportionally(Position memory position, uint256 amount) internal pure returns (Position memory) {
    uint256 positionAssets = position.principal + position.fee;
    uint256 newPositionAssets = positionAssets - amount;
    position.principal = newPositionAssets.mulDivDown(position.principal, positionAssets);
    position.fee = newPositionAssets - position.principal;
    return position;
  }

  /// @notice Calculates what proportion of earnings would `borrowAmount` represent considering `backupSupplied`.
  /// @param earnings amount to be distributed.
  /// @param borrowAmount amount that will be checked if came from the backup supplier or fixed rate pool.
  /// @return unassignedEarnings earnings to be added to `unassignedEarnings`.
  /// @return backupEarnings earnings to be distributed to the backup supplier.
  function distributeEarnings(
    Pool memory pool,
    uint256 earnings,
    uint256 borrowAmount
  ) internal pure returns (uint256 unassignedEarnings, uint256 backupEarnings) {
    backupEarnings = borrowAmount == 0
      ? 0
      : earnings.mulDivDown(borrowAmount - Math.min(backupSupplied(pool), borrowAmount), borrowAmount);
    unassignedEarnings = earnings - backupEarnings;
  }

  /// @notice Adds a maturity date to the borrow or supply positions of the account.
  /// @param encoded encoded maturity dates where the account borrowed or supplied to.
  /// @param maturity the new maturity where the account will borrow or supply to.
  /// @return updated encoded maturity dates.
  function setMaturity(uint256 encoded, uint256 maturity) internal pure returns (uint256) {
    // initialize the maturity with also the 1st bit on the 33th position set
    if (encoded == 0) return maturity | (1 << 32);

    uint256 baseMaturity = encoded & ((1 << 32) - 1);
    if (maturity < baseMaturity) {
      // if the new maturity is lower than the base, set it as the new base
      // wipe clean the last 32 bits, shift the amount of `INTERVAL` and set the new value with the 33rd bit set
      uint256 range = (baseMaturity - maturity) / INTERVAL;
      if (encoded >> (256 - range) != 0) revert MaturityOverflow();
      encoded = ((encoded >> 32) << (32 + range));
      return maturity | encoded | (1 << 32);
    } else {
      uint256 range = (maturity - baseMaturity) / INTERVAL;
      if (range > 223) revert MaturityOverflow();
      return encoded | (1 << (32 + range));
    }
  }

  /// @notice Remove maturity from account's borrow or supplied positions.
  /// @param encoded encoded maturity dates where the account borrowed or supplied to.
  /// @param maturity maturity date to be removed.
  /// @return updated encoded maturity dates.
  function clearMaturity(uint256 encoded, uint256 maturity) internal pure returns (uint256) {
    if (encoded == 0 || encoded == maturity | (1 << 32)) return 0;

    uint256 baseMaturity = encoded & ((1 << 32) - 1);
    // if the baseMaturity is the one being cleaned
    if (maturity == baseMaturity) {
      // wipe 32 bytes + 1 for the old base flag
      uint256 packed = encoded >> 33;
      uint256 range = 1;
      while ((packed & 1) == 0 && packed != 0) {
        unchecked {
          ++range;
        }
        packed >>= 1;
      }
      encoded = ((encoded >> (32 + range)) << 32);
      return (maturity + (range * INTERVAL)) | encoded;
    } else {
      // otherwise just clear the bit
      return encoded & ~(1 << (32 + ((maturity - baseMaturity) / INTERVAL)));
    }
  }

  /// @notice Verifies that a maturity is `VALID`, `MATURED`, `NOT_READY` or `INVALID`.
  /// @dev if expected state doesn't match the calculated one, it reverts with a custom error `UnmatchedPoolState`.
  /// @param maturity timestamp of the maturity date to be verified.
  /// @param maxPools number of pools available in the time horizon.
  /// @param requiredState state required by the caller to be verified (see `State` for description).
  /// @param alternativeState state required by the caller to be verified (see `State` for description).
  function checkPoolState(
    uint256 maturity,
    uint8 maxPools,
    State requiredState,
    State alternativeState
  ) internal view {
    State state;
    if (maturity % INTERVAL != 0) {
      state = State.INVALID;
    } else if (maturity <= block.timestamp) {
      state = State.MATURED;
    } else if (maturity > block.timestamp - (block.timestamp % INTERVAL) + (INTERVAL * maxPools)) {
      state = State.NOT_READY;
    } else {
      state = State.VALID;
    }

    if (state != requiredState && state != alternativeState) {
      if (alternativeState == State.NONE) revert UnmatchedPoolState(uint8(state), uint8(requiredState));

      revert UnmatchedPoolStates(uint8(state), uint8(requiredState), uint8(alternativeState));
    }
  }

  /// @notice Stores the accountability of a fixed interest rate pool.
  /// @param borrowed total amount borrowed from the pool.
  /// @param supplied total amount supplied to the pool.
  /// @param unassignedEarnings total amount of earnings not yet distributed and accrued.
  /// @param lastAccrual timestamp for the last time that some earnings have been distributed to the backup supplier.
  struct Pool {
    uint256 borrowed;
    uint256 supplied;
    uint256 unassignedEarnings;
    uint256 lastAccrual;
  }

  /// @notice Stores principal and fee of a borrow or a supply position of a account in a fixed rate pool.
  /// @param principal amount borrowed or supplied to the fixed rate pool.
  /// @param fee amount of fees to be repaid or earned at the maturity of the fixed rate pool.
  struct Position {
    uint256 principal;
    uint256 fee;
  }

  enum State {
    NONE,
    INVALID,
    MATURED,
    VALID,
    NOT_READY
  }
}

error MaturityOverflow();
error UnmatchedPoolState(uint8 state, uint8 requiredState);
error UnmatchedPoolStates(uint8 state, uint8 requiredState, uint8 alternativeState);

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IPriceFeed {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}