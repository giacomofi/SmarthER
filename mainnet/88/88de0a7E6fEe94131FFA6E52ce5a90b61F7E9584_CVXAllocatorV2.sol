pragma solidity ^0.8.10;

import "../types/BaseAllocator.sol";

import "./interfaces/ILockedCvx.sol";
import "./interfaces/ICrvDepositor.sol";
import "./interfaces/IRewardStaking.sol";

struct OperationData {
    ILockedCvx cvxLocker;
    uint88 spendRatio;
    bool relock;
    ICrvDepositor crvDeposit;
    IRewardStaking ccStaking; // cvxcrv
}

contract CVXAllocatorV2 is BaseAllocator {
    OperationData public opData;

    constructor(OperationData memory opDataArg, AllocatorInitData memory aData) BaseAllocator(aData) {
        opData = opDataArg;
        aData.tokens[0].approve(address(opDataArg.cvxLocker), type(uint256).max);
        aData.tokens[1].approve(address(opDataArg.crvDeposit), type(uint256).max);
        aData.tokens[2].approve(address(opDataArg.ccStaking), type(uint256).max);
    }

    function _update(uint256 id) internal override returns (uint128 gain, uint128 loss) {
        // reads
        uint256 index = tokenIds[id];

        IERC20 cvx = _tokens[0];
        IERC20 crv = _tokens[1];
        IERC20 cc = _tokens[2];

        OperationData memory operation = opData;
        ILockedCvx locker = operation.cvxLocker;
        IRewardStaking ccStaking = operation.ccStaking;

        // interactions
        if (_unlockable() > 0) locker.processExpiredLocks(operation.relock);
        if (_checkClaimableRewards(locker)) locker.getReward(address(this), true);
        if (ccStaking.earned(address(this)) > 0) ccStaking.getReward(address(this), true);

        uint256 bal = cvx.balanceOf(address(this));

        if (bal > 0) {
            locker.lock(address(this), bal, operation.spendRatio);
        }

        bal = crv.balanceOf(address(this));

        if (bal > 0) {
            operation.crvDeposit.deposit(bal, true);
        }

        bal = cc.balanceOf(address(this));

        if (bal > 0) {
            ccStaking.stake(bal);
        }

        uint256 former = extender.getAllocatorAllocated(id) + extender.getAllocatorPerformance(id).gain;
        uint256 current = _amountAllocated(operation, index);

        if (current >= former) gain = uint128(current - former);
        else loss = uint128(former - current);
    }

    function deallocate(uint256[] memory amounts) public override onlyGuardian {
        uint256 length = amounts.length;
        OperationData memory operation = opData;

        if (amounts[0] > 0)
            operation.cvxLocker.processExpiredLocks(false); // can only do full
        else if (amounts[2] > 0)
            operation.ccStaking.withdrawAndUnwrap( // need to check what it goes into
                amounts[2] == type(uint256).max ? operation.ccStaking.balanceOf(address(this)) : amounts[2],
                true
            );
    }

    function _deactivate(bool panic) internal override {
        if (panic) {
            uint256[] memory amounts = new uint256[](3);
            OperationData memory operation = opData;
            ILockedCvx cvxLocker = operation.cvxLocker;
            IRewardStaking ccStaking = operation.ccStaking;

            if (_unlockable() > 0) amounts[0] = 1;
            if (ccStaking.balanceOf(address(this)) > 0) amounts[2] = type(uint256).max;

            deallocate(amounts);
        }
    }

    function _prepareMigration() internal override {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[2] = type(uint256).max;
        deallocate(amounts);
    }

    function rewardTokens() public view override returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = _tokens[1];
        tokens[1] = _tokens[2];
        return tokens;
    }

    function utilityTokens() public view override returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = _tokens[1];
        tokens[1] = _tokens[2];
        return tokens;
    }

    function name() external pure override returns (string memory) {
        return "CVXAllocatorV2";
    }

    function setOperationData(OperationData calldata newData) external onlyGuardian {
        opData = newData;
    }

    function setSpendRatio(uint88 ratio) external onlyGuardian {
        opData.spendRatio = ratio;
    }

    function setRelock(bool relock) external onlyGuardian {
        opData.relock = relock;
    }

    /// @notice Returns amounts allocated. NOTE: returns 0 for crv because it's being swapped into cvxcrv.
    /// Thus, crv loss limit should be type(uint256).max;
    function amountAllocated(uint256 id) public view override returns (uint256) {
        uint256 index = tokenIds[id];
        OperationData memory operation = opData;
        return _amountAllocated(operation, index);
    }

    function _checkClaimableRewards(ILockedCvx locker) internal returns (bool) {
        ILockedCvx.EarnedData[] memory rewards = locker.claimableRewards(address(this));
        for (uint256 i; i < rewards.length; i++) {
            if (rewards[i].amount > 0) {
                return true;
            }
        }
        return false;
    }

    function _amountAllocated(OperationData memory operation, uint256 index) internal view returns (uint256) {
        if (index == 2) return operation.ccStaking.balanceOf(address(this));
        else if (index == 1) return 0;
        return operation.cvxLocker.lockedBalanceOf(address(this));
    }

    function _unlockable() internal view returns (uint256) {
        (, uint256 unlockable, , ) = opData.cvxLocker.lockedBalances(address(this));
        return unlockable;
    }
}

