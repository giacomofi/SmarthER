// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title LPStaking contract
 * @author Ajitesh Mishra
 * @notice This contract will store and manage staking at APR defined by owner
 * @dev Store, calculate, collect and transefer stakes and rewards to end user
 */
contract LPStaking is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // Lib for uints
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _depositIds;
    // Sec in a year

    uint256 private APRTime; // = 365 days (For testing it can be updated to shorter time.)
    address public onlyaddress;
    IERC20Upgradeable public WETH; // WETH Contract

    // Structure to store StakeHoders details
    struct stakeDetails {
        uint256 depositId; //deposit id
        uint256 stake; // Total amount staked by the user for perticular pool
        uint256 reward; // Total unclaimed reward calculated at lastRewardCalculated
        uint256 APR; // APR at which the amount was staked
        uint256 period; // vested for period
        uint256 lastRewardCalculated; // time when user staked
        uint256 poolId; //poolId
        uint256 vestedFor; // months
    }

    //interest rate
    struct interestRate {
        uint256 period;
        uint256 APR;
    }

    //poolid=>period=>APR
    mapping(uint256 => mapping(uint256 => uint256)) public vestingAPRPerPool;
    /** mapping to store current status for stakeHolder
     * Explaination:
     *  {
     *      Staker: {
     *           Pool: staking details
     *      }
     *  }
     */

    mapping(address => bool) public tokenPools;
    mapping(address => mapping(uint256 => stakeDetails)) public deposits;
    mapping(address => uint256[]) public userDepositMap;
    mapping(uint256 => stakeDetails) public depositDetails;

    // Events
    event Staked(address indexed staker, uint256 amount, uint256 indexed _poolId, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 amount, uint256 indexed _poolId, uint256 timestamp);
    event RewardClaimed(address indexed staker, uint256 amount, uint256 indexed _poolId, uint256 timestamp);
    event WETHDeposit(address indexed user, uint256 amount);
    event WETHWithdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 feeReward);

    // Structure to store the pool's information
    struct stakingPool {
        address token; // Address of staking token
        address reward; // Address of reward token
        uint256 tvl; // Total value currently locked in this pool
        uint256 totalAllotedReward; // Total award transfered to this contract by admin for reward.
        uint256 totalClaimedReward; // Total reward claimed in this pool
    }

    struct periodPool {
        uint256 tvl;
        uint256 totalAllotedFeeReward;
    }

    // List of pools created by admin
    stakingPool[] public pools;

    //pool period map period=>tvl
    mapping(uint256 => periodPool) public periodPoolMap;

    //mapping(uint => periodPool) periodMaketFee;
    uint256[] periods;

    //Bool for staking and reward calculation paused
    bool public isPaused;
    uint256 public pausedTimestamp;
    uint256 public periodSum; //sum of all periods
    uint256 public constant PRECISION_FACTOR = 10**18;
    /**
     * @dev Modifier to check if pool exists
     * @param _poolId Pools's ID
     */
    modifier poolExists(uint256 _poolId) {
        require(_poolId < pools.length, "Staking: Pool doesn't exists");
        _;
    }

    modifier onlyAddress() {
        require(_msgSender() == onlyaddress, "invalid access");
        _;
    }

    /**
     * @notice This method will be called once only by proxy contract to init.
     */
    function initialize(address _feeToken, uint256[] memory _periods) external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        periods = _periods;
        WETH = IERC20Upgradeable(_feeToken);
        APRTime = 365 days;
        setPeriodSum(_periods);
    }

    modifier isUniqueTokenPool(address _token) {
        require(!tokenPools[_token], "Add : token pool already exits");
        _;
    }

    function setOnlyAddress(address _only) external onlyOwner {
        onlyaddress = _only;
    }

    /**
     * @dev This function is used to calculate sum of periods
     */

    function setPeriodSum(uint256[] memory _periods) internal {
        periodSum = 0;
        for (uint256 i = 0; i < _periods.length; i++) {
            periodSum += _periods[i] == 0 ? 1 : _periods[i];
        }
    }

    /**
     * @dev This function will create new pool, access type is onlyOwner
     * @notice This Function will create new pool with the token address,\
       reward address and the APR percentage.
     * @param _token Staking token address for this pool. 
     * @param _reward Staking reward token address for this pool
     * @param _periodRates APR percentage * 1000 for this pool.
     */
    function addPool(
        address _token,
        address _reward,
        interestRate[] memory _periodRates
    ) public onlyOwner isUniqueTokenPool(_token) {
        tokenPools[_token] = true;
        uint256 index = pools.length > 0 ? pools.length - 1 : pools.length;

        // Add pool to contract
        for (uint256 i; i < _periodRates.length; i++) {
            vestingAPRPerPool[index][_periodRates[i].period] = _periodRates[i].APR;
        }
        pools.push(stakingPool(_token, _reward, 0, 0, 0));
    }

    /**
     * @dev This function allows owner to pause contract.
     */
    function PauseStaking() public onlyOwner {
        require(!isPaused, "Already Paused");
        isPaused = true;
        pausedTimestamp = block.timestamp;
    }

    /**
     * @dev This function allows owner to resume contract.
     */
    function ResumeStaking() public onlyOwner {
        require(isPaused, "Already Operational");
        isPaused = false;
        pausedTimestamp = block.timestamp;
    }

    /**
     * @dev This funtion will return the length of pools\
        which will be used to loop and get pool details.
     * @notice Get the length of pools and use it to loop for index.
     * @return Length of pool.
     */
    function poolLength() public view returns (uint256) {
        return pools.length;
    }

    /**
     * @dev This function allows owner to update APR for specific pool.
     * @notice Let's you update the APR for this pool if you're current owner.
     * @param _poolId pool's Id in which you want to update the APR.
     * @param _periodRates New APR percentage * 1000.
     */
    function updateAPR(uint256 _poolId, interestRate[] memory _periodRates) public onlyOwner poolExists(_poolId) {
        for (uint256 i; i < _periodRates.length; i++) {
            vestingAPRPerPool[_poolId][_periodRates[i].period] = _periodRates[i].APR;
        }
    }

    function getAPR(uint256 _poolId, uint256 _period) public view returns (uint256) {
        return vestingAPRPerPool[_poolId][_period];
    }

    /**
     * @dev This funciton allows owner to withdraw allotted reward amount from this contract.
     * @notice Let's you withdraw reward fund in this contract.
     * @param _poolId pool's Id in which you want to withdraw this reward.
     * @param amount amount to be withdraw from contract to owner's wallet.
     */
    function withdrawRewardfromPool(uint256 _poolId, uint256 amount) public onlyOwner poolExists(_poolId) {
        // Reward contract object.
        IERC20Upgradeable rewardToken = IERC20Upgradeable(pools[_poolId].reward);

        // Check if amount is allowed to spend the token
        require(
            pools[_poolId].totalAllotedReward >= amount,
            "Staking: amount Must be less than or equal to available rewards"
        );

        // Transfer the token to contract
        rewardToken.transfer(msg.sender, amount);

        // Update the pool's stats
        pools[_poolId].totalAllotedReward -= amount;
    }

    /**
     * @dev This funciton allows owner to add more reward amount to  this contract.
     * @notice Let's you allot more reward fund in this contract.
     * @param _poolId pool's Id in which you want to add this reward.
     * @param amount amount to be transfered from owner's wallet to this contract.
     */
    function addRewardToPool(uint256 _poolId, uint256 amount) public onlyOwner poolExists(_poolId) {
        // Reward contract object.
        IERC20Upgradeable rewardToken = IERC20Upgradeable(pools[_poolId].reward);

        // Check if amount is allowed to spend the token
        require(rewardToken.allowance(msg.sender, address(this)) >= amount, "Staking: Must allow Spending");

        // Transfer the token to contract
        rewardToken.transferFrom(msg.sender, address(this), amount);

        // Update the pool's stats
        pools[_poolId].totalAllotedReward += amount;
    }

    /**
     * @notice Receive WETH Fee Deposit only admin
     *
     * @param amount to deposit
     */

    function receiveWETHFee(uint256 amount) external onlyAddress nonReentrant {
        require(amount > 0, "Collect Fee: Amount must be > 0");
        WETH.transferFrom(_msgSender(), address(this), amount);

        for (uint256 i = 0; i < periods.length; i++) {
            periodPoolMap[periods[i]].totalAllotedFeeReward += periods[i] == 0
                ? (((1 * PRECISION_FACTOR) / periodSum) * amount) / PRECISION_FACTOR
                : (((periods[i] * PRECISION_FACTOR) / periodSum) * amount) / PRECISION_FACTOR;
        }
        emit WETHDeposit(_msgSender(), amount);
    }

    /**
     * @dev This function is used to withdraw WETH from contract from Admin only
     */

    function AdminWETHWithdraw() external onlyOwner nonReentrant {
        uint256 accMarketFee = WETH.balanceOf(address(this));
        WETH.transferFrom(address(this), _msgSender(), accMarketFee);
        emit WETHWithdraw(_msgSender(), accMarketFee);
    }

    /**
     * @dev This function is used to calculate current reward for stakeHolder
     * @param _stakeHolder The address of stakeHolder to calculate reward till current block
     * @return reward calculated till current block
     */
    function _calculateReward(
        address _stakeHolder,
        uint256 _dId,
        bool isProrata
    ) internal view returns (uint256 reward) {
        stakeDetails memory stakeDetail = _stakeHolder != address(0)
            ? deposits[_stakeHolder][_dId]
            : depositDetails[_dId];

        if (stakeDetail.stake > 0) {
            // Without safemath formula for explanation
            // reward = (
            //     (stakeDetail.stake * stakeDetails.APR * (block.timestamp - stakeDetail.lastRewardCalculated)) /
            //     (APRTime * 100 * 1000)
            // );
            if (isPaused) {
                if (stakeDetail.lastRewardCalculated > pausedTimestamp) {
                    reward = 0;
                } else {
                    reward = stakeDetail
                        .stake
                        .mul(stakeDetail.APR)
                        .mul(pausedTimestamp.sub(stakeDetail.lastRewardCalculated))
                        .div(APRTime.mul(100).mul(1000));
                }
            } else {
                uint256 APR = isProrata ? getAPR(stakeDetail.poolId, 0) : stakeDetail.APR;
                reward = stakeDetail.stake.mul(APR).mul(block.timestamp.sub(stakeDetail.lastRewardCalculated)).div(
                    APRTime.mul(100).mul(1000)
                );
            }
        } else {
            reward = 0;
        }
    }

    /**
     * @dev This function is used to calculate Total reward for stakeHolder for pool
     * @param _stakeHolder The address of stakeHolder to calculate Total reward
     * @param _dId deposit id for reward calculation
     * @param isProrata to calculate on prorata basis
     * @return reward total reward
     */
    function calculateReward(
        address _stakeHolder,
        uint256 _dId,
        bool isProrata
    ) public view returns (uint256 reward) {
        stakeDetails memory stakeDetail = deposits[_stakeHolder][_dId];
        reward = stakeDetail.reward + _calculateReward(_stakeHolder, _dId, isProrata);
    }

    /**
     * @dev Allows user to stake the amount the pool. Calculate the old reward\
       and updates the reward, staked amount and current APR.
     * @notice This function will update your staked amount.
     * @param _poolId The pool in which user wants to stake.
     * @param amount The amount user wants to add into his stake.
     */
    function stake(
        uint256 _poolId,
        uint256 amount,
        uint256 _period
    ) external nonReentrant whenNotPaused poolExists(_poolId) returns (uint256) {
        require(!isPaused, "Staking is paused");
        require(amount > 0, "Invalid amount");
        require(getAPR(_poolId, _period) != 0, "Invalid staking period");

        IERC20Upgradeable token = IERC20Upgradeable(pools[_poolId].token);

        // Check if amount is allowed to spend the token
        require(token.allowance(msg.sender, address(this)) >= amount, "Staking: Must allow Spending");

        // Transfer the token to contract
        token.transferFrom(msg.sender, address(this), amount);

        _depositIds.increment();
        uint256 id = _depositIds.current();
        // Calculate the last reward
        uint256 uncalculatedReward = _calculateReward(msg.sender, id, true);

        // Update the stake details
        deposits[msg.sender][id].depositId = id;
        deposits[msg.sender][id].stake += amount;
        deposits[msg.sender][id].reward += uncalculatedReward;
        deposits[msg.sender][id].lastRewardCalculated = block.timestamp;
        deposits[msg.sender][id].APR = getAPR(_poolId, _period);
        deposits[msg.sender][id].period = block.timestamp + (_period * 30 days);
        deposits[msg.sender][id].poolId = _poolId;
        deposits[msg.sender][id].vestedFor = _period;
        userDepositMap[msg.sender].push(id);
        depositDetails[id] = deposits[msg.sender][id];
        // Update TVL
        pools[_poolId].tvl += amount;
        periodPoolMap[_period].tvl += amount;

        emit Staked(msg.sender, amount, _poolId, block.timestamp);
        return id;
    }

    modifier whenNotPaused() {
        require(!isPaused, "contract paused!");
        _;
    }

    /**
     * @dev Calculate the current reward and unstake the stake token, Transefer
     * it to sender and update reward to 0
     * @param _poolId Pool from which user want to claim the reward.
     * @param _dId deposit id for getting reward fot deposit.
     * @param isForceWithdraw bool flag for emergency withdraw.
     * @notice This function will transfer the reward earned till now and staked token amount.
     */
    function withdraw(
        uint256 _poolId,
        uint256 _dId,
        bool isForceWithdraw
    ) external nonReentrant whenNotPaused poolExists(_poolId) {
        stakeDetails memory details = deposits[msg.sender][_dId];
        bool check = isForceWithdraw ? true : block.timestamp > details.period;
        require(details.stake > 0, "Claim : Nothing to claim");
        require(check, "Claim : cannot withdraw before vesting period ends");
        // Calculate the last reward
        uint256 uncalculatedReward = _calculateReward(msg.sender, _dId, isForceWithdraw);

        uint256 reward = details.reward + uncalculatedReward;
        uint256 amount = details.stake;
        // Check for the allowance and transfer from the owners account
        require(
            pools[details.poolId].totalAllotedReward > reward,
            "Staking: Insufficient reward allowance from the Admin"
        );

        // Transfer the reward.
        IERC20Upgradeable rewardtoken = IERC20Upgradeable(pools[details.poolId].reward);
        rewardtoken.transfer(msg.sender, reward);

        // Send the unstaked amout to stakeHolder
        IERC20Upgradeable staketoken = IERC20Upgradeable(pools[details.poolId].token);
        staketoken.transfer(msg.sender, amount);

        if (!isForceWithdraw && periodPoolMap[details.vestedFor].totalAllotedFeeReward > 0) {
            //transfer marketFee reward
            harvestFee(msg.sender, _dId);
        }

        // Update pools stats
        pools[details.poolId].totalAllotedReward -= reward;
        pools[details.poolId].totalClaimedReward += reward;
        pools[details.poolId].tvl -= details.stake;

        periodPoolMap[details.vestedFor].tvl -= amount;

        // Update the stake details
        deposits[msg.sender][_dId].reward = 0;
        deposits[msg.sender][_dId].stake = 0;
        if (isPaused) {
            deposits[msg.sender][_dId].lastRewardCalculated = pausedTimestamp;
        } else {
            deposits[msg.sender][_dId].lastRewardCalculated = block.timestamp;
        }

        // Trigger the event
        emit RewardClaimed(msg.sender, reward, _poolId, block.timestamp);
    }

    /**
     * @dev Disburse users Depsoits Unclaimed marketfee reward
     * @param _user address of the user
     * @param _dId deposit id for harvest
     * @notice This function will give send user there unclaimed marketfee reward.
     */
    function harvestFee(address _user, uint256 _dId) internal {
        stakeDetails memory deposit = deposits[_user][_dId];
        require(deposit.stake > 0, "Harvest: Not a staker");

        uint256 rewardFee = getHavestAmount(_user, _dId);
        if (rewardFee == 0 || periodPoolMap[deposit.vestedFor].totalAllotedFeeReward <= 0) {
            return;
        }

        uint256 balance = WETH.balanceOf(address(this));

        if (balance == 0) {
            return;
        }
        periodPoolMap[deposit.vestedFor].totalAllotedFeeReward -= rewardFee;
        WETH.transferFrom(address(this), _user, rewardFee);
        emit Harvest(_user, rewardFee);
    }

    /**
     * @dev Calculates users deposits WETH market fee reward
     * @notice This function will give you total of unclaimed rewards till now.
     * @return reward Total unclaimed WETH reward till now for specific deposit Id
     */
    function getHavestAmount(address _user, uint256 _dId) public view returns (uint256) {
        stakeDetails memory deposit = deposits[_user][_dId];
        uint256 locktime = deposit.vestedFor;
        if (deposit.stake < 0 || periodPoolMap[locktime].totalAllotedFeeReward < 0) {
            return 0;
        }

        uint256 feeRewardPerSecond;
        if (locktime == 0) {
            feeRewardPerSecond = periodPoolMap[locktime].totalAllotedFeeReward / 60 / 60 / 24 / 30 / 1;
        } else {
            feeRewardPerSecond = periodPoolMap[locktime].totalAllotedFeeReward / 60 / 60 / 24 / 30 / locktime;
        }
        uint256 pendingReward = (block.timestamp - deposit.lastRewardCalculated) * feeRewardPerSecond;

        uint256 reward = ((deposit.stake * PRECISION_FACTOR) / periodPoolMap[locktime].tvl) * pendingReward;

        return reward / PRECISION_FACTOR;
    }

    function getDeposits(address _user) public view returns (stakeDetails[] memory) {
        stakeDetails[] memory details = new stakeDetails[](userDepositMap[_user].length);
        for (uint256 i = 0; i < userDepositMap[_user].length; i++) {
            stakeDetails memory deposit = deposits[_user][userDepositMap[_user][i]];
            if (deposit.stake > 0) {
                details[i] = deposit;
            }
        }
        return details;
    }

    /**
     * @dev Calculate and return total undelivered rewards till now.
     * @notice This function will give you total of unclaimed rewards till now.
     * @return _totalReward Total unclaimed reward till now.
     */

    function totalReward() public view returns (uint256 _totalReward) {
        uint256 sum = 0;
        for (uint256 i = 1; i <= _depositIds.current(); i++) {
            if (depositDetails[i].stake > 0) {
                sum += depositDetails[i].reward;
                sum += _calculateReward(address(0), depositDetails[i].depositId, false);
            }
        }
        _totalReward = sum;
    }

    /**
     * @dev Function to check if contract have suffecient reward allowance or not
     * @notice This function will return if it has sufficient fund for paying the reward
     * @param _poolId The pool for which you want to check reward availibility
     * @return True if have sufficient allowance for paying all the rewards
     */
    function haveSuffecientFundsForReward(uint256 _poolId) public view returns (bool) {
        return pools[_poolId].totalAllotedReward >= totalReward();
    }

    /**
     * @dev Function to get balance of this contract WETH market fee
     * @return uint balance of weth in wei
     */
    function getAccMarketFee() public view returns (uint256) {
        return WETH.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
                version == 1 && !AddressUpgradeable.isContract(address(this)),
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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