// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract QuaStaking is AccessControl {

    uint256 constant private MONTH = 60 * 60 * 24 * 30;
    uint256 constant private DAY = 60 * 60 * 24;
    uint256 constant private PERSENT_BASE = 10000;

    IERC20 public immutable token;
    uint256 public lockedAmount;
    address public commissionAddress;

    Pool[3] public pools;
    mapping(address => DepositInfo[]) public addressToDepositInfo;

    struct DepositInfo {
        uint256 amount;
        uint256 start;
        uint256 poolId;
        uint256 maxUnstakeAmount;
    }

    struct Pool {
        uint64 APY;
        uint8 timeLockUp;
        uint64 commission;
    }

    event TokensStaked(
        address user, 
        uint256 amount, 
        uint256 poolId, 
        uint256 timestamp
    );

    event Withdraw(
        address user, 
        uint256 amount, 
        uint256 poolId, 
        bool earlyWithdraw
    );

    event WithdrawExcess(address user, uint256 amount);

    /**
     * @dev setup DEFAULT_ADMIN_ROLE to deployer
     * @param _owner address of admin
     * @param _commissionAddress address to which the commission is sent 
     * @param _token address of ERC20 token Quarashi 
     * @param  _APY = 0.0055/0,0125/0,028 * 10000, 
     * @param _commission = 0.01/0.03/0.08 * 10000, 
     * @param _timeLockUp = 1/6/12
     */
    constructor(
        address _owner,
        address _commissionAddress,
        IERC20 _token, 
        uint8[3] memory _timeLockUp, 
        uint64[3] memory _APY, 
        uint64[3] memory _commission
    ) 
    {
        require(address(_token) != address(0), "Zero token address");
        token = _token;
        require(_owner != address(0), "Zero owner address");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        require(_commissionAddress != address(0), "Zero commission address");
        commissionAddress = _commissionAddress;

        Pool memory pool; 
        for (uint256 i; i < 3; i++) {
            pool = Pool(_APY[i], _timeLockUp[i], _commission[i]);
            pools[i] = (pool);
        }
    }

    /**
     * @param _commissionAddress new address to which the commission is sent 
     */
    function setCommissionAddress(address _commissionAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        commissionAddress = _commissionAddress;
    }

    /** 
     * @notice Create deposit for msg.sender with input params
     * @dev tokens must be approved for contract before call this func
     * @dev fires TokensStaked event
     * @param amount - initial balance of deposit
     * @param _poolId - id of pool of deposit,
     * = 0 for 1 month, 1 for 6 months, 2 for 12 months
     */
    function stake(uint256 amount, uint256 _poolId) external {
        require(
            token.balanceOf(_msgSender()) >= amount, 
            "Token: balance too low"
        );
        require(_poolId < pools.length, "Pool: wrong pool");

        uint256 _maxUnstakeAmount = amount;
        for (uint256 i; i < pools[_poolId].timeLockUp; i++) {
            _maxUnstakeAmount += _maxUnstakeAmount * pools[_poolId].APY / PERSENT_BASE;
        }
        lockedAmount += _maxUnstakeAmount;

        DepositInfo memory deposit = DepositInfo(
            amount, 
            block.timestamp, 
            _poolId,
            _maxUnstakeAmount
        );
        addressToDepositInfo[_msgSender()].push(deposit);

        
        require(
            lockedAmount <= token.balanceOf(address(this)) + amount, 
            "Token: do not have enouth tokens for reward"
        );

        require(
            token.transferFrom(_msgSender(), address(this), amount), 
            "Token: token did not transfer"
        );

        emit TokensStaked(_msgSender(), amount, _poolId, block.timestamp);
    }

    /** 
     * @notice Withdraw deposit with _depositInfoId for caller,
     * allow early withdraw, fire Withdraw event
     * @param _depositInfoId - id of deposit of caller
     */
    function withdraw(uint256 _depositInfoId) external {
        require(
            _depositInfoId < addressToDepositInfo[_msgSender()].length,
            "Pool: wrong staking id"
        );
        
        DepositInfo memory deposit = addressToDepositInfo[_msgSender()][_depositInfoId];
        require(deposit.amount != 0, "Deposit: tokens already been sended");

        uint256 amount;
        bool earlyWithdraw;
        uint256 commissionAmount;
        (amount, earlyWithdraw, commissionAmount) = getRewardAmount(_msgSender(), _depositInfoId);
        
        delete addressToDepositInfo[_msgSender()][_depositInfoId];
        lockedAmount -= deposit.maxUnstakeAmount;

        if (commissionAmount > 0) {
            require(
                token.transfer(commissionAddress, commissionAmount),
                "Token: can not transfer commission"
            );
        }
        require(
            token.transfer(_msgSender(), amount), 
            "Token: can not transfer reward"
        );
        
        emit Withdraw(_msgSender(), amount, deposit.poolId, earlyWithdraw);
    }

    /** 
     * @notice Withdraw excess of tokens from this contract,
     * can be called only by admin,
     * excess = balanceOf(this) - all deposits amount + max rewards,
     * fire WithdrawExcess event
     */
    function withdrawExcess() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = token.balanceOf(address(this)) - lockedAmount;
        require(amount > 0, "Token: do not have excess tokens");
        require(
            token.transfer(_msgSender(), amount),
            "Token: can not transfer excess"
        );

        emit WithdrawExcess(_msgSender(), amount);
    }

    /**
     * @notice Return all deposits of msg.sender, 
     * include unstaked deposits (with 0 amount)
     * @return amounts - initial balance of deposit[i] 
     * @return starts - start time of deposit[i]
     * @return poolIds - id of pool of deposit[i], 
     * = 0 for 1 month, 1 for 6 months, 2 for 12 months
     */
    function getDepositInfo(address _user) external view returns (
            uint256[] memory, 
            uint256[] memory, 
            uint256[] memory
        ) 
    {
        uint256 depositsAmount = addressToDepositInfo[_user].length;
        uint256[] memory amounts = new uint256[](depositsAmount);
        uint256[] memory starts = new uint256[](depositsAmount);
        uint256[] memory poolIds = new uint256[](depositsAmount);

        for (uint256 i; i < depositsAmount; i++) {
            amounts[i] = addressToDepositInfo[_user][i].amount;
            starts[i] = addressToDepositInfo[_user][i].start;
            poolIds[i] = addressToDepositInfo[_user][i].poolId;
        }

        return (amounts, starts, poolIds);
    }

    /**
     * @notice Return reward amount of deposit with input params if unstake it now
     * @param _user - address of deposit holder
     * @param _depositInfoId - id of deposit of _user
     * @return amount - reward amount = initial balance + reward - commission, 
     * if early unstake, else = initial balance + reward
     * @return earlyWithdraw - if early unstake = true, else = false 
     * @return commissionAmount - amount of tokens written off for an early unstake,
     * = 0 otherwise 
     */
    function getRewardAmount(
        address _user,
        uint256 _depositInfoId
    ) public view returns (
            uint256, 
            bool,
            uint256
        ) 
    {
        DepositInfo memory deposit = addressToDepositInfo[_user][_depositInfoId];
        Pool memory pool = pools[deposit.poolId];

        bool earlyWithdraw = true;
        if (deposit.start + MONTH * pool.timeLockUp <= block.timestamp) {
            earlyWithdraw = false;
        }
        uint256 amount;
        uint256 commissionAmount;

        if (earlyWithdraw) {
            amount = deposit.amount;
            uint256 stakingMonths = (block.timestamp - deposit.start) / MONTH;
            uint256 stakingDays = (block.timestamp - deposit.start) % MONTH / DAY;
            for (uint256 i; i < stakingMonths; i++) {
                amount += amount * pool.APY  / PERSENT_BASE;
            }
            amount += amount * pool.APY * stakingDays / 30 / PERSENT_BASE;
            commissionAmount = deposit.amount * pool.commission / PERSENT_BASE;
            amount -= commissionAmount;
        } else {
            amount = deposit.maxUnstakeAmount;
        }

        return (amount, earlyWithdraw, commissionAmount);
    }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}