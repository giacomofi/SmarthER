// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "../interfaces/IOracleDispatch.sol";
import "../interfaces/ILockManager.sol";
import "../utils/RevestAccessControl.sol";
import "../lib/chainlink/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/chainlink/Denominations.sol";

/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 *
 */
contract ChainlinkOracleDispatch is IOracleDispatch, RevestAccessControl {

    uint private constant MIN_TIME = 45 minutes;
    
    constructor(address provider) RevestAccessControl(provider) {}

    mapping(uint => address) public priceFeeds;

    //  Attempts to update oracle and returns true if successful. Returns true if update unnecessary
    function updateOracle(address asset, address compareTo) external pure override returns (bool) {
        return true;
    }

    //  Return true because no poke is needed
    function pokeOracle(address asset, address compareTo) external pure override returns (bool) {
        return true;
    }

    //  Will return true if oracle already initialized, if oracle has successfully been initialized by this call,
    //  or if oracle does not need to be initialized
    function initializeOracle(address asset, address compareTo) external pure override returns (bool) {
        return true;
    }


    //  Gets the value of the asset
    //  Oracle = the oracle address in specific. Optional parameter
    //  Inverted pair = whether or not this call represents an inversion of typical type (ERC20 underlying, USDC compareTo) to (USDC underlying, ERC20 compareTo)
    //  Must take inverse of value in this case to get REAL value
    function getValueOfAsset(
        address asset,
        address compareTo,
        bool risingEdge
    ) public view override returns (uint) {
        //This will never be called if there IS NOT a pair available
        //Implicit assumption for this function to be called is that getPairHasOracle has returned true


        return getPriceForOracle(asset, compareTo);
    }

    //  Oracle will never need updates
    function oracleNeedsUpdates(address asset, address compareTo) external pure override returns (bool) {
        return false;
    }

    function oracleNeedsInitialization(address asset, address compareTo) external pure override returns (bool) {
        return false;
    }

    function canOracleBeCreatedForRoute(address asset, address compareTo) external view override returns (bool) {
        return getPairHasOracle(asset, compareTo);
    }

    //  Oracle never needs poking
    function oracleNeedsPoking(address asset, address compareTo) external pure override returns (bool) {
        return false;
    }

    //  Oracle never needs poking
    function getTimePeriodAfterPoke(address asset, address compareTo) external pure override returns (uint) {
        return 0;
    }

    //  Returns a direct reference to the address that the specific contract for this pair is registered at
    function getOracleForPair(address asset, address compareTo) public view override returns (address) {
        return priceFeeds[getOracleID(asset, compareTo)];
    }

    // Returns a boolean if this oracle can provide data for the requested pair, used during FNFT creation
    function getPairHasOracle(address asset, address compareTo) public view override returns (bool) {

        return asset != compareTo && getOracleForPair(asset, compareTo) != address(0);
    }

    // Not terribly important for non-updateable oracles like Chainlink
    function getInstantPrice(address asset, address compareTo) external view override returns (uint) {
        return getValueOfAsset(asset, compareTo, true);
    }

    // INTERNAL FUNCTIONS


    //  Returns price and decimal precision
    function getPriceForOracle(address asset, address compareTo) internal view returns (uint) {
        uint id = getOracleID(asset, compareTo);
        address oracle = priceFeeds[id];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(oracle);
        (uint80 roundID, int256 answer, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) = priceFeed.latestRoundData();


        require(answer > 0, "E112"); 
        require(answeredInRound >= roundID, "E113");
        require(timestamp != 0, "E113");

        //difference between when started and returned needs to be less than 45-minutes
        require(block.timestamp - timestamp < MIN_TIME, "E113");
        require(timestamp - startedAt < MIN_TIME, "E113");


        uint castAnswer = answer >= int256(0) ? uint(answer) : 0;
        uint linkDecimals = priceFeed.decimals();
        uint realDecimals = linkDecimals;

        if(isStandardAsset(compareTo)) {
            realDecimals = ERC20(compareTo).decimals();
        }
        // Standardize price to native precision
        return castAnswer * (10 ** realDecimals) / (10 ** linkDecimals);
    }

    function batchAddOracles(
        address[] memory asset1,
        address[] memory asset2,
        address[] memory oracle
    ) external onlyOwner {
        for (uint i = 0; i < asset1.length; i++) {
            priceFeeds[getOracleID(asset1[i], asset2[i])] = oracle[i];
        }
    }

    function addOracle(
        address asset1,
        address asset2,
        address oracle
    ) external onlyOwner {
        // Token will always be the first ID, followed by the address to compare to
        uint id = getOracleID(asset1, asset2);
        priceFeeds[id] = oracle;
    }



    //  Will return 0 if Oracle DNE
    function getOracleID(address asset, address compareTo) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(asset, compareTo)));
    }

    //  Is the asset a real token or a denomination?
    function isStandardAsset(address asset) private pure returns (bool) {
        return asset != Denominations.USD &&
               asset != Denominations.ETH &&
               asset != Denominations.BTC &&
               asset != Denominations.GBP &&
               asset != Denominations.EUR;
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IOracleDispatch {

    // Attempts to update oracle and returns true if successful. Returns true if update unnecessary
    function updateOracle(address asset, address compareTo) external returns (bool);

    // Will return true if oracle does not need to be poked or if poke was successful
    function pokeOracle(address asset, address compareTo) external returns (bool);

    // Will return true if oracle already initialized, if oracle has successfully been initialized by this call,
    // or if oracle does not need to be initialized
    function initializeOracle(address asset, address compareTo) external returns (bool);

    // Gets the value of the asset
    // Oracle = the oracle address in specific. Optional parameter
    // Inverted pair = whether or not this call represents an inversion of typical type (ERC20 underlying, USDC compareTo) to (USDC underlying, ERC20 compareTo)
    // Must take inverse of value in this case to get REAL value
    function getValueOfAsset(
        address asset,
        address compareTo,
        bool risingEdge
    )  external view returns (uint);

    // Does this oracle need to be updated prior to our reading the price?
    // Return false if we are within desired time period
    // Or if this type of oracle does not require updates
    function oracleNeedsUpdates(address asset, address compareTo) external view returns (bool);

    // Does this oracle need to be poked prior to update and withdrawal?
    function oracleNeedsPoking(address asset, address compareTo) external view returns (bool);

    function oracleNeedsInitialization(address asset, address compareTo) external view returns (bool);

    //Only ever called if oracle needs initialization
    function canOracleBeCreatedForRoute(address asset, address compareTo) external view returns (bool);

    // How long to wait after poking the oracle before you can update it again and withdraw
    function getTimePeriodAfterPoke(address asset, address compareTo) external view returns (uint);

    // Returns a direct reference to the address that the specific contract for this pair is registered at
    function getOracleForPair(address asset, address compareTo) external view returns (address);

    // Returns a boolean if this oracle can provide data for the requested pair, used during FNFT creation
    function getPairHasOracle(address asset, address compareTo) external view returns (bool);

    //Returns the instantaneous price of asset and the decimals for that price
    function getInstantPrice(address asset, address compareTo) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ILockManager {

    function createLock(uint fnftId, IRevest.LockParam memory lock) external returns (uint);

    function getLock(uint lockId) external view returns (IRevest.Lock memory);

    function fnftIdToLockId(uint fnftId) external view returns (uint);

    function fnftIdToLock(uint fnftId) external view returns (IRevest.Lock memory);

    function pointFNFTToLock(uint fnftId, uint lockId) external;

    function lockTypes(uint tokenId) external view returns (IRevest.LockType);

    function unlockFNFT(uint fnftId, address sender) external returns (bool);

    function getLockMaturity(uint fnftId) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAddressRegistryV2.sol";
import "../interfaces/ILockManager.sol";
import "../interfaces/IRewardsHandler.sol";
import "../interfaces/ITokenVault.sol";
import "../interfaces/IRevestToken.sol";
import "../interfaces/IFNFTHandler.sol";
import "../lib/uniswap/IUniswapV2Factory.sol";


contract RevestAccessControl is Ownable {
    IAddressRegistryV2 internal addressesProvider;

    constructor(address provider) Ownable() {
        addressesProvider = IAddressRegistryV2(provider);
    }

    modifier onlyRevest() {
        require(_msgSender() != address(0), "E004");
        require(
                _msgSender() == addressesProvider.getLockManager() ||
                _msgSender() == addressesProvider.getRewardsHandler() ||
                _msgSender() == addressesProvider.getTokenVault() ||
                _msgSender() == addressesProvider.getRevest() ||
                _msgSender() == addressesProvider.getRevestToken(),
            "E016"
        );
        _;
    }

    modifier onlyRevestController() {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getRevest(), "E017");
        _;
    }

    modifier onlyTokenVault() {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getTokenVault(), "E017");
        _;
    }

    function setAddressRegistry(address registry) external onlyOwner {
        addressesProvider = IAddressRegistryV2(registry);
    }

    function getAdmin() internal view returns (address) {
        return addressesProvider.getAdmin();
    }

    function getRevest() internal view returns (IRevest) {
        return IRevest(addressesProvider.getRevest());
    }

    function getRevestToken() internal view returns (IRevestToken) {
        return IRevestToken(addressesProvider.getRevestToken());
    }

    function getLockManager() internal view returns (ILockManager) {
        return ILockManager(addressesProvider.getLockManager());
    }

    function getTokenVault() internal view returns (ITokenVault) {
        return ITokenVault(addressesProvider.getTokenVault());
    }

    function getUniswapV2() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(addressesProvider.getDEX(0));
    }

    function getFNFTHandler() internal view returns (IFNFTHandler) {
        return IFNFTHandler(addressesProvider.getRevestFNFT());
    }

    function getRewardsHandler() internal view returns (IRewardsHandler) {
        return IRewardsHandler(addressesProvider.getRewardsHandler());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint);

    function description() external view returns (string memory);

    function version() external view returns (uint);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);

  // ... other fiat currencies
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function extendFNFTMaturity(
        uint fnftId,
        uint endTime
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external view returns (uint);

    function getERC20Fee() external view returns (uint);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IAddressRegistry.sol";

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistryV2 is IAddressRegistry {

        function initialize_with_legacy(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address legacy_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getLegacyTokenVault() external view returns (address legacy);

    function setLegacyTokenVault(address legacyVault) external;

    function breakGlass() external;

    function pauseToken() external;

    function unpauseToken() external;

    function modifyPauser(address pauser, bool grant) external;

    function modifyBreaker(address breaker, bool grant) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRewardsHandler {

    struct UserBalance {
        uint allocPoint; // Allocation points
        uint lastMul;
    }

    function receiveFee(address token, uint amount) external;

    function updateLPShares(uint fnftId, uint newShares) external;

    function updateBasicShares(uint fnftId, uint newShares) external;

    function getAllocPoint(uint fnftId, address token, bool isBasic) external view returns (uint);

    function claimRewards(uint fnftId, address caller) external returns (uint);

    function setStakingContract(address stake) external;

    function getRewards(uint fnftId, address token) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ITokenVault {

    function createFNFT(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint quantity,
        address from
    ) external;

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
    ) external;

    function depositToken(
        uint fnftId,
        uint amount,
        uint quantity
    ) external;

    function cloneFNFTConfig(IRevest.FNFTConfig memory old) external returns (IRevest.FNFTConfig memory);

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) external;

    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory newFNFTIds,
        uint[] memory proportions,
        uint quantity
    ) external;

    function getFNFT(uint fnftId) external view returns (IRevest.FNFTConfig memory);
    function getFNFTCurrentValue(uint fnftId) external view returns (uint);
    function getNontransferable(uint fnftId) external view returns (bool);
    function getSplitsRemaining(uint fnftId) external view returns (uint);

    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRevestToken is IERC20 {

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

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