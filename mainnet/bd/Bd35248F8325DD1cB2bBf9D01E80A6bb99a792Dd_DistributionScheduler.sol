// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant FEATURE_DISABLED = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;
    uint256 internal constant CODEC_OVERFLOW = 436;
    uint256 internal constant IN_RECOVERY_MODE = 437;
    uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
    uint256 internal constant INDUCED_FAILURE = 439;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase, var-name-mixedcase

interface IRewardTokenDistributor {
    struct Reward {
        IERC20 token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function reward_tokens(uint256 index) external view returns (IERC20);

    function reward_data(IERC20 token) external view returns (Reward memory);

    function claim_rewards(address user) external;

    function add_reward(IERC20 rewardToken, address distributor) external;

    function set_reward_distributor(IERC20 rewardToken, address distributor) external;

    function deposit_reward_token(IERC20 rewardToken, uint256 amount) external;

    function claimable_reward(address rewardToken, address user) external view returns (uint256);

    function claimable_reward_write(address rewardToken, address user) external returns (uint256);
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

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
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     *
     * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
     */
    function _callOptionalReturn(address token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = token.call(data);

        // If the low-level call didn't succeed we return whatever was returned from it.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IRewardTokenDistributor.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

// solhint-disable not-rely-on-time

/**
 * @title DistributionScheduler
 * @notice Scheduler for setting up permissionless distributions of liquidity gauge reward tokens.
 * @dev Any address may send tokens to the DistributionSchedule to be distributed among gauge depositors.
 */
contract DistributionScheduler {
    using SafeERC20 for IERC20;

    uint256 private constant _MAX_REWARDS = 8;

    // The node at _HEAD contains no value, and simply points to the actual first node. The last node points to _NULL.
    uint32 private constant _HEAD = 0;
    uint32 private constant _NULL = 0;

    // gauge-token pair -> timestamp -> (amount, nextTimestamp)
    mapping(bytes32 => mapping(uint32 => RewardNode)) private _rewardsLists;

    struct RewardNode {
        uint224 amount;
        uint32 nextTimestamp;
    }

    /**
     * @notice Returns information on the reward paid out to `gauge` in `token` over the week starting at `timestamp`
     * @param gauge - The gauge which is to distribute the reward token.
     * @param token - The token which is to be distributed among gauge depositors.
     * @param timestamp - The timestamp corresponding to the beginning of the week being queried.
     * @return - the amount of `token` which is to be distributed over the week starting at `timestamp`.
     *         - the timestamp of the next scheduled distribution of `token` to `gauge`. Zero if no distribution exists.
     */
    function getRewardNode(
        IRewardTokenDistributor gauge,
        IERC20 token,
        uint256 timestamp
    ) external view returns (RewardNode memory) {
        return _rewardsLists[_getRewardsListId(gauge, token)][uint32(timestamp)];
    }

    /**
     * @notice Returns the amount of `token` which is ready to be distributed by `gauge` as of the current timestamp.
     * @param gauge - The gauge which is to distribute the reward token.
     * @param token - The token which is to be distributed among gauge depositors.
     */
    function getPendingRewards(IRewardTokenDistributor gauge, IERC20 token) public view returns (uint256) {
        return getPendingRewardsAt(gauge, token, block.timestamp);
    }

    /**
     * @notice Returns the amount of `token` which is ready to be distributed by `gauge` as of a specified timestamp.
     * @param gauge - The gauge which is to distribute the reward token.
     * @param token - The token which is to be distributed among gauge depositors.
     * @param timestamp - The future timestamp in which to query.
     */
    function getPendingRewardsAt(
        IRewardTokenDistributor gauge,
        IERC20 token,
        uint256 timestamp
    ) public view returns (uint256) {
        mapping(uint32 => RewardNode) storage rewardsList = _rewardsLists[_getRewardsListId(gauge, token)];

        (, uint256 amount) = _getPendingRewards(rewardsList, timestamp);
        return amount;
    }

    /**
     * @notice Schedule a distribution of tokens to gauge depositors over the span of 1 week.
     * @dev All distributions must start at the beginning of a week in UNIX time, i.e. Thurs 00:00 UTC.
     * This is to prevent griefing from many low value distributions having to be processed before a meaningful
     * distribution can be processed.
     * @param gauge - The gauge which is to distribute the reward token.
     * @param token - The token which is to be distributed among gauge depositors.
     * @param amount - The amount of tokens which to distribute.
     * @param startTime - The timestamp at the beginning of the week over which to distribute tokens.
     */
    function scheduleDistribution(
        IRewardTokenDistributor gauge,
        IERC20 token,
        uint256 amount,
        uint256 startTime
    ) external {
        require(amount > 0, "Must provide non-zero number of tokens");

        // Ensure that values won't overflow when put into storage.
        require(amount <= type(uint224).max, "Reward amount overflow");
        require(startTime <= type(uint32).max, "Reward timestamp overflow");

        // Ensure that a user doesn't add a reward token which becomes locked on scheduler
        address rewardDistributor = gauge.reward_data(token).distributor;
        require(rewardDistributor != address(0), "Reward token does not exist on gauge");
        require(rewardDistributor == address(this), "DistributionScheduler is not reward token's distributor");

        // Prevent griefing by creating many small distributions which must be processed.
        require(startTime >= block.timestamp, "Distribution can only be scheduled for the future");
        require(startTime == _roundDownTimestamp(startTime), "Distribution must start at the beginning of the week");

        // Avoid mistakes causing rewards being locked far into the future.
        require(startTime - block.timestamp <= 365 days, "Distribution too far into the future");

        token.safeTransferFrom(msg.sender, address(this), amount);

        _insertReward(_rewardsLists[_getRewardsListId(gauge, token)], uint32(startTime), uint224(amount));
    }

    /**
     * @notice Process all pending distributions for a gauge to start distributing the tokens.
     * @param gauge - The gauge which is to distribute the reward token.
     */
    function startDistributions(IRewardTokenDistributor gauge) external {
        for (uint256 i = 0; i < _MAX_REWARDS; ++i) {
            IERC20 token = gauge.reward_tokens(i);
            if (token == IERC20(0)) break;

            // Only attempt to start distributions for tokens which we are the distributor for
            address rewardDistributor = gauge.reward_data(token).distributor;
            if (rewardDistributor == address(this)) {
                startDistributionForToken(gauge, token);
            }
        }
    }

    /**
     * @notice Process all pending distributions for a given token for a gauge to start distributing tokens.
     * @param gauge - The gauge which is to distribute the reward token.
     * @param token - The token which is to be distributed among gauge depositors.
     */
    function startDistributionForToken(IRewardTokenDistributor gauge, IERC20 token) public {
        mapping(uint32 => RewardNode) storage rewardsList = _rewardsLists[_getRewardsListId(gauge, token)];

        (uint32 firstUnprocessedNodeKey, uint256 rewardAmount) = _getPendingRewards(rewardsList, block.timestamp);

        // These calls are reentrancy-safe as we've already performed our only state transition (updating the head of
        // the list)
        rewardsList[_HEAD].nextTimestamp = firstUnprocessedNodeKey;

        token.approve(address(gauge), rewardAmount);
        gauge.deposit_reward_token(token, rewardAmount);
    }

    // Internal functions

    function _getRewardsListId(IRewardTokenDistributor gauge, IERC20 rewardToken) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(gauge, rewardToken));
    }