pragma solidity ^0.8.10;

// interfaces
import "../interfaces/IAllocator.sol";
import "../interfaces/ITreasury.sol";

// types
import "../types/OlympusAccessControlledV2.sol";

// libraries
import "../libraries/SafeERC20.sol";

error BaseAllocator_AllocatorNotActivated();
error BaseAllocator_AllocatorNotOffline();
error BaseAllocator_Migrating();
error BaseAllocator_NotMigrating();
error BaseAllocator_OnlyExtender(address sender);

/**
 * @title BaseAllocator
 * @notice
 *  This abstract contract serves as a template for writing new Olympus Allocators.
 *  Many of the functionalities regarding handling of Treasury funds by the Guardian have
 *  been delegated to the `TreasuryExtender` contract, and thus an explanation for them can be found
 *  in `TreasuryExtender.sol`.
 *
 *  The main purpose of this abstract contract and the `IAllocator` interface is to provide
 *  a unified framework for how an Allocator should behave. Below an explanation of how
 *  we expect an Allocator to behave in general, mentioning the most important points.
 *
 *  Activation:
 *   - An Allocator is first deployed with all necessary arguments.
 *     Thereafter, each deposit is registered with the `TreasuryExtender`.
 *     This assigns a unique id for each deposit (set of allocations) in an Allocator.
 *   - Next, the Allocators allocation and loss limits are set via the extender function.
 *   - Finally, the Allocator is activated by calling `activate`.
 *
 *  Runtime:
 *   The Allocator is in communication with the Extender, it must inform the Extender
 *   what the status of the tokens is which were allocated. We only care about noting down
 *   their status in the Extender. A quick summary of the important functions on this topic:
 *
 *   - `update(uint256 id)` is the main function that deals with state reporting, where
 *     `_update(uint256 id)` is the internal function to implement, which should update Allocator
 *     internal state. `update(uint256 id)` then continues to report the Allocators state via `report`
 *     to the extender. `_update(uint256 id)` should handle _investment_ of funds present in Contract.
 *
 *   - `deallocate` should handle allocated token withdrawal, preparing the tokens to be withdrawn
 *     by the Extender. It is not necessary to handle approvals for this token, because it is automatically
 *     approved in the constructor. For other token withdrawals, it is assumed that reward tokens will
 *     either be sold into underlying (allocated) or that they will simply rest in the Contract, being reward tokens.
 *     Please also check function documentation.
 *
 *   - `rewardTokens` and `utilityTokens` should return the above mentioned simple reward tokens for the former case,
 *     while utility tokens should be those tokens which are continously reinvested or otherwise used by the contract
 *     in order to accrue more rewards. A reward token can also be a utility token, but then one must prepare them
 *     separately for withdrawal if they are to be returned to the treasury.
 *
 *  Migration & Deactivation:
 *   - `prepareMigration()` together with the virtual `_prepareMigration()` sets the state of the Allocator into
 *     MIGRATING, disabling further token deposits, enabling only withdrawals, and preparing all funds for withdrawal.
 *
 *   - `migrate` then executes the migration and also deactivates the Allocator.
 *
 *   - `deactivate` sets `status` to OFFLINE, meaning it simply deactivates the Allocator. It can be passed
 *     a panic boolean, meaning it handles deactivation logic in `deactivate`. The Allocator panic deactivates if
 *     this state if the loss limit is reached via `update`. The Allocator can otherwise also simply be deactivated
 *     and funds transferred back to the Treasury.
 *
 *  This was a short summary of the Allocator lifecycle.
 */
abstract contract BaseAllocator is OlympusAccessControlledV2, IAllocator {
    using SafeERC20 for IERC20;

    // Indices which represent the ids of the deposits in the `TreasuryExtender`
    uint256[] internal _ids;

    // The allocated (underlying) tokens of the Allocator
    IERC20[] internal _tokens;

    // From deposit id to the token's id
    mapping(uint256 => uint256) public tokenIds;

    // Allocator status: OFFLINE, ACTIVATED, MIGRATING
    AllocatorStatus public status;

    // The extender with which the Allocator communicates.
    ITreasuryExtender public immutable extender;

    constructor(AllocatorInitData memory data) OlympusAccessControlledV2(data.authority) {
        _tokens = data.tokens;
        extender = data.extender;

        for (uint256 i; i < data.tokens.length; i++) {
            data.tokens[i].approve(address(data.extender), type(uint256).max);
        }

        emit AllocatorDeployed(address(data.authority), address(data.extender));
    }

    /////// MODIFIERS

    modifier onlyExtender {
	_onlyExtender(msg.sender);
	_;
    }

    modifier onlyActivated {
	_onlyActivated(status);
	_;
    }

    modifier onlyOffline {
	_onlyOffline(status);
	_;
    }

    modifier notMigrating {
	_notMigrating(status);
	_;
    }

    modifier isMigrating {
	_isMigrating(status);
	_;
    }

    /////// VIRTUAL FUNCTIONS WHICH NEED TO BE IMPLEMENTED
    /////// SORTED BY EXPECTED COMPLEXITY AND DEPENDENCY

    /**
     * @notice
     *  Updates an Allocators state.
     * @dev
     *  This function should be implemented by the developer of the Allocator.
     *  This function should fulfill the following purposes:
     *   - invest token specified by deposit id
     *   - handle rebalancing / harvesting for token as needed
     *   - calculate gain / loss for token and return those values
     *   - handle any other necessary runtime calculations, such as fees etc.
     *
     *  In essence, this function should update the main runtime state of the Allocator
     *  so that everything is properly invested, harvested, accounted for.
     * @param id the id of the deposit in the `TreasuryExtender`
     */
    function _update(uint256 id) internal virtual returns (uint128 gain, uint128 loss);

    /**
     * @notice
     *  Deallocates tokens, prepares tokens for return to the Treasury.
     * @dev
     *  This function should deallocate (withdraw) `amounts` of each token so that they may be withdrawn
     *  by the TreasuryExtender. Otherwise, this function may also prepare the withdraw if it is time-bound.
     * @param amounts is the amount of each of token from `_tokens` to withdraw
     */
    function deallocate(uint256[] memory amounts) public virtual;

    /**
     * @notice
     *  Handles deactivation logic for the Allocator.
     */
    function _deactivate(bool panic) internal virtual;

    /**
     * @notice
     *  Handles migration preparatory logic.
     * @dev
     *  Within this function, the developer should arrange the withdrawal of all assets for migration.
     *  A useful function, say, to be passed into this could be `deallocate` with all of the amounts,
     *  so with n places for n-1 utility tokens + 1 allocated token, maxed out.
     */
    function _prepareMigration() internal virtual;

    /**
     * @notice
     *  Should estimate total amount of Allocated tokens
     * @dev
     *  The difference between this and `treasury.getAllocatorAllocated`, is that the latter is a static
     *  value recorded during reporting, but no data is available on _new_ amounts after reporting.
     *  Thus, this should take into consideration the new amounts. This can be used for say aTokens.
     * @param id the id of the deposit in `TreasuryExtender`
     */
    function amountAllocated(uint256 id) public view virtual returns (uint256);

    /**
     * @notice
     *  Should return all reward token addresses
     */
    function rewardTokens() public view virtual returns (IERC20[] memory);

    /**
     * @notice
     *  Should return all utility token addresses
     */
    function utilityTokens() public view virtual returns (IERC20[] memory);

    /**
     * @notice
     *  Should return the Allocator name
     */
    function name() external view virtual returns (string memory);

    /////// IMPLEMENTATION OPTIONAL

    /**
     * @notice
     *  Should handle activation logic
     * @dev
     *  If there is a need to handle any logic during activation, this is the function you should implement it into
     */
    function _activate() internal virtual {}

    /////// FUNCTIONS

    /**
     * @notice
     *  Updates an Allocators state and reports to `TreasuryExtender` if necessary.
     * @dev
     *  Can only be called by the Guardian.
     *  Can only be called while the Allocator is activated.
     *
     *  This function should update the Allocators internal state via `_update`, which should in turn
     *  return the `gain` and `loss` the Allocator has sustained in underlying allocated `token` from `_tokens`
     *  decided by the `id`.
     *  Please check the docs on `_update` to see what its function should be.
     *
     *  `_lossLimitViolated` checks if the Allocators is above its loss limit and deactivates it in case
     *  of serious losses. The loss limit should be set to some value which is unnacceptable to be lost
     *  in the case of normal runtime and thus require a panic shutdown, whatever it is defined to be.
     *
     *  Lastly, the Allocator reports its state to the Extender, which handles gain, loss, allocated logic.
     *  The documentation on this can be found in `TreasuryExtender.sol`.
     * @param id the id of the deposit in `TreasuryExtender`
     */
    function update(uint256 id) external override onlyGuardian onlyActivated {
        // effects
        // handle depositing, harvesting, compounding logic inside of _update()
        // if gain is in allocated then gain > 0 otherwise gain == 0
        // we only use so we know initia
        // loss always in allocated
        (uint128 gain, uint128 loss) = _update(id);

        if (_lossLimitViolated(id, loss)) {
            deactivate(true);
            return;
        }

        // interactions
        // there is no interactions happening inside of report
        // so allocator has no state changes to make after it
        if (gain + loss > 0) extender.report(id, gain, loss);
    }

    /**
     * @notice
     *  Prepares the Allocator for token migration.
     * @dev
     *  This function prepares the Allocator for token migration by calling the to-be-implemented
     *  `_prepareMigration`, which should logically withdraw ALL allocated (1) + utility AND reward tokens
     *  from the contract. The ALLOCATED token and THE UTILITY TOKEN is going to be migrated, while the REWARD
     *  tokens can be withdrawn by the Extender to the Treasury.
     */
    function prepareMigration() external override onlyGuardian notMigrating {
        // effects
        _prepareMigration();

        status = AllocatorStatus.MIGRATING;
    }

    /**
     * @notice
     *  Migrates the allocated and all utility tokens to the next Allocator.
     * @dev
     *  The allocated token and the utility tokens will be migrated by this function, while it is
     *  assumed that the reward tokens are either simply kept or already harvested into the underlying
     *  essentially being the edge case of this contract. This contract is also going to report to the
     *  Extender that a migration happened and as such it is important to follow the proper sequence of
     *  migrating.
     *
     *  Steps to migrate:
     *   - FIRST call `_prepareMigration()` to prepare funds for migration.
     *   - THEN deploy the new Allocator and activate it according to the normal procedure.
     *     NOTE: This is to be done RIGHT BEFORE migration as to avoid allocating to the wrong allocator.
     *   - FINALLY call migrate. This is going to migrate the funds to the LAST allocator registered.
     *   - Check if everything went fine.
     *
     *  End state should be that allocator amounts have been swapped for allocators, that gain + loss is netted out 0
     *  for original allocator, and that the new allocators gain has been set to the original allocators gain.
     *  We don't transfer the loss because we have the information how much was initially invested + gain,
     *  and the new allocator didn't cause any loss thus we don't really need to add to it.
     */
    function migrate() external override onlyGuardian isMigrating {
        // reads
        IERC20[] memory utilityTokensArray = utilityTokens();
        address newAllocator = extender.getAllocatorByID(extender.getTotalAllocatorCount() - 1);
	uint256 idLength = _ids.length;
	uint256 utilLength = utilityTokensArray.length;

        // interactions
        for (uint256 i; i < idLength; i++) {
            IERC20 token = _tokens[i];

            token.safeTransfer(newAllocator, token.balanceOf(address(this)));
            extender.report(_ids[i], type(uint128).max, type(uint128).max);
        }

        for (uint256 i; i < utilLength; i++) {
            IERC20 utilityToken = utilityTokensArray[i];
            utilityToken.safeTransfer(newAllocator, utilityToken.balanceOf(address(this)));
        }

        // turn off Allocator
        deactivate(false);

        emit MigrationExecuted(newAllocator);
    }

    /**
     * @notice
     *  Activates the Allocator.
     * @dev
     *  Only the Guardian can call this.
     *
     *  Add any logic you need during activation, say interactions with Extender or something else,
     *  in the virtual method `_activate`.
     */
    function activate() external override onlyGuardian onlyOffline {
        // effects
        _activate();
        status = AllocatorStatus.ACTIVATED;

        emit AllocatorActivated();
    }

    /**
     * @notice
     *  Adds a deposit ID to the Allocator.
     * @dev
     *  Only the Extender calls this.
     * @param id id to add to the allocator
     */
    function addId(uint256 id) external override onlyExtender {
        _ids.push(id);
        tokenIds[id] = _ids.length - 1;
    }

    /**
     * @notice
     *  Returns all deposit IDs registered with the Allocator.
     * @return the deposit IDs registered
     */
    function ids() external view override returns (uint256[] memory) {
        return _ids;
    }

    /**
     * @notice
     *  Returns all tokens registered with the Allocator.
     * @return the tokens
     */
    function tokens() external view override returns (IERC20[] memory) {
        return _tokens;
    }

    /**
     * @notice
     *  Deactivates the Allocator.
     * @dev
     *  Only the Guardian can call this.
     *
     *  Add any logic you need during deactivation, say interactions with Extender or something else,
     *  in the virtual method `_deactivate`. Be careful to specifically use the internal or public function
     *  depending on what you need.
     * @param panic should panic logic be executed
     */
    function deactivate(bool panic) public override onlyGuardian {
        // effects
        _deactivate(panic);
        status = AllocatorStatus.OFFLINE;

        emit AllocatorDeactivated(panic);
    }

    /**
     * @notice
     *  Getter for Allocator version.
     * @return Returns the Allocators version.
     */
    function version() public pure override returns (string memory) {
        return "v2.0.0";
    }

    /**
     * @notice
     *  Internal check if the loss limit has been violated by the Allocator.
     * @dev
     *  Called as part of `update`. The rule is that the already sustained loss + newly sustained
     *  has to be larger or equal to the limit to break the contract.
     * @param id deposit id as in `TreasuryExtender`
     * @param loss the amount of newly sustained loss
     * @return true if the the loss limit has been broken
     */
    function _lossLimitViolated(uint256 id, uint128 loss) internal returns (bool) {
        // read
        uint128 lastLoss = extender.getAllocatorPerformance(id).loss;

        // events
        if ((loss + lastLoss) >= extender.getAllocatorLimits(id).loss) {
            emit LossLimitViolated(lastLoss, loss, amountAllocated(tokenIds[id]));
            return true;
        }

        return false;
    }

    /**
     * @notice
     *  Internal check to see if sender is extender.
     */
    function _onlyExtender(address sender) internal view {
        if (sender != address(extender)) revert BaseAllocator_OnlyExtender(sender);
    }

    /**
     * @notice
     *  Internal check to see if allocator is activated.
     */
    function _onlyActivated(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.ACTIVATED) revert BaseAllocator_AllocatorNotActivated();
    }

    /**
     * @notice
     *  Internal check to see if allocator is offline.
     */
    function _onlyOffline(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.OFFLINE) revert BaseAllocator_AllocatorNotOffline();
    }

    /**
     * @notice
     *  Internal check to see if allocator is not migrating.
     */
    function _notMigrating(AllocatorStatus inputStatus) internal pure {
        if (inputStatus == AllocatorStatus.MIGRATING) revert BaseAllocator_Migrating();
    }

    /**
     * @notice
     *  Internal check to see if allocator is migrating.
     */
    function _isMigrating(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.MIGRATING) revert BaseAllocator_NotMigrating();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// comments check if interface is fine with v2
interface ILockedCvx {
    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function processExpiredLocks(bool _relock) external; // ok, was edited

    function getReward(address _account, bool _stake) external; // ok

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function epochCount() external view returns (uint256);

    function epochs(uint256 _id) external view returns (uint224, uint32);

    function checkpointEpoch() external;

    function balanceOf(address _account) external view returns (uint256);

    function lockedBalanceOf(address _user) external view returns (uint256 amount);

    function pendingLockOf(address _user) external view returns (uint256 amount);

    function pendingLockAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256 supply);

    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) external;

    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;

    function setStakeLimits(uint256 _minimum, uint256 _maximum) external;

    function setBoost(
        uint256 _max,
        uint256 _rate,
        address _receivingAddress
    ) external;

    function setKickIncentive(uint256 _rate, uint256 _delay) external;

    function shutdown() external;

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;

    function notifyRewardAmount(address _rewardToken, uint256 _reward) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICrvDepositor {
    function deposit(uint256, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRewardStaking {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function withdraw(uint256 amount, bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external;

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function balanceOf(address _account) external view returns (uint256);
}

pragma solidity >=0.8.0;

// interfaces
import "./IERC20.sol";
import "./ITreasuryExtender.sol";
import "./IOlympusAuthority.sol";

enum AllocatorStatus {
    OFFLINE,
    ACTIVATED,
    MIGRATING
}

struct AllocatorInitData {
    IOlympusAuthority authority;
    ITreasuryExtender extender;
    IERC20[] tokens;
}

/**
 * @title Interface for the BaseAllocator
 * @dev
 *  These are the standard functions that an Allocator should implement. A subset of these functions
 *  is implemented in the `BaseAllocator`. Similar to those implemented, if for some reason the developer
 *  decides to implement a dedicated base contract, or not at all and rather a dedicated Allocator contract
 *  without base, imitate the functionalities implemented in it.
 */
interface IAllocator {
    /**
     * @notice
     *  Emitted when the Allocator is deployed.
     */
    event AllocatorDeployed(address authority, address extender);

    /**
     * @notice
     *  Emitted when the Allocator is activated.
     */
    event AllocatorActivated();

    /**
     * @notice
     *  Emitted when the Allocator is deactivated.
     */
    event AllocatorDeactivated(bool panic);

    /**
     * @notice
     *  Emitted when the Allocators loss limit is violated.
     */
    event LossLimitViolated(uint128 lastLoss, uint128 dloss, uint256 estimatedTotalAllocated);

    /**
     * @notice
     *  Emitted when a Migration is executed.
     * @dev
     *  After this also `AllocatorDeactivated` should follow.
     */
    event MigrationExecuted(address allocator);

    /**
     * @notice
     *  Emitted when Ether is received by the contract.
     * @dev
     *  Only the Guardian is able to send the ether.
     */
    event EtherReceived(uint256 amount);

    function update(uint256 id) external;

    function deallocate(uint256[] memory amounts) external;

    function prepareMigration() external;

    function migrate() external;

    function activate() external;

    function deactivate(bool panic) external;

    function addId(uint256 id) external;

    function name() external view returns (string memory);

    function ids() external view returns (uint256[] memory);

    function tokenIds(uint256 id) external view returns (uint256);

    function version() external view returns (string memory);

    function status() external view returns (AllocatorStatus);

    function tokens() external view returns (IERC20[] memory);

    function utilityTokens() external view returns (IERC20[] memory);

    function rewardTokens() external view returns (IERC20[] memory);

    function amountAllocated(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

pragma solidity ^0.8.10;

import "../interfaces/IOlympusAuthority.sol";

error UNAUTHORIZED();
error AUTHORITY_INITIALIZED();

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract OlympusAccessControlledV2 {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority authority);

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
	_onlyGovernor();
	_;
    }

    modifier onlyGuardian {
	_onlyGuardian();
	_;
    }

    modifier onlyPolicy {
	_onlyPolicy();
	_;
    }

    modifier onlyVault {
	_onlyVault();
	_;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IOlympusAuthority _newAuthority) internal {
        if (authority != IOlympusAuthority(address(0))) revert AUTHORITY_INITIALIZED();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IOlympusAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        if (msg.sender != authority.governor()) revert UNAUTHORIZED();
    }

    function _onlyGuardian() internal view {
        if (msg.sender != authority.guardian()) revert UNAUTHORIZED();
    }

    function _onlyPolicy() internal view {
        if (msg.sender != authority.policy()) revert UNAUTHORIZED();
    }

    function _onlyVault() internal view {
        if (msg.sender != authority.vault()) revert UNAUTHORIZED();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.10;

struct AllocatorPerformance {
    uint128 gain;
    uint128 loss;
}

struct AllocatorLimits {
    uint128 allocated;
    uint128 loss;
}

struct AllocatorHoldings {
    uint256 allocated;
}

struct AllocatorData {
    AllocatorHoldings holdings;
    AllocatorLimits limits;
    AllocatorPerformance performance;
}

/**
 * @title Interface for the TreasuryExtender
 */
interface ITreasuryExtender {
    /**
     * @notice
     *  Emitted when a new Deposit is registered.
     */
    event NewDepositRegistered(address allocator, address token, uint256 id);

    /**
     * @notice
     *  Emitted when an Allocator is funded
     */
    event AllocatorFunded(uint256 id, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when allocated funds are withdrawn from an Allocator
     */
    event AllocatorWithdrawal(uint256 id, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when rewards are withdrawn from an Allocator
     */
    event AllocatorRewardsWithdrawal(address allocator, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when an Allocator reports a gain
     */
    event AllocatorReportedGain(uint256 id, uint128 gain);

    /**
     * @notice
     *  Emitted when an Allocator reports a loss
     */
    event AllocatorReportedLoss(uint256 id, uint128 loss);

    /**
     * @notice
     *  Emitted when an Allocator reports a migration
     */
    event AllocatorReportedMigration(uint256 id);

    /**
     * @notice
     *  Emitted when an Allocator limits are modified
     */
    event AllocatorLimitsChanged(uint256 id, uint128 allocationLimit, uint128 lossLimit);

    function registerDeposit(address newAllocator) external;

    function setAllocatorLimits(uint256 id, AllocatorLimits memory limits) external;

    function report(
        uint256 id,
        uint128 gain,
        uint128 loss
    ) external;

    function requestFundsFromTreasury(uint256 id, uint256 amount) external;

    function returnFundsToTreasury(uint256 id, uint256 amount) external;

    function returnRewardsToTreasury(
        uint256 id,
        address token,
        uint256 amount
    ) external;

    function getTotalAllocatorCount() external view returns (uint256);

    function getAllocatorByID(uint256 id) external view returns (address);

    function getAllocatorAllocated(uint256 id) external view returns (uint256);

    function getAllocatorLimits(uint256 id) external view returns (AllocatorLimits memory);

    function getAllocatorPerformance(uint256 id) external view returns (AllocatorPerformance memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}