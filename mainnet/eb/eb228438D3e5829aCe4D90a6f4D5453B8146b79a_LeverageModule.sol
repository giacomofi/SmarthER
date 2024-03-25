// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.1) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../utils/SafeERC20Upgradeable.sol";
import "../../../interfaces/IERC4626Upgradeable.sol";
import "../../../utils/math/MathUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: When the vault is empty or nearly empty, deposits are at high risk of being stolen through frontrunning with
 * a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable, IERC4626Upgradeable {
    using MathUpgradeable for uint256;

    IERC20Upgradeable private _asset;
    uint8 private _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20Upgradeable asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20Upgradeable asset_) internal onlyInitializing {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20Upgradeable asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20MetadataUpgradeable.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20MetadataUpgradeable, ERC20Upgradeable) returns (uint8) {
        return _decimals;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        MathUpgradeable.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20Upgradeable.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
     */
    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
pragma solidity ^0.8.13;

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./variables.sol";
import "../../infiniteProxy/IProxy.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Helpers is Variables {
    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsInStETH aaveV2;
        ProtocolAssetsInWstETH aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH euler;
        ProtocolAssetsInStETH morphoAaveV2;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error Helpers__UnsupportedProtocolId();
    error Helpers__NotRebalancer();
    error Helpers__Reentrant();
    error Helpers__EulerDisabled();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    modifier onlyRebalancer() {
        if (
            !(isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender)
        ) {
            revert Helpers__NotRebalancer();
        }
        _;
    }

    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        if (_status == 2) revert Helpers__Reentrant();
        _status = 2;
        _;
        _status = 1;
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z =
            SafeMathUpgradeable.add(SafeMathUpgradeable.mul(x, y), RAY / 2) /
            RAY;
    }

    /// Returns ratio of Aave V2 in terms of `WETH` and `STETH`.
    function getRatioAaveV2()
        public
        view
        returns (uint256 stEthAmount_, uint256 ethAmount_, uint256 ratio_)
    {
        stEthAmount_ = IERC20(A_STETH_ADDRESS).balanceOf(address(vaultDSA));
        ethAmount_ = IERC20(D_WETH_ADDRESS).balanceOf(address(vaultDSA));
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Aave V3 in terms of `WETH` and `STETH`.
    function getRatioAaveV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(A_WSTETH_ADDRESS_AAVEV3).balanceOf(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IERC20(D_WETH_ADDRESS_AAVEV3).balanceOf(address(vaultDSA));

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Compound V3 in terms of `ETH` and `STETH`.
    function getRatioCompoundV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        ethAmount_ = COMP_ETH_MARKET_CONTRACT.borrowBalanceOf(
            address(vaultDSA)
        );

        ICompoundMarket.UserCollateral
            memory collateralData_ = COMP_ETH_MARKET_CONTRACT.userCollateral(
                address(vaultDSA),
                WSTETH_ADDRESS
            );

        wstEthAmount_ = uint256(collateralData_.balance);

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Euler in terms of `ETH` and `STETH`.
    function getRatioEuler(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = 0;
        stEthAmount_ = 0;
        ethAmount_ = 0;
        ratio_ = 0;

        // wstEthAmount_ = IEulerTokens(E_WSTETH_ADDRESS).balanceOfUnderlying(
        //     address(vaultDSA)
        // );

        // if (stEthPerWsteth_ > 0) {
        //     // Convert wstETH collateral balance to stETH.
        //     stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        // } else {
        //     stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        // }
        // ethAmount_ = IEulerTokens(EULER_D_WETH_ADDRESS).balanceOf(
        //     address(vaultDSA)
        // );

        // ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// Returns ratio of Morpho Aave in terms of `ETH` and `STETH`.
    function getRatioMorphoAaveV2()
        public
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        )
    {
        // `supplyBalanceInOf` => The supply balance of a user. aToken -> user -> balances.
        IMorphoAaveV2.SupplyBalance memory supplyBalanceSteth_ = MORPHO_CONTRACT
            .supplyBalanceInOf(A_STETH_ADDRESS, address(vaultDSA));

        // For a given market, the borrow balance of a user. aToken -> user -> balances.
        IMorphoAaveV2.BorrowBalance memory borrowBalanceWeth_ = MORPHO_CONTRACT
            .borrowBalanceInOf(
                A_WETH_ADDRESS, // aToken is used in mapping
                address(vaultDSA)
            );

        stEthAmountPool_ = rmul(
            supplyBalanceSteth_.onPool,
            (MORPHO_CONTRACT.poolIndexes(A_STETH_ADDRESS).poolSupplyIndex)
        );

        stEthAmountP2P_ = rmul(
            supplyBalanceSteth_.inP2P,
            MORPHO_CONTRACT.p2pSupplyIndex(A_STETH_ADDRESS)
        );

        // Supply balance = (pool supply * pool supply index) + (p2p supply * p2p supply index)
        stEthAmount_ = stEthAmountPool_ + stEthAmountP2P_;

        ethAmountPool_ = rmul(
            borrowBalanceWeth_.onPool,
            (MORPHO_CONTRACT.poolIndexes(A_WETH_ADDRESS).poolBorrowIndex)
        );

        ethAmountP2P_ = rmul(
            borrowBalanceWeth_.inP2P,
            (MORPHO_CONTRACT.p2pBorrowIndex(A_WETH_ADDRESS))
        );

        // Borrow balance = (pool borrow * pool borrow index) + (p2p borrow * p2p borrow index)
        ethAmount_ = ethAmountPool_ + ethAmountP2P_;

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    function getProtocolRatio(
        uint8 protocolId_
    ) public view returns (uint256 ratio_) {
        if (protocolId_ == 1) {
            // stETH based protocol
            (, , ratio_) = getRatioAaveV2();
        } else if (protocolId_ == 2) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioAaveV3(stEthPerWsteth_);
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioCompoundV3(stEthPerWsteth_);
        } else if (protocolId_ == 4) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioEuler(stEthPerWsteth_);
        } else if (protocolId_ == 5) {
            // stETH based protocol
            (, , , , , , ratio_) = getRatioMorphoAaveV2();
        } else {
            revert Helpers__UnsupportedProtocolId();
        }
    }

    function getNetAssets()
        public
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            NetAssetsHelper memory assets_
        )
    {
        uint256 stETHPerWstETH_ = WSTETH_CONTRACT.stEthPerToken();

        // Calculate collateral and debt values for all the protocols

        // stETH based protocols
        (assets_.aaveV2.stETH, assets_.aaveV2.wETH, ) = getRatioAaveV2();
        (
            assets_.morphoAaveV2.stETH,
            ,
            ,
            assets_.morphoAaveV2.wETH,
            ,
            ,

        ) = getRatioMorphoAaveV2();

        // wstETH based protocols
        (assets_.aaveV3.wstETH, , assets_.aaveV3.wETH, ) = getRatioAaveV3(
            stETHPerWstETH_
        );
        (
            assets_.compoundV3.wstETH,
            ,
            assets_.compoundV3.wETH,

        ) = getRatioCompoundV3(stETHPerWstETH_);
        (assets_.euler.wstETH, , assets_.euler.wETH, ) = getRatioEuler(
            stETHPerWstETH_
        );

        // Ideal wstETH balances in vault and DSA
        assets_.vaultBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal stETH balances in vault and DSA
        assets_.vaultBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal wETH balances in vault and DSA
        assets_.vaultBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Aggregating total wstETH
        uint256 totalWstETH_ = // Protocols
            assets_.aaveV3.wstETH +
            assets_.compoundV3.wstETH +
            assets_.euler.wstETH +
            // Ideal balances
            assets_.vaultBalances.wstETH +
            assets_.dsaBalances.wstETH;

        // Net assets are always calculated as STETH supplied - ETH borrowed.

        // Convert all wstETH to stETH to get the same base token.
        uint256 convertedStETH = IWstETH(WSTETH_ADDRESS).getStETHByWstETH(
            totalWstETH_
        );

        // Aggregating total stETH + wETH including revenue
        totalAssets_ =
            // Protocol stETH collateral
            assets_.vaultBalances.stETH +
            assets_.dsaBalances.stETH +
            assets_.aaveV2.stETH +
            assets_.morphoAaveV2.stETH +
            convertedStETH +
            // Ideal wETH balance and assuming wETH 1:1 stETH
            assets_.vaultBalances.wETH +
            assets_.dsaBalances.wETH;

        // Aggregating total wETH debt from protocols
        totalDebt_ =
            assets_.aaveV2.wETH +
            assets_.aaveV3.wETH +
            assets_.compoundV3.wETH +
            assets_.morphoAaveV2.wETH +
            assets_.euler.wETH;

        netAssets_ = totalAssets_ - totalDebt_ - revenue; // Assuming wETH 1:1 stETH
        aggregatedRatio_ = totalAssets_ == 0
            ? 0
            : ((totalDebt_ * 1e6) / (totalAssets_ - revenue));
    }

    /// @notice calculates the withdraw fee: max(percentage amount, absolute amount)
    /// @param stETHAmount_ the amount of assets being withdrawn
    /// @return the withdraw fee amount in assets
    function getWithdrawFee(
        uint256 stETHAmount_
    ) public view returns (uint256) {
        // percentage is in 1e4(1% is 10_000) here we want to have 100% as denominator
        uint256 withdrawFee = (stETHAmount_ * withdrawalFeePercentage) / 1e6;

        if (withdrawFeeAbsoluteMin > withdrawFee) {
            return withdrawFeeAbsoluteMin;
        }
        return withdrawFee;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface IEulerTokens {
    function balanceOfUnderlying(
        address account
    ) external view returns (uint256); //To be used for E-Tokens

    function balanceOf(address) external view returns (uint256); //To be used for D-Tokens
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}

interface IMorphoAaveV2 {
    struct PoolIndexes {
        uint32 lastUpdateTimestamp; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 poolSupplyIndex; // Last pool supply index. Note that for the stEth market, the pool supply index is tweaked to take into account the staking rewards.
        uint112 poolBorrowIndex; // Last pool borrow index. Note that for the stEth market, the pool borrow index is tweaked to take into account the staking rewards.
    }

    function poolIndexes(address) external view returns (PoolIndexes memory);

    // Current index from supply peer-to-peer unit to underlying (in ray).
    function p2pSupplyIndex(address) external view returns (uint256);

    // Current index from borrow peer-to-peer unit to underlying (in ray).
    function p2pBorrowIndex(address) external view returns (uint256);

    struct SupplyBalance {
        uint256 inP2P; // In peer-to-peer supply scaled unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In pool supply scaled unit. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In peer-to-peer borrow scaled unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In pool borrow scaled unit, a unit that grows in value, to keep track of the debt increase when borrowers are on Aave. Multiply by the pool borrow index to get the underlying amount.
    }

    // For a given market, the supply balance of a user. aToken -> user -> balances.
    function supplyBalanceInOf(
        address,
        address
    ) external view returns (SupplyBalance memory);

    // For a given market, the borrow balance of a user. aToken -> user -> balances.
    function borrowBalanceInOf(
        address,
        address
    ) external view returns (BorrowBalance memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "./interfaces.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

/// @title      Variables
/// @notice     Contains common storage variables of all modules of Infinite proxy.
contract ConstantVariables {
    uint256 internal constant RAY = 10 ** 27;

    IInstaIndex internal constant INSTA_INDEX_CONTRACT =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    // IERC20 internal constant STETH_CONTRACT = IERC20(STETH_ADDRESS);
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IWstETH internal constant WSTETH_CONTRACT = IWstETH(WSTETH_ADDRESS);
    address internal constant A_WSTETH_ADDRESS_AAVEV3 =
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address internal constant E_WSTETH_ADDRESS =
        0xbd1bd5C956684f7EB79DA40f582cbE1373A1D593;

    /***********************************|
    |           ETH ADDRESSES           |
    |__________________________________*/
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant A_WETH_ADDRESS =
        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address internal constant D_WETH_ADDRESS =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address internal constant D_WETH_ADDRESS_AAVEV3 =
        0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    address internal constant EULER_D_WETH_ADDRESS =
        0x62e28f054efc24b26A794F5C1249B6349454352C;

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    ILiteVaultV1 internal constant LITE_VAULT_V1 = ILiteVaultV1(IETH_TOKEN_V1);

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IMorphoAaveV2 internal constant MORPHO_CONTRACT =
        IMorphoAaveV2(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
}

contract Variables is ERC4626Upgradeable, ConstantVariables {
    /****************************************************************************|
    |   @notice Ids associated with protocols at the time of deployment.         |
    |   New protocols might have been added or removed at the time of viewing.   |
    |                          AAVE_V2 => 1                                      |
    |                          AAVE_V3 => 2                                      |
    |                          COMPOUND_V3 => 3                                  |
    |                          EULER => 4 // Disabled                            |
    |                          MORPHO_AAVE_V2 => 5                               |
    |___________________________________________________________________________*/

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/
    /*
     * Includes variables from ERC4626Upgradeable
     */

    /// @notice variables.sol is imported in all the files. Adding _disableInitializers() so the implementation can't be manipulated
    constructor() {
        _disableInitializers();
    }

    // 1: open; 2: closed
    uint8 internal _status;

    IDSA public vaultDSA;

    /// @notice Max limit (in wei) allowed for wsteth per eth unit amount.
    uint256 public leverageMaxUnitAmountLimit;

    /// @notice Secondary auth that only has the power to reduce max risk ratio.
    address public secondaryAuth;

    // Current exchange price.
    uint256 public exchangePrice;

    // Revenue exchange price (helps in calculating revenue).
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public revenueExchangePrice;

    /// @notice mapping to store allowed rebalancers
    ///         modifiable by auth
    mapping(address => bool) public isRebalancer;

    // Mapping of protocol id => max risk ratio, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    // 1 = Aave v2
    // 2 = Aave v3
    // 3 = Compound v3 (ETH market)
    // 4 = Euler // Disabled
    // 5 = Morpho Aave v2
    mapping(uint8 => uint256) public maxRiskRatio;

    // Max aggregated risk ratio of the vault that can be reached, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    uint256 public aggrMaxVaultRatio;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the percentage in 1e6
    /// this number is given in 1e4, i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    /// modifiable by owner
    uint256 public withdrawalFeePercentage;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the absolute minimum
    /// this number is given in decimals for the respective asset of the vault.
    /// modifiable by owner
    uint256 public withdrawFeeAbsoluteMin; // in underlying base asset, i.e. stEth

    // charge from the profits, scaled to factor 4.
    // 100,000 would be 10% cut from profit
    uint256 public revenueFeePercentage;

    /// @notice Stores profit revenue and withdrawal fees collected.
    uint256 public revenue;

    /// @notice Revenue will be transffered to this address upon collection.
    address public treasury;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract Events {
    /// Emitted whenever a protocol is leveraged.
    event LogLeverage(
        uint8 indexed protocol,
        uint256 indexed route,
        uint256 wstETHflashAmt,
        uint256 ethAmountBorrow,
        address[] vaults,
        uint256[] vaultAmts,
        uint256 indexed swapMode,
        uint256 unitAmt,
        uint256 vaultSwapAmt
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../../common/helpers.sol";
import "./events.sol";

/// @title LeverageModule
/// @dev Actions are executable by allowed rebalancers only
contract LeverageModule is Helpers, Events {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    // Revert if protocol or vault overall ratio after leverage is more than max.
    error LeverageModule__UnequalLength();
    error LeverageModule__UnitAmountLess();
    error LeverageModule__AggregatedRatioExceeded();
    error LeverageModule__MaxRiskRatioExceeded();
    error LeverageModule__LessAssetsRecieved();

    struct LeverageMemoryVariables {
        bool isStETHBasedProtocol;
        uint256 spellIndex;
        uint256 spellsLength;
        uint256 vaultsLength;
        string[] targets;
        bytes[] calldatas;
        uint256 flashStETH;
        uint256 beforeNetAssets;
        uint256 afterNetAssets;
        uint256 aggregatedRatio;
    }

    /// @notice Core function to perform leverage.
    /// @dev Note Flashloan will always be taken in `WSTETH`.
    /// @param protocolId_ Id of the protocol to leverage.
    /// @param route_ Route for flashloan
    /// @param wstETHflashAmount_ Amount of flashloan.
    /// @param wETHBorrowAmount_ Amount of weth to be borrowed.
    /// @param vaults_ Addresses of old vaults to deleverage.
    /// @param vaultAmounts_ Amount of `WETH` that we will payback in old vaults.
    /// @param swapMode_ Mode of swap.(0 = no swap, 1 = 1Inch, 2 = direct Lido route)
    /// @param unitAmount_ `WSTETH` per `WETH` conversion ratio with slippage.
    /// @dev Note `WETH` will always be swapped to `WSTETH`,
    /// even if the protocol accepts STETH. (This is done to add simplicity to the vault).
    /// @param oneInchData_ Bytes calldata required for `WETH` to `WSTETH` swapping.
    function leverage(
        uint8 protocolId_,
        uint256 route_,
        uint256 wstETHflashAmount_,
        uint256 wETHBorrowAmount_,
        address[] memory vaults_,
        uint256[] memory vaultAmounts_,
        uint256 swapMode_,
        uint256 unitAmount_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        if (protocolId_ == 4) {
            revert Helpers__EulerDisabled();
        }

        LeverageMemoryVariables memory lev_;
        lev_.vaultsLength = vaultAmounts_.length;
        if (!(vaults_.length == lev_.vaultsLength))
            revert LeverageModule__UnequalLength();

        lev_.isStETHBasedProtocol = (protocolId_ == 1 || protocolId_ == 5);

        // Includes eth borrow + stETH deposit
        lev_.spellsLength = 2;

        if (lev_.isStETHBasedProtocol) {
            // stETH based protocol

            // Note: Below are the spells based on which spell count has been calculated.
            // If wstETHflashAmount_ > 0, unwrap wsteth, deposit stETH aavev2 -> 2
            // Borrow (no condition) -> 1
            // Deleverage, aave v2 withdraw -> lev_.vaultsLength > 0 , lev_.vaultsLength + 1
            // Swap wETH to wstETH, unwrap wstETH -> swapMode_ == 1 , 2
            // Convert wETH to ETH, ETH to stETH -> swapMode_ == 2 , 2
            // Deposit wsteth aavev2, -> no condition , 1
            // Withdraw aave v2 wstETH, unwrap wsteth, flashpayback wstETH -> wstETHflashAmount_ > 0 , 3

            // Includes flash unwrap, deposit, withdraw, wrap, and flash payback.
            if (wstETHflashAmount_ > 0) lev_.spellsLength += 5;
            // Includes deleveraging other vaults (deleveraging other vaults gives astETH in return at 1:1)
            // + 1 for withdrawing underlying stETH from astETH.
            if (lev_.vaultsLength > 0)
                lev_.spellsLength += lev_.vaultsLength + 1;

            // Includes 1Inch swap to wstETH and unwrap.
            if (swapMode_ == 1)
                lev_.spellsLength += 2;
                // Includes direct Lido route. wETH => eth => stETH.
            else if (swapMode_ == 2) lev_.spellsLength += 2;
        } else {
            // wstETH based protocol

            // Deposit wstETH aavev2, -> wstETHflashAmount_ > 0 , 1
            // Borrow, -> no condition , 1
            // Deleverage, aave v2 withdraw, wrap stETH -> lev_.vaultsLength > 0 , lev_.vaultsLength + 2
            // Swap weth to wsteth, -> swapMode_ == 1 , 1
            // Convert wETH to ETH, ETH to stETH, stETH to wstETH -> swapMode_ == 2 , 3
            // Deposit wsteth aavev2, -> no condition , 1
            // Withdraw aave v2 wstETH, flashpayback wstETH -> wstETHflashAmount_ > 0 , 2

            // Includes flash deposit, withdraw, and flash payback.
            if (wstETHflashAmount_ > 0) lev_.spellsLength += 3;
            // Includes deleveraging other vaults, converting astETH into stETH, wrapping
            // stETH into wstETH (deleveraging other vaults gives astETH in return at 1:1)
            if (lev_.vaultsLength > 0) {
                lev_.spellsLength += lev_.vaultsLength + 2;
            }

            // Includes 1Inch swap.
            if (swapMode_ == 1)
                lev_.spellsLength += 1;
                // Includes direct Lido route. wETH => eth => stETH => wstETH.
            else if (swapMode_ == 2) lev_.spellsLength += 3;
        }

        // Var to set the total amount of astETH recieved from old vault deleverage.
        // Used for swapping astETH to stETH.
        uint256 vaultSwapAmt_;
        uint256 wstethPerWeth;

        lev_.targets = new string[](lev_.spellsLength);
        lev_.calldatas = new bytes[](lev_.spellsLength);

        (, , lev_.beforeNetAssets, , ) = getNetAssets();

        /***********************************|
        |     FLASHLOAN wstETH DEPOSIT      |
        |__________________________________*/
        if (wstETHflashAmount_ > 0) {
            // Flashloan needed. Hence adding spells to deposit flashloan received.

            if (lev_.isStETHBasedProtocol) {
                // stETH based protocol
                lev_.flashStETH = WSTETH_CONTRACT.getStETHByWstETH(
                    wstETHflashAmount_
                );

                // Flashloan is in wstETH & protocol 1 & 5 only supports stETH.
                // Hence converting flash wstETH into stETH
                lev_.targets[lev_.spellIndex] = "WSTETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)", //WSTETH -> STETH
                    type(uint256).max, // Converting all wsteth to steth
                    0,
                    0
                );

                lev_.spellIndex++;
            }

            if (protocolId_ == 1) {
                lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (protocolId_ == 2) {
                lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (protocolId_ == 3) {
                lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (protocolId_ == 4) {
                lev_.targets[lev_.spellIndex] = "EULER-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,address,uint256,bool,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    true,
                    0,
                    0
                );
            } else if (protocolId_ == 5) {
                lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    type(uint256).max, // depositing max steth
                    0,
                    0
                );
            }

            lev_.spellIndex++;
        }

        /***********************************|
        |            WETH BORROW             |
        |__________________________________*/

        if (protocolId_ == 1) {
            lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                wETHBorrowAmount_,
                2,
                0,
                0
            );
        } else if (protocolId_ == 2) {
            lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                wETHBorrowAmount_,
                2,
                0,
                0
            );
        } else if (protocolId_ == 3) {
            lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WETH_ADDRESS,
                wETHBorrowAmount_,
                0,
                0
            );
        } else if (protocolId_ == 4) {
            lev_.targets[lev_.spellIndex] = "EULER-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(uint256,address,uint256,uint256,uint256)",
                0,
                WETH_ADDRESS,
                wETHBorrowAmount_,
                0,
                0
            );
        } else if (protocolId_ == 5) {
            lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,address,uint256,uint256,uint256)",
                WETH_ADDRESS,
                A_WETH_ADDRESS,
                wETHBorrowAmount_,
                0,
                0
            );
        }

        lev_.spellIndex++;

        /***********************************|
        |       DELEVERAGE V1 VAULTS        |
        |__________________________________*/

        if (lev_.vaultsLength > 0) {
            for (uint256 k = 0; k < lev_.vaultsLength; k++) {
                lev_.targets[lev_.spellIndex] = "LITE-A"; // Instadapp Lite v1 vaults connector
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    vaultAmounts_[k],
                    0,
                    0
                );

                lev_.spellIndex++;

                // We'll receive astETH 1:1 for wETH payback.
                wETHBorrowAmount_ -= vaultAmounts_[k];
                vaultSwapAmt_ += vaultAmounts_[k];
            }

            lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                vaultSwapAmt_, // Not taking buffer since we will mostly have borrowed assets on aave so buffer case will be covered.
                0,
                0
            );

            lev_.spellIndex++;

            if (!(lev_.isStETHBasedProtocol)) {
                // wstETH based protocols
                lev_.targets[lev_.spellIndex] = "WSTETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    type(uint256).max, // Swap all the stETH amount recieved through Aave.
                    0,
                    0
                );

                lev_.spellIndex++;
            }
        }

        /***********************************|
        |      WETH => WSTETH 1INCH SWAP     |
        |__________________________________*/

        if (swapMode_ > 0) {
            if (swapMode_ == 1) {
                // swap via 1inch
                // wstethPerWeth will always be < 1, considering wETH is 1:1 with stETH.
                wstethPerWeth = WSTETH_CONTRACT.tokensPerStEth();
                if (unitAmount_ < (wstethPerWeth - leverageMaxUnitAmountLimit))
                    revert LeverageModule__UnitAmountLess();

                lev_.targets[lev_.spellIndex] = "1INCH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    WSTETH_ADDRESS,
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    unitAmount_,
                    oneInchData_,
                    0
                );
                lev_.spellIndex++;

                // Unwrapping wstETH to stETH after 1Inch swap(wETH => wstETH)
                if (lev_.isStETHBasedProtocol) {
                    // stETH based protocols
                    lev_.targets[lev_.spellIndex] = "WSTETH-A";
                    lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                        "withdraw(uint256,uint256,uint256)",
                        type(uint256).max, // Swap all the wstETH amount recieved through 1Inch.
                        0,
                        0
                    );

                    lev_.spellIndex++;
                }
            } else if (swapMode_ == 2) {
                // convert wETH into ETH
                lev_.targets[lev_.spellIndex] = "WETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)",
                    wETHBorrowAmount_,
                    0,
                    0
                );
                lev_.spellIndex++;

                // convert ETH into stETH
                lev_.targets[lev_.spellIndex] = "LIDO-STETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    wETHBorrowAmount_,
                    0,
                    0
                );
                lev_.spellIndex++;

                // wrapping stETH to wstETH
                if (!lev_.isStETHBasedProtocol) {
                    // wstETH based protocols
                    lev_.targets[lev_.spellIndex] = "WSTETH-A";
                    lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                        "deposit(uint256,uint256,uint256)",
                        type(uint256).max,
                        0,
                        0
                    );
                    lev_.spellIndex++;
                }
            }
        }

        /***********************************|
        |         COLLATERAL DEPOSIT        |
        |__________________________________*/

        /// If protocol is 1 or 5, DSA would currently have all stETH (since we unwrapped all wstETH from 1Inch swap).
        /// If protocol is 2, 3 or 4, DSA would currently have all wstETH (since we have wrapped all the stETH to wstETH).
        if (protocolId_ == 1) {
            // stETH based protocol
            lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 2) {
            // wstETH based protocol
            lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 4) {
            // wstETH based protocol
            lev_.targets[lev_.spellIndex] = "EULER-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(uint256,address,uint256,bool,uint256,uint256)",
                0,
                WSTETH_ADDRESS,
                type(uint256).max,
                true,
                0,
                0
            );
        } else if (protocolId_ == 5) {
            // stETH based protocol
            lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                A_STETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        }
        lev_.spellIndex++;

        /***********************************|
        |         WITHDRAW FLASHLOAN        |
        |__________________________________*/

        if (wstETHflashAmount_ > 0) {
            if (protocolId_ == 1) {
                lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    (lev_.flashStETH + 10), // taking 10 wei margin as there is possibilty of 1 wei precision loss due to exchange price calculations
                    0,
                    0
                );
            } else if (protocolId_ == 2) {
                lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    wstETHflashAmount_,
                    0,
                    0
                );
            } else if (protocolId_ == 3) {
                lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    wstETHflashAmount_,
                    0,
                    0
                );
            } else if (protocolId_ == 4) {
                lev_.targets[lev_.spellIndex] = "EULER-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,address,uint256,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    wstETHflashAmount_,
                    0,
                    0
                );
            } else if (protocolId_ == 5) {
                lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    (lev_.flashStETH + 10), // taking 10 wei margin as there is possibilty of 1 wei precision loss due to exchange price calculations
                    0,
                    0
                );
            }
            lev_.spellIndex++;

            if (lev_.isStETHBasedProtocol) {
                lev_.targets[lev_.spellIndex] = "WSTETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    type(uint256).max,
                    0,
                    0
                );
                lev_.spellIndex++;
            }

            lev_.targets[lev_.spellIndex] = "INSTAPOOL-C";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                wstETHflashAmount_,
                0,
                0
            );
            lev_.spellIndex++;

            bytes memory encodedFlashData_ = abi.encode(
                lev_.targets,
                lev_.calldatas
            );

            string[] memory flashTarget = new string[](1);
            bytes[] memory flashCalldata = new bytes[](1);
            flashTarget[0] = "INSTAPOOL-C";
            flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                WSTETH_ADDRESS,
                wstETHflashAmount_,
                route_,
                encodedFlashData_,
                "0x"
            );

            vaultDSA.cast(flashTarget, flashCalldata, address(this));
        } else {
            vaultDSA.cast(lev_.targets, lev_.calldatas, address(this));
        }

        // Verifying that the max risk ratio of the vault is less than the max ratio allowed.
        if (getProtocolRatio(protocolId_) > maxRiskRatio[protocolId_]) {
            revert LeverageModule__MaxRiskRatioExceeded();
        }

        // Verifying that the aggregated ratio of the vault is less than the max ratio allowed.
        (, , lev_.afterNetAssets, lev_.aggregatedRatio, ) = getNetAssets();

        if (lev_.afterNetAssets > lev_.beforeNetAssets) {
            revenue = revenue + lev_.afterNetAssets - lev_.beforeNetAssets;
        } else if ((lev_.beforeNetAssets - lev_.afterNetAssets) > 1e10) {
            revert LeverageModule__LessAssetsRecieved();
        }

        if (lev_.aggregatedRatio > aggrMaxVaultRatio) {
            revert LeverageModule__AggregatedRatioExceeded();
        }

        emit LogLeverage(
            protocolId_,
            route_,
            wstETHflashAmount_,
            wETHBorrowAmount_,
            vaults_,
            vaultAmounts_,
            swapMode_,
            unitAmount_,
            vaultSwapAmt_
        );
    }
}