    /**
     * @dev Sums the rewards held on all pending reward nodes with a key lesser than `targetKey`.
     * @return - the key corresponding to the first node with a key greater than `targetKey`.
     *         - the cumulative rewards held on all pending nodes before `targetKey`
     */
    function _getPendingRewards(mapping(uint32 => RewardNode) storage rewardsList, uint256 targetKey)
        internal
        view
        returns (uint32, uint256)
    {
        uint32 currentNodeKey = rewardsList[_HEAD].nextTimestamp;

        // Iterate through all nodes which are ready to be started, summing the values of each.
        uint256 amount;
        while (targetKey >= currentNodeKey && currentNodeKey != _NULL) {
            amount += rewardsList[currentNodeKey].amount;

            currentNodeKey = rewardsList[currentNodeKey].nextTimestamp;
        }

        return (currentNodeKey, amount);
    }

    /**
     * @dev Find the position of the new node in the list of pending nodes and insert it.
     */
    function _insertReward(
        mapping(uint32 => RewardNode) storage rewardsList,
        uint32 insertedNodeKey,
        uint224 amount
    ) private {
        // We want to find two nodes which sit either side of the new node to be created so we can insert between them.

        uint32 currentNodeKey = _HEAD;
        uint32 nextNodeKey = rewardsList[currentNodeKey].nextTimestamp;

        // Search through nodes until the new node sits somewhere between `currentNodeKey` and `nextNodeKey`, or
        // we process all nodes.
        while (insertedNodeKey > nextNodeKey && nextNodeKey != _NULL) {
            currentNodeKey = nextNodeKey;
            nextNodeKey = rewardsList[currentNodeKey].nextTimestamp;
        }

        if (nextNodeKey == _NULL) {
            // We reached the end of the list and so can just append the new node.
            rewardsList[currentNodeKey].nextTimestamp = insertedNodeKey;
            rewardsList[insertedNodeKey] = RewardNode(amount, _NULL);
        } else if (nextNodeKey == insertedNodeKey) {
            // There already exists a node at the time we want to insert one.
            // We then just increase the value of this node.

            uint256 rewardAmount = uint256(rewardsList[nextNodeKey].amount) + amount;
            require(rewardAmount <= type(uint224).max, "Reward amount overflow");
            rewardsList[nextNodeKey].amount = uint224(rewardAmount);
        } else {
            // We're inserting a node in between `currentNodeKey` and `nextNodeKey` so then update
            // `currentNodeKey` to point to the newly inserted node and the new node to point to `nextNodeKey`.
            rewardsList[insertedNodeKey] = RewardNode(amount, nextNodeKey);
            rewardsList[currentNodeKey].nextTimestamp = insertedNodeKey;
        }
    }

    /**
     * @dev Rounds the provided timestamp down to the beginning of the previous week (Thurs 00:00 UTC)
     */
    function _roundDownTimestamp(uint256 timestamp) private pure returns (uint256) {
        return (timestamp / 1 weeks) * 1 weeks;
    }
}