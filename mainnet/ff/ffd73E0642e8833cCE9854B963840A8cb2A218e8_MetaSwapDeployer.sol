// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
    using SafeMath for uint256;

    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    // Constant values used in ramping A calculations
    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10**6;
    uint256 private constant MAX_A_CHANGE = 2;
    uint256 private constant MIN_RAMP_TIME = 14 days;

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter
     */
    function getA(SwapUtils.Swap storage self) external view returns (uint256) {
        return _getAPrecise(self).div(A_PRECISION);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function getAPrecise(SwapUtils.Swap storage self)
        external
        view
        returns (uint256)
    {
        return _getAPrecise(self);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function _getAPrecise(SwapUtils.Swap storage self)
        internal
        view
        returns (uint256)
    {
        uint256 t1 = self.futureATime; // time when ramp is finished
        uint256 a1 = self.futureA; // final A value when ramp is finished

        if (block.timestamp < t1) {
            uint256 t0 = self.initialATime; // time when ramp is started
            uint256 a0 = self.initialA; // initial A value when ramp is started
            if (a1 > a0) {
                // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
                return
                    a0.add(
                        a1.sub(a0).mul(block.timestamp.sub(t0)).div(t1.sub(t0))
                    );
            } else {
                // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
                return
                    a0.sub(
                        a0.sub(a1).mul(block.timestamp.sub(t0)).div(t1.sub(t0))
                    );
            }
        } else {
            return a1;
        }
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param self Swap struct to update
     * @param futureA_ the new A to ramp towards
     * @param futureTime_ timestamp when the new A should be reached
     */
    function rampA(
        SwapUtils.Swap storage self,
        uint256 futureA_,
        uint256 futureTime_
    ) external {
        require(
            block.timestamp >= self.initialATime.add(1 days),
            "Wait 1 day before starting ramp"
        );
        require(
            futureTime_ >= block.timestamp.add(MIN_RAMP_TIME),
            "Insufficient ramp time"
        );
        require(
            futureA_ > 0 && futureA_ < MAX_A,
            "futureA_ must be > 0 and < MAX_A"
        );

        uint256 initialAPrecise = _getAPrecise(self);
        uint256 futureAPrecise = futureA_.mul(A_PRECISION);

        if (futureAPrecise < initialAPrecise) {
            require(
                futureAPrecise.mul(MAX_A_CHANGE) >= initialAPrecise,
                "futureA_ is too small"
            );
        } else {
            require(
                futureAPrecise <= initialAPrecise.mul(MAX_A_CHANGE),
                "futureA_ is too large"
            );
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureTime_;

        emit RampA(
            initialAPrecise,
            futureAPrecise,
            block.timestamp,
            futureTime_
        );
    }

    /**
     * @notice Stops ramping A immediately. Once this function is called, rampA()
     * cannot be called for another 24 hours
     * @param self Swap struct to update
     */
    function stopRampA(SwapUtils.Swap storage self) external {
        require(self.futureATime > block.timestamp, "Ramp is already stopped");

        uint256 currentA = _getAPrecise(self);
        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./AmplificationUtils.sol";
import "./LPToken.sol";
import "./MathUtils.sol";

/**
 * @title SwapUtils library
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities.
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library SwapUtils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;

    /*** EVENTS ***/

    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);

    struct Swap {
        // variables around the ramp management of A,
        // the amplification coefficient * n * (n - 1)
        // see https://www.curve.fi/stableswap-paper.pdf for details
        uint256 initialA;
        uint256 futureA;
        uint256 initialATime;
        uint256 futureATime;
        // fee calculation
        uint256 swapFee;
        uint256 adminFee;
        uint256 defaultWithdrawFee;
        LPToken lpToken;
        // contract references for all tokens being pooled
        IERC20[] pooledTokens;
        // multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS
        // for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
        // has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
        uint256[] tokenPrecisionMultipliers;
        // the pool balance of each token, in the token's precision
        // the contract's actual token balance might differ
        uint256[] balances;
        mapping(address => uint256) depositTimestamp;
        mapping(address => uint256) withdrawFeeMultiplier;
    }

    // Struct storing variables used in calculations in the
    // calculateWithdrawOneTokenDY function to avoid stack too deep errors
    struct CalculateWithdrawOneTokenDYInfo {
        uint256 d0;
        uint256 d1;
        uint256 newY;
        uint256 feePerToken;
        uint256 preciseA;
    }

    // Struct storing variables used in calculations in the
    // {add,remove}Liquidity functions to avoid stack too deep errors
    struct ManageLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
        LPToken lpToken;
        uint256 totalSupply;
        uint256[] balances;
        uint256[] multipliers;
    }

    // the precision all pools tokens will be converted to
    uint8 public constant POOL_PRECISION_DECIMALS = 18;

    // the denominator used to calculate admin and LP fees. For example, an
    // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
    uint256 private constant FEE_DENOMINATOR = 10**10;

    // Max swap fee is 1% or 100bps of each swap
    uint256 public constant MAX_SWAP_FEE = 10**8;

    // Max adminFee is 100% of the swapFee
    // adminFee does not add additional fee on top of swapFee
    // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
    // users but only on the earnings of LPs
    uint256 public constant MAX_ADMIN_FEE = 10**10;

    // Max withdrawFee is 1% of the value withdrawn
    // Fee will be redistributed to the LPs in the pool, rewarding
    // long term providers.
    uint256 public constant MAX_WITHDRAW_FEE = 10**8;

    // Constant value used as max loop limit
    uint256 private constant MAX_LOOP_LIMIT = 256;

    // Time that it should take for the withdraw fee to fully decay to 0
    uint256 public constant WITHDRAW_FEE_DECAY_TIME = 4 weeks;

    /*** VIEW & PURE FUNCTIONS ***/

    /**
     * @notice Retrieves the timestamp of last deposit made by the given address
     * @param self Swap struct to read from
     * @return timestamp of last deposit
     */
    function getDepositTimestamp(Swap storage self, address user)
        external
        view
        returns (uint256)
    {
        return self.depositTimestamp[user];
    }

    function _getAPrecise(Swap storage self) internal view returns (uint256) {
        return AmplificationUtils._getAPrecise(self);
    }

    /**
     * @notice Calculate the dy, the amount of selected token that user receives and
     * the fee of withdrawing in one token
     * @param account the address that is withdrawing
     * @param tokenAmount the amount to withdraw in the pool's precision
     * @param tokenIndex which token will be withdrawn
     * @param self Swap struct to read from
     * @return the amount of token user will receive
     */
    function calculateWithdrawOneToken(
        Swap storage self,
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256) {
        (uint256 availableTokenAmount, ) =
            _calculateWithdrawOneToken(
                self,
                account,
                tokenAmount,
                tokenIndex,
                self.lpToken.totalSupply()
            );
        return availableTokenAmount;
    }

    function _calculateWithdrawOneToken(
        Swap storage self,
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 totalSupply
    ) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 newY;
        uint256 currentY;

        (dy, newY, currentY) = calculateWithdrawOneTokenDY(
            self,
            tokenIndex,
            tokenAmount,
            totalSupply
        );

        // dy_0 (without fees)
        // dy, dy_0 - dy

        uint256 dySwapFee =
            currentY
                .sub(newY)
                .div(self.tokenPrecisionMultipliers[tokenIndex])
                .sub(dy);

        dy = dy
            .mul(
            FEE_DENOMINATOR.sub(_calculateCurrentWithdrawFee(self, account))
        )
            .div(FEE_DENOMINATOR);

        return (dy, dySwapFee);
    }

    /**
     * @notice Calculate the dy of withdrawing in one token
     * @param self Swap struct to read from
     * @param tokenIndex which token will be withdrawn
     * @param tokenAmount the amount to withdraw in the pools precision
     * @return the d and the new y after withdrawing one token
     */
    function calculateWithdrawOneTokenDY(
        Swap storage self,
        uint8 tokenIndex,
        uint256 tokenAmount,
        uint256 totalSupply
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Get the current D, then solve the stableswap invariant
        // y_i for D - tokenAmount
        uint256[] memory xp = _xp(self);

        require(tokenIndex < xp.length, "Token index out of range");

        CalculateWithdrawOneTokenDYInfo memory v =
            CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
        v.preciseA = _getAPrecise(self);
        v.d0 = getD(xp, v.preciseA);
        v.d1 = v.d0.sub(tokenAmount.mul(v.d0).div(totalSupply));

        require(tokenAmount <= xp[tokenIndex], "Withdraw exceeds available");

        v.newY = getYD(v.preciseA, tokenIndex, xp, v.d1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        v.feePerToken = _feePerToken(self.swapFee, xp.length);
        for (uint256 i = 0; i < xp.length; i++) {
            uint256 xpi = xp[i];
            // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
            // else dxExpected = xp[i] - (xp[i] * d1 / d0)
            // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
            xpReduced[i] = xpi.sub(
                (
                    (i == tokenIndex)
                        ? xpi.mul(v.d1).div(v.d0).sub(v.newY)
                        : xpi.sub(xpi.mul(v.d1).div(v.d0))
                )
                    .mul(v.feePerToken)
                    .div(FEE_DENOMINATOR)
            );
        }

        uint256 dy =
            xpReduced[tokenIndex].sub(
                getYD(v.preciseA, tokenIndex, xpReduced, v.d1)
            );
        dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

        return (dy, v.newY, xp[tokenIndex]);
    }

    /**
     * @notice Calculate the price of a token in the pool with given
     * precision-adjusted balances and a particular D.
     *
     * @dev This is accomplished via solving the invariant iteratively.
     * See the StableSwap paper and Curve.fi implementation for further details.
     *
     * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     * x_1**2 + b*x_1 = c
     * x_1 = (x_1**2 + c) / (2*x_1 + b)
     *
     * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
     * @param tokenIndex Index of token we are calculating for.
     * @param xp a precision-adjusted set of pool balances. Array should be
     * the same cardinality as the pool.
     * @param d the stableswap invariant
     * @return the price of the token, in the same precision as in xp
     */
    function getYD(
        uint256 a,
        uint8 tokenIndex,
        uint256[] memory xp,
        uint256 d
    ) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndex < numTokens, "Token not found");

        uint256 c = d;
        uint256 s;
        uint256 nA = a.mul(numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s.add(xp[i]);
                c = c.mul(d).div(xp[i].mul(numTokens));
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // c = c * D * D * D * ... overflow!
            }
        }
        c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));

        uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = d;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
     * @param xp a precision-adjusted set of pool balances. Array should be the same cardinality
     * as the pool.
     * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
     * See the StableSwap paper for details
     * @return the invariant, at the precision of the pool
     */
    function getD(uint256[] memory xp, uint256 a)
        internal
        pure
        returns (uint256)
    {
        uint256 numTokens = xp.length;
        uint256 s;
        for (uint256 i = 0; i < numTokens; i++) {
            s = s.add(xp[i]);
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a.mul(numTokens);

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = dP.mul(d).div(xp[j].mul(numTokens));
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // dP = dP * D * D * D * ... overflow!
            }
            prevD = d;
            d = nA
                .mul(s)
                .div(AmplificationUtils.A_PRECISION)
                .add(dP.mul(numTokens))
                .mul(d)
                .div(
                nA
                    .sub(AmplificationUtils.A_PRECISION)
                    .mul(d)
                    .div(AmplificationUtils.A_PRECISION)
                    .add(numTokens.add(1).mul(dP))
            );
            if (d.within1(prevD)) {
                return d;
            }
        }

        // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
        // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
        // function which does not rely on D.
        revert("D does not converge");
    }

    /**
     * @notice Given a set of balances and precision multipliers, return the
     * precision-adjusted balances.
     *
     * @param balances an array of token balances, in their native precisions.
     * These should generally correspond with pooled tokens.
     *
     * @param precisionMultipliers an array of multipliers, corresponding to
     * the amounts in the balances array. When multiplied together they
     * should yield amounts at the pool's precision.
     *
     * @return an array of amounts "scaled" to the pool's precision
     */
    function _xp(
        uint256[] memory balances,
        uint256[] memory precisionMultipliers
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = balances.length;
        require(
            numTokens == precisionMultipliers.length,
            "Balances must match multipliers"
        );
        uint256[] memory xp = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = balances[i].mul(precisionMultipliers[i]);
        }
        return xp;
    }

    /**
     * @notice Return the precision-adjusted balances of all tokens in the pool
     * @param self Swap struct to read from
     * @return the pool balances "scaled" to the pool's precision, allowing
     * them to be more easily compared.
     */
    function _xp(Swap storage self) internal view returns (uint256[] memory) {
        return _xp(self.balances, self.tokenPrecisionMultipliers);
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @param self Swap struct to read from
     * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice(Swap storage self)
        external
        view
        returns (uint256)
    {
        uint256 d = getD(_xp(self), _getAPrecise(self));
        LPToken lpToken = self.lpToken;
        uint256 supply = lpToken.totalSupply();
        if (supply > 0) {
            return d.mul(10**uint256(POOL_PRECISION_DECIMALS)).div(supply);
        }
        return 0;
    }

    /**
     * @notice Calculate the new balances of the tokens given the indexes of the token
     * that is swapped from (FROM) and the token that is swapped to (TO).
     * This function is used as a helper function to calculate how much TO token
     * the user should receive on swap.
     *
     * @param preciseA precise form of amplification coefficient
     * @param tokenIndexFrom index of FROM token
     * @param tokenIndexTo index of TO token
     * @param x the new total amount of FROM token
     * @param xp balances of the tokens in the pool
     * @return the amount of TO token that should remain in the pool
     */
    function getY(
        uint256 preciseA,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 x,
        uint256[] memory xp
    ) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(
            tokenIndexFrom != tokenIndexTo,
            "Can't compare token to itself"
        );
        require(
            tokenIndexFrom < numTokens && tokenIndexTo < numTokens,
            "Tokens must be in pool"
        );

        uint256 d = getD(xp, preciseA);
        uint256 c = d;
        uint256 s;
        uint256 nA = numTokens.mul(preciseA);

        uint256 _x;
        for (uint256 i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            } else {
                continue;
            }
            s = s.add(_x);
            c = c.mul(d).div(_x.mul(numTokens));
            // If we were to protect the division loss we would have to keep the denominator separate
            // and divide at the end. However this leads to overflow with large numTokens or/and D.
            // c = c * D * D * D * ... overflow!
        }
        c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));
        uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = d;

        // iterative approximation
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Externally calculates a swap between two tokens.
     * @param self Swap struct to read from
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return dy the number of tokens the user will get
     */
    function calculateSwap(
        Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(
            self,
            tokenIndexFrom,
            tokenIndexTo,
            dx,
            self.balances
        );
    }

    /**
     * @notice Internally calculates a swap between two tokens.
     *
     * @dev The caller is expected to transfer the actual amounts (dx and dy)
     * using the token contracts.
     *
     * @param self Swap struct to read from
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return dy the number of tokens the user will get
     * @return dyFee the associated fee
     */
    function _calculateSwap(
        Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256[] memory balances
    ) internal view returns (uint256 dy, uint256 dyFee) {
        uint256[] memory multipliers = self.tokenPrecisionMultipliers;
        uint256[] memory xp = _xp(balances, multipliers);
        require(
            tokenIndexFrom < xp.length && tokenIndexTo < xp.length,
            "Token index out of range"
        );
        uint256 x = dx.mul(multipliers[tokenIndexFrom]).add(xp[tokenIndexFrom]);
        uint256 y =
            getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, xp);
        dy = xp[tokenIndexTo].sub(y).sub(1);
        dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        dy = dy.sub(dyFee).div(multipliers[tokenIndexTo]);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of
     * LP tokens
     *
     * @param account the address that is removing liquidity. required for withdraw fee calculation
     * @param amount the amount of LP tokens that would to be burned on
     * withdrawal
     * @return array of amounts of tokens user will receive
     */
    function calculateRemoveLiquidity(
        Swap storage self,
        address account,
        uint256 amount
    ) external view returns (uint256[] memory) {
        return
            _calculateRemoveLiquidity(
                self,
                self.balances,
                account,
                amount,
                self.lpToken.totalSupply()
            );
    }

    function _calculateRemoveLiquidity(
        Swap storage self,
        uint256[] memory balances,
        address account,
        uint256 amount,
        uint256 totalSupply
    ) internal view returns (uint256[] memory) {
        require(amount <= totalSupply, "Cannot exceed total supply");

        uint256 feeAdjustedAmount =
            amount
                .mul(
                FEE_DENOMINATOR.sub(_calculateCurrentWithdrawFee(self, account))
            )
                .div(FEE_DENOMINATOR);

        uint256[] memory amounts = new uint256[](balances.length);

        for (uint256 i = 0; i < balances.length; i++) {
            amounts[i] = balances[i].mul(feeAdjustedAmount).div(totalSupply);
        }
        return amounts;
    }

    /**
     * @notice Calculate the fee that is applied when the given user withdraws.
     * Withdraw fee decays linearly over WITHDRAW_FEE_DECAY_TIME.
     * @param user address you want to calculate withdraw fee of
     * @return current withdraw fee of the user
     */
    function calculateCurrentWithdrawFee(Swap storage self, address user)
        external
        view
        returns (uint256)
    {
        return _calculateCurrentWithdrawFee(self, user);
    }

    function _calculateCurrentWithdrawFee(Swap storage self, address user)
        internal
        view
        returns (uint256)
    {
        uint256 endTime =
            self.depositTimestamp[user].add(WITHDRAW_FEE_DECAY_TIME);
        if (endTime > block.timestamp) {
            uint256 timeLeftover = endTime.sub(block.timestamp);
            return
                self
                    .defaultWithdrawFee
                    .mul(self.withdrawFeeMultiplier[user])
                    .mul(timeLeftover)
                    .div(WITHDRAW_FEE_DECAY_TIME)
                    .div(FEE_DENOMINATOR);
        }
        return 0;
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param self Swap struct to read from
     * @param account address of the account depositing or withdrawing tokens
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return if deposit was true, total amount of lp token that will be minted and if
     * deposit was false, total amount of lp token that will be burned
     */
    function calculateTokenAmount(
        Swap storage self,
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256) {
        uint256 a = _getAPrecise(self);
        uint256[] memory balances = self.balances;
        uint256[] memory multipliers = self.tokenPrecisionMultipliers;

        uint256 d0 = getD(_xp(balances, multipliers), a);
        for (uint256 i = 0; i < balances.length; i++) {
            if (deposit) {
                balances[i] = balances[i].add(amounts[i]);
            } else {
                balances[i] = balances[i].sub(
                    amounts[i],
                    "Cannot withdraw more than available"
                );
            }
        }
        uint256 d1 = getD(_xp(balances, multipliers), a);
        uint256 totalSupply = self.lpToken.totalSupply();

        if (deposit) {
            return d1.sub(d0).mul(totalSupply).div(d0);
        } else {
            return
                d0.sub(d1).mul(totalSupply).div(d0).mul(FEE_DENOMINATOR).div(
                    FEE_DENOMINATOR.sub(
                        _calculateCurrentWithdrawFee(self, account)
                    )
                );
        }
    }

    /**
     * @notice return accumulated amount of admin fees of the token with given index
     * @param self Swap struct to read from
     * @param index Index of the pooled token
     * @return admin balance in the token's precision
     */
    function getAdminBalance(Swap storage self, uint256 index)
        external
        view
        returns (uint256)
    {
        require(index < self.pooledTokens.length, "Token index out of range");
        return
            self.pooledTokens[index].balanceOf(address(this)).sub(
                self.balances[index]
            );
    }

    /**
     * @notice internal helper function to calculate fee per token multiplier used in
     * swap fee calculations
     * @param swapFee swap fee for the tokens
     * @param numTokens number of tokens pooled
     */
    function _feePerToken(uint256 swapFee, uint256 numTokens)
        internal
        pure
        returns (uint256)
    {
        return swapFee.mul(numTokens).div(numTokens.sub(1).mul(4));
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice swap two tokens in the pool
     * @param self Swap struct to read from and write to
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell
     * @param minDy the min amount the user would like to receive, or revert.
     * @return amount of token user received on swap
     */
    function swap(
        Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256) {
        {
            IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
            require(
                dx <= tokenFrom.balanceOf(msg.sender),
                "Cannot swap more than you own"
            );
            // Transfer tokens first to see if a fee was charged on transfer
            uint256 beforeBalance = tokenFrom.balanceOf(address(this));
            tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

            // Use the actual transferred amount for AMM math
            dx = tokenFrom.balanceOf(address(this)).sub(beforeBalance);
        }

        uint256 dy;
        uint256 dyFee;
        uint256[] memory balances = self.balances;
        (dy, dyFee) = _calculateSwap(
            self,
            tokenIndexFrom,
            tokenIndexTo,
            dx,
            balances
        );
        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee =
            dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
                self.tokenPrecisionMultipliers[tokenIndexTo]
            );

        self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx);
        self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy).sub(
            dyAdminFee
        );

        self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

        return dy;
    }

    /**
     * @notice Add liquidity to the pool
     * @param self Swap struct to read from and write to
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
     * @return amount of LP token user received
     */
    function addLiquidity(
        Swap storage self,
        uint256[] memory amounts,
        uint256 minToMint
    ) external returns (uint256) {
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(
            amounts.length == pooledTokens.length,
            "Amounts must match pooled tokens"
        );

        // current state
        ManageLiquidityInfo memory v =
            ManageLiquidityInfo(
                0,
                0,
                0,
                _getAPrecise(self),
                self.lpToken,
                0,
                self.balances,
                self.tokenPrecisionMultipliers
            );
        v.totalSupply = v.lpToken.totalSupply();

        if (v.totalSupply != 0) {
            v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
        }

        uint256[] memory newBalances = new uint256[](pooledTokens.length);

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            require(
                v.totalSupply != 0 || amounts[i] > 0,
                "Must supply all tokens in pool"
            );

            // Transfer tokens first to see if a fee was charged on transfer
            if (amounts[i] != 0) {
                uint256 beforeBalance =
                    pooledTokens[i].balanceOf(address(this));
                pooledTokens[i].safeTransferFrom(
                    msg.sender,
                    address(this),
                    amounts[i]
                );

                // Update the amounts[] with actual transfer amount
                amounts[i] = pooledTokens[i].balanceOf(address(this)).sub(
                    beforeBalance
                );
            }

            newBalances[i] = v.balances[i].add(amounts[i]);
        }

        // invariant after change
        v.d1 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        require(v.d1 > v.d0, "D should increase");

        // updated to reflect fees and calculate the user's LP tokens
        v.d2 = v.d1;
        uint256[] memory fees = new uint256[](pooledTokens.length);

        if (v.totalSupply != 0) {
            uint256 feePerToken =
                _feePerToken(self.swapFee, pooledTokens.length);
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
                fees[i] = feePerToken
                    .mul(idealBalance.difference(newBalances[i]))
                    .div(FEE_DENOMINATOR);
                self.balances[i] = newBalances[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR)
                );
                newBalances[i] = newBalances[i].sub(fees[i]);
            }
            v.d2 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        } else {
            // the initial depositor doesn't pay fees
            self.balances = newBalances;
        }

        uint256 toMint;
        if (v.totalSupply == 0) {
            toMint = v.d1;
        } else {
            toMint = v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
        }

        require(toMint >= minToMint, "Couldn't mint min requested");

        // mint the user's LP tokens
        v.lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(
            msg.sender,
            amounts,
            fees,
            v.d1,
            v.totalSupply.add(toMint)
        );

        return toMint;
    }

    /**
     * @notice Update the withdraw fee for `user`. If the user is currently
     * not providing liquidity in the pool, sets to default value. If not, recalculate
     * the starting withdraw fee based on the last deposit's time & amount relative
     * to the new deposit.
     *
     * @param self Swap struct to read from and write to
     * @param user address of the user depositing tokens
     * @param toMint amount of pool tokens to be minted
     */
    function updateUserWithdrawFee(
        Swap storage self,
        address user,
        uint256 toMint
    ) public {
        // If token is transferred to address 0 (or burned), don't update the fee.
        if (user == address(0)) {
            return;
        }
        if (self.defaultWithdrawFee == 0) {
            // If current fee is set to 0%, set multiplier to FEE_DENOMINATOR
            self.withdrawFeeMultiplier[user] = FEE_DENOMINATOR;
        } else {
            // Otherwise, calculate appropriate discount based on last deposit amount
            uint256 currentFee = _calculateCurrentWithdrawFee(self, user);
            uint256 currentBalance = self.lpToken.balanceOf(user);

            // ((currentBalance * currentFee) + (toMint * defaultWithdrawFee)) * FEE_DENOMINATOR /
            // ((toMint + currentBalance) * defaultWithdrawFee)
            self.withdrawFeeMultiplier[user] = currentBalance
                .mul(currentFee)
                .add(toMint.mul(self.defaultWithdrawFee))
                .mul(FEE_DENOMINATOR)
                .div(toMint.add(currentBalance).mul(self.defaultWithdrawFee));
        }
        self.depositTimestamp[user] = block.timestamp;
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param self Swap struct to read from and write to
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     * acceptable for this burn. Useful as a front-running mitigation
     * @return amounts of tokens the user received
     */
    function removeLiquidity(
        Swap storage self,
        uint256 amount,
        uint256[] calldata minAmounts
    ) external returns (uint256[] memory) {
        LPToken lpToken = self.lpToken;
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(
            minAmounts.length == pooledTokens.length,
            "minAmounts must match poolTokens"
        );

        uint256[] memory balances = self.balances;
        uint256 totalSupply = lpToken.totalSupply();

        uint256[] memory amounts =
            _calculateRemoveLiquidity(
                self,
                balances,
                msg.sender,
                amount,
                totalSupply
            );

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
            self.balances[i] = balances[i].sub(amounts[i]);
            pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        lpToken.burnFrom(msg.sender, amount);

        emit RemoveLiquidity(msg.sender, amounts, totalSupply.sub(amount));

        return amounts;
    }

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param self Swap struct to read from and write to
     * @param tokenAmount the amount of the lp tokens to burn
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @return amount chosen token that user received
     */
    function removeLiquidityOneToken(
        Swap storage self,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount
    ) external returns (uint256) {
        LPToken lpToken = self.lpToken;
        IERC20[] memory pooledTokens = self.pooledTokens;

        require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(tokenIndex < pooledTokens.length, "Token not found");

        uint256 totalSupply = lpToken.totalSupply();

        (uint256 dy, uint256 dyFee) =
            _calculateWithdrawOneToken(
                self,
                msg.sender,
                tokenAmount,
                tokenIndex,
                totalSupply
            );

        require(dy >= minAmount, "dy < minAmount");

        self.balances[tokenIndex] = self.balances[tokenIndex].sub(
            dy.add(dyFee.mul(self.adminFee).div(FEE_DENOMINATOR))
        );
        lpToken.burnFrom(msg.sender, tokenAmount);
        pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(
            msg.sender,
            tokenAmount,
            totalSupply,
            tokenIndex,
            dy
        );

        return dy;
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     *
     * @param self Swap struct to read from and write to
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @return actual amount of LP tokens burned in the withdrawal
     */
    function removeLiquidityImbalance(
        Swap storage self,
        uint256[] memory amounts,
        uint256 maxBurnAmount
    ) public returns (uint256) {
        ManageLiquidityInfo memory v =
            ManageLiquidityInfo(
                0,
                0,
                0,
                _getAPrecise(self),
                self.lpToken,
                0,
                self.balances,
                self.tokenPrecisionMultipliers
            );
        v.totalSupply = v.lpToken.totalSupply();

        IERC20[] memory pooledTokens = self.pooledTokens;

        require(
            amounts.length == pooledTokens.length,
            "Amounts should match pool tokens"
        );

        require(
            maxBurnAmount <= v.lpToken.balanceOf(msg.sender) &&
                maxBurnAmount != 0,
            ">LP.balanceOf"
        );

        uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);
        uint256[] memory fees = new uint256[](pooledTokens.length);
        {
            uint256[] memory balances1 = new uint256[](pooledTokens.length);
            v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                balances1[i] = v.balances[i].sub(
                    amounts[i],
                    "Cannot withdraw more than available"
                );
            }
            v.d1 = getD(_xp(balances1, v.multipliers), v.preciseA);

            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
                uint256 difference = idealBalance.difference(balances1[i]);
                fees[i] = feePerToken.mul(difference).div(FEE_DENOMINATOR);
                self.balances[i] = balances1[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR)
                );
                balances1[i] = balances1[i].sub(fees[i]);
            }

            v.d2 = getD(_xp(balances1, v.multipliers), v.preciseA);
        }
        uint256 tokenAmount = v.d0.sub(v.d2).mul(v.totalSupply).div(v.d0);
        require(tokenAmount != 0, "Burnt amount cannot be zero");
        tokenAmount = tokenAmount.add(1).mul(FEE_DENOMINATOR).div(
            FEE_DENOMINATOR.sub(_calculateCurrentWithdrawFee(self, msg.sender))
        );

        require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

        v.lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(
            msg.sender,
            amounts,
            fees,
            v.d1,
            v.totalSupply.sub(tokenAmount)
        );

        return tokenAmount;
    }

    /**
     * @notice withdraw all admin fees to a given address
     * @param self Swap struct to withdraw fees from
     * @param to Address to send the fees to
     */
    function withdrawAdminFees(Swap storage self, address to) external {
        IERC20[] memory pooledTokens = self.pooledTokens;
        for (uint256 i = 0; i < pooledTokens.length; i++) {
            IERC20 token = pooledTokens[i];
            uint256 balance =
                token.balanceOf(address(this)).sub(self.balances[i]);
            if (balance != 0) {
                token.safeTransfer(to, balance);
            }
        }
    }

    /**
     * @notice Sets the admin fee
     * @dev adminFee cannot be higher than 100% of the swap fee
     * @param self Swap struct to update
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(Swap storage self, uint256 newAdminFee) external {
        require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
        self.adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }

    /**
     * @notice update the swap fee
     * @dev fee cannot be higher than 1% of each swap
     * @param self Swap struct to update
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(Swap storage self, uint256 newSwapFee) external {
        require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
        self.swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }

    /**
     * @notice update the default withdraw fee. This also affects deposits made in the past as well.
     * @param self Swap struct to update
     * @param newWithdrawFee new withdraw fee to be applied
     */
    function setDefaultWithdrawFee(Swap storage self, uint256 newWithdrawFee)
        external
    {
        require(newWithdrawFee <= MAX_WITHDRAW_FEE, "Fee is too high");
        self.defaultWithdrawFee = newWithdrawFee;

        emit NewWithdrawFee(newWithdrawFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ISwap.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Initializes this LPToken contract with the given name and symbol
     * @dev The caller of this function will become the owner. A Swap contract should call this
     * in its initializer function.
     * @param name name of this token
     * @param symbol symbol of this token
     */
    function initialize(string memory name, string memory symbol)
        external
        initializer
        returns (bool)
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __Ownable_init_unchained();
        return true;
    }

    /**
     * @notice Mints the given amount of LPToken to the recipient.
     * @dev only owner can call this mint function
     * @param recipient address of account to receive the tokens
     * @param amount amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(amount != 0, "LPToken: cannot mint 0");
        _mint(recipient, amount);
    }

    /**
     * @dev Overrides ERC20._beforeTokenTransfer() which get called on every transfers including
     * minting and burning. This ensures that Swap.updateUserWithdrawFees are called everytime.
     * This assumes the owner is set to a Swap contract's address.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
        require(to != address(this), "LPToken: cannot send to itself");
        ISwap(owner()).updateUserWithdrawFee(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title MathUtils library
 * @notice A library to be used in conjunction with SafeMath. Contains functions for calculating
 * differences between two uint256.
 */
library MathUtils {
    /**
     * @notice Compares a and b and returns true if the difference between a and b
     *         is less than 1 or equal to each other.
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return True if the difference between a and b is less than 1 or equal,
     *         otherwise return false
     */
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        return (difference(a, b) <= 1);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        }
        return b - a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ISwap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidity(address account, uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        IERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        uint256 withdrawFee,
        address lpTokenTargetAddress
    ) external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    // withdraw fee update function
    function updateUserWithdrawFee(address recipient, uint256 transferAmount)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./OwnerPausableUpgradeable.sol";
import "./SwapUtils.sol";
import "./AmplificationUtils.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract Swap is OwnerPausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SwapUtils for SwapUtils.Swap;
    using AmplificationUtils for SwapUtils.Swap;

    // Struct storing data responsible for automatic market maker functionalities. In order to
    // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
    SwapUtils.Swap public swapStorage;

    // Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
    // getTokenIndex function also relies on this mapping to retrieve token index.
    mapping(address => uint8) private tokenIndexes;

    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients
    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);
    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _pooledTokens an array of ERC20s this pool will accept
     * @param decimals the decimals to use for each pooled token,
     * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param _withdrawFee default withdrawFee to be initialized with
     * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
     */
    function initialize(
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address lpTokenTargetAddress
    ) public virtual initializer {
        __OwnerPausable_init();
        __ReentrancyGuard_init();
        // Check _pooledTokens and precisions parameter
        require(_pooledTokens.length > 1, "_pooledTokens.length <= 1");
        require(_pooledTokens.length <= 32, "_pooledTokens.length > 32");
        require(
            _pooledTokens.length == decimals.length,
            "_pooledTokens decimals mismatch"
        );

        uint256[] memory precisionMultipliers = new uint256[](decimals.length);

        for (uint8 i = 0; i < _pooledTokens.length; i++) {
            if (i > 0) {
                // Check if index is already used. Check if 0th element is a duplicate.
                require(
                    tokenIndexes[address(_pooledTokens[i])] == 0 &&
                        _pooledTokens[0] != _pooledTokens[i],
                    "Duplicate tokens"
                );
            }
            require(
                address(_pooledTokens[i]) != address(0),
                "The 0 address isn't an ERC-20"
            );
            require(
                decimals[i] <= SwapUtils.POOL_PRECISION_DECIMALS,
                "Token decimals exceeds max"
            );
            precisionMultipliers[i] =
                10 **
                    uint256(SwapUtils.POOL_PRECISION_DECIMALS).sub(
                        uint256(decimals[i])
                    );
            tokenIndexes[address(_pooledTokens[i])] = i;
        }

        // Check _a, _fee, _adminFee, _withdrawFee parameters
        require(_a < AmplificationUtils.MAX_A, "_a exceeds maximum");
        require(_fee < SwapUtils.MAX_SWAP_FEE, "_fee exceeds maximum");
        require(
            _adminFee < SwapUtils.MAX_ADMIN_FEE,
            "_adminFee exceeds maximum"
        );
        require(
            _withdrawFee < SwapUtils.MAX_WITHDRAW_FEE,
            "_withdrawFee exceeds maximum"
        );

        // Clone and initialize a LPToken contract
        LPToken lpToken = LPToken(Clones.clone(lpTokenTargetAddress));
        require(
            lpToken.initialize(lpTokenName, lpTokenSymbol),
            "could not init lpToken clone"
        );

        // Initialize swapStorage struct
        swapStorage.lpToken = lpToken;
        swapStorage.pooledTokens = _pooledTokens;
        swapStorage.tokenPrecisionMultipliers = precisionMultipliers;
        swapStorage.balances = new uint256[](_pooledTokens.length);
        swapStorage.initialA = _a.mul(AmplificationUtils.A_PRECISION);
        swapStorage.futureA = _a.mul(AmplificationUtils.A_PRECISION);
        // swapStorage.initialATime = 0;
        // swapStorage.futureATime = 0;
        swapStorage.swapFee = _fee;
        swapStorage.adminFee = _adminFee;
        swapStorage.defaultWithdrawFee = _withdrawFee;
    }

    /*** MODIFIERS ***/

    /**
     * @notice Modifier to check deadline against current timestamp
     * @param deadline latest timestamp to accept this transaction
     */
    modifier deadlineCheck(uint256 deadline) {
        require(block.timestamp <= deadline, "Deadline not met");
        _;
    }

    /*** VIEW FUNCTIONS ***/

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @return A parameter
     */
    function getA() external view virtual returns (uint256) {
        return swapStorage.getA();
    }

    /**
     * @notice Return A in its raw precision form
     * @dev See the StableSwap paper for details
     * @return A parameter in its raw precision form
     */
    function getAPrecise() external view virtual returns (uint256) {
        return swapStorage.getAPrecise();
    }

    /**
     * @notice Return address of the pooled token at given index. Reverts if tokenIndex is out of range.
     * @param index the index of the token
     * @return address of the token at given index
     */
    function getToken(uint8 index) public view virtual returns (IERC20) {
        require(index < swapStorage.pooledTokens.length, "Out of range");
        return swapStorage.pooledTokens[index];
    }

    /**
     * @notice Return the index of the given token address. Reverts if no matching
     * token is found.
     * @param tokenAddress address of the token
     * @return the index of the given token address
     */
    function getTokenIndex(address tokenAddress)
        public
        view
        virtual
        returns (uint8)
    {
        uint8 index = tokenIndexes[tokenAddress];
        require(
            address(getToken(index)) == tokenAddress,
            "Token does not exist"
        );
        return index;
    }

    /**
     * @notice Return timestamp of last deposit of given address
     * @return timestamp of the last deposit made by the given address
     */
    function getDepositTimestamp(address user)
        external
        view
        virtual
        returns (uint256)
    {
        return swapStorage.getDepositTimestamp(user);
    }

    /**
     * @notice Return current balance of the pooled token at given index
     * @param index the index of the token
     * @return current balance of the pooled token at given index with token's native precision
     */
    function getTokenBalance(uint8 index)
        external
        view
        virtual
        returns (uint256)
    {
        require(index < swapStorage.pooledTokens.length, "Index out of range");
        return swapStorage.balances[index];
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice() external view virtual returns (uint256) {
        return swapStorage.getVirtualPrice();
    }

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view virtual returns (uint256) {
        return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param account address that is depositing or withdrawing tokens
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return token amount the user will receive
     */
    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view virtual returns (uint256) {
        return swapStorage.calculateTokenAmount(account, amounts, deposit);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param account the address that is withdrawing tokens
     * @param amount the amount of LP tokens that would be burned on withdrawal
     * @return array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(address account, uint256 amount)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        return swapStorage.calculateRemoveLiquidity(account, amount);
    }

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param account the address that is withdrawing tokens
     * @param tokenAmount the amount of LP token to burn
     * @param tokenIndex index of which token will be withdrawn
     * @return availableTokenAmount calculated amount of underlying token
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view virtual returns (uint256 availableTokenAmount) {
        return
            swapStorage.calculateWithdrawOneToken(
                account,
                tokenAmount,
                tokenIndex
            );
    }

    /**
     * @notice Calculate the fee that is applied when the given user withdraws. The withdraw fee
     * decays linearly over period of 4 weeks. For example, depositing and withdrawing right away
     * will charge you the full amount of withdraw fee. But withdrawing after 4 weeks will charge you
     * no additional fees.
     * @dev returned value should be divided by FEE_DENOMINATOR to convert to correct decimals
     * @param user address you want to calculate withdraw fee of
     * @return current withdraw fee of the user
     */
    function calculateCurrentWithdrawFee(address user)
        external
        view
        virtual
        returns (uint256)
    {
        return swapStorage.calculateCurrentWithdrawFee(user);
    }

    /**
     * @notice This function reads the accumulated amount of admin fees of the token with given index
     * @param index Index of the pooled token
     * @return admin's token balance in the token's precision
     */
    function getAdminBalance(uint256 index)
        external
        view
        virtual
        returns (uint256)
    {
        return swapStorage.getAdminBalance(index);
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice Swap two tokens using this pool
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
        external
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
    }

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    )
        external
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.addLiquidity(amounts, minToMint);
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amounts of tokens user received
     */
    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    )
        external
        virtual
        nonReentrant
        deadlineCheck(deadline)
        returns (uint256[] memory)
    {
        return swapStorage.removeLiquidity(amount, minAmounts);
    }

    /**
     * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param tokenAmount the amount of the token you want to receive
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param deadline latest timestamp to accept this transaction
     * @return amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    )
        external
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            swapStorage.removeLiquidityOneToken(
                tokenAmount,
                tokenIndex,
                minAmount
            );
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    )
        external
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
    }

    /*** ADMIN FUNCTIONS ***/

    /**
     * @notice Updates the user withdraw fee. This function can only be called by
     * the pool token. Should be used to update the withdraw fee on transfer of pool tokens.
     * Transferring your pool token will reset the 4 weeks period. If the recipient is already
     * holding some pool tokens, the withdraw fee will be discounted in respective amounts.
     * @param recipient address of the recipient of pool token
     * @param transferAmount amount of pool token to transfer
     */
    function updateUserWithdrawFee(address recipient, uint256 transferAmount)
        external
    {
        require(
            msg.sender == address(swapStorage.lpToken),
            "Only callable by pool token"
        );
        swapStorage.updateUserWithdrawFee(recipient, transferAmount);
    }

    /**
     * @notice Withdraw all admin fees to the contract owner
     */
    function withdrawAdminFees() external onlyOwner {
        swapStorage.withdrawAdminFees(owner());
    }

    /**
     * @notice Update the admin fee. Admin fee takes portion of the swap fee.
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(uint256 newAdminFee) external onlyOwner {
        swapStorage.setAdminFee(newAdminFee);
    }

    /**
     * @notice Update the swap fee to be applied on swaps
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(uint256 newSwapFee) external onlyOwner {
        swapStorage.setSwapFee(newSwapFee);
    }

    /**
     * @notice Update the withdraw fee. This fee decays linearly over 4 weeks since
     * user's last deposit.
     * @param newWithdrawFee new withdraw fee to be applied on future deposits
     */
    function setDefaultWithdrawFee(uint256 newWithdrawFee) external onlyOwner {
        swapStorage.setDefaultWithdrawFee(newWithdrawFee);
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA and futureTime
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param futureA the new A to ramp towards
     * @param futureTime timestamp when the new A should be reached
     */
    function rampA(uint256 futureA, uint256 futureTime) external onlyOwner {
        swapStorage.rampA(futureA, futureTime);
    }

    /**
     * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
     */
    function stopRampA() external onlyOwner {
        swapStorage.stopRampA();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
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
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title OwnerPausable
 * @notice An ownable contract allows the owner to pause and unpause the
 * contract without a delay.
 * @dev Only methods using the provided modifiers will be paused.
 */
abstract contract OwnerPausableUpgradeable is
    OwnableUpgradeable,
    PausableUpgradeable
{
    function __OwnerPausable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    }

    /**
     * @notice Pause the contract. Revert if already paused.
     */
    function pause() external onlyOwner {
        PausableUpgradeable._pause();
    }

    /**
     * @notice Unpause the contract. Revert if already unpaused.
     */
    function unpause() external onlyOwner {
        PausableUpgradeable._unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT WITH AGPL-3.0-only

pragma solidity 0.6.12;

import "./Swap.sol";
import "./interfaces/IFlashLoanReceiver.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract SwapFlashLoan is Swap {
    // Total fee that is charged on all flashloans in BPS. Borrowers must repay the amount plus the flash loan fee.
    // This fee is split between the protocol and the pool.
    uint256 public flashLoanFeeBPS;
    // Share of the flash loan fee that goes to the protocol in BPS. A portion of each flash loan fee is allocated
    // to the protocol rather than the pool.
    uint256 public protocolFeeShareBPS;
    // Max BPS for limiting flash loan fee settings.
    uint256 public constant MAX_BPS = 10000;

    /*** EVENTS ***/
    event FlashLoan(
        address indexed receiver,
        uint8 tokenIndex,
        uint256 amount,
        uint256 amountFee,
        uint256 protocolFee
    );

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _pooledTokens an array of ERC20s this pool will accept
     * @param decimals the decimals to use for each pooled token,
     * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param _withdrawFee default withdrawFee to be initialized with
     * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
     */
    function initialize(
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address lpTokenTargetAddress
    ) public virtual override initializer {
        Swap.initialize(
            _pooledTokens,
            decimals,
            lpTokenName,
            lpTokenSymbol,
            _a,
            _fee,
            _adminFee,
            _withdrawFee,
            lpTokenTargetAddress
        );
        flashLoanFeeBPS = 8; // 8 bps
        protocolFeeShareBPS = 0; // 0 bps
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice Borrow the specified token from this pool for this transaction only. This function will call
     * `IFlashLoanReceiver(receiver).executeOperation` and the `receiver` must return the full amount of the token
     * and the associated fee by the end of the callback transaction. If the conditions are not met, this call
     * is reverted.
     * @param receiver the address of the receiver of the token. This address must implement the IFlashLoanReceiver
     * interface and the callback function `executeOperation`.
     * @param token the protocol fee in bps to be applied on the total flash loan fee
     * @param amount the total amount to borrow in this transaction
     * @param params optional data to pass along to the callback function
     */
    function flashLoan(
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes memory params
    ) external nonReentrant {
        uint8 tokenIndex = getTokenIndex(address(token));
        uint256 availableLiquidityBefore = token.balanceOf(address(this));
        uint256 protocolBalanceBefore =
            availableLiquidityBefore.sub(swapStorage.balances[tokenIndex]);
        require(
            amount > 0 && availableLiquidityBefore >= amount,
            "invalid amount"
        );

        // Calculate the additional amount of tokens the pool should end up with
        uint256 amountFee = amount.mul(flashLoanFeeBPS).div(10000);
        // Calculate the portion of the fee that will go to the protocol
        uint256 protocolFee = amountFee.mul(protocolFeeShareBPS).div(10000);
        require(amountFee > 0, "amount is small for a flashLoan");

        // Transfer the requested amount of tokens
        token.safeTransfer(receiver, amount);

        // Execute callback function on receiver
        IFlashLoanReceiver(receiver).executeOperation(
            address(this),
            address(token),
            amount,
            amountFee,
            params
        );

        uint256 availableLiquidityAfter = token.balanceOf(address(this));
        require(
            availableLiquidityAfter >= availableLiquidityBefore.add(amountFee),
            "flashLoan fee is not met"
        );

        swapStorage.balances[tokenIndex] = availableLiquidityAfter
            .sub(protocolBalanceBefore)
            .sub(protocolFee);
        emit FlashLoan(receiver, tokenIndex, amount, amountFee, protocolFee);
    }

    /*** ADMIN FUNCTIONS ***/

    /**
     * @notice Updates the flash loan fee parameters. This function can only be called by the owner.
     * @param newFlashLoanFeeBPS the total fee in bps to be applied on future flash loans
     * @param newProtocolFeeShareBPS the protocol fee in bps to be applied on the total flash loan fee
     */
    function setFlashLoanFees(
        uint256 newFlashLoanFeeBPS,
        uint256 newProtocolFeeShareBPS
    ) external onlyOwner {
        require(
            newFlashLoanFeeBPS > 0 &&
                newFlashLoanFeeBPS <= MAX_BPS &&
                newProtocolFeeShareBPS <= MAX_BPS,
            "fees are not in valid range"
        );
        flashLoanFeeBPS = newFlashLoanFeeBPS;
        protocolFeeShareBPS = newProtocolFeeShareBPS;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.6.12;

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Nerve fee IFlashLoanReceiver. Modified from Aave's IFlashLoanReceiver interface.
 * https://github.com/aave/aave-protocol/blob/4b4545fb583fd4f400507b10f3c3114f45b8a037/contracts/flashloan/interfaces/IFlashLoanReceiver.sol
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address pool,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/ISwapFlashLoan.sol";
import "hardhat/console.sol";

contract FlashLoanBorrowerExample is IFlashLoanReceiver {
    using SafeMath for uint256;

    // Typical executeOperation function should do the 3 following actions
    // 1. Check if the flashLoan was successful
    // 2. Do actions with the borrowed tokens
    // 3. Repay the debt to the `pool`
    function executeOperation(
        address pool,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external override {
        // 1. Check if the flashLoan was valid
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "flashloan is broken?"
        );

        // 2. Do actions with the borrowed token
        bytes32 paramsHash = keccak256(params);
        if (paramsHash == keccak256(bytes("dontRepayDebt"))) {
            return;
        } else if (paramsHash == keccak256(bytes("reentrancy_addLiquidity"))) {
            ISwapFlashLoan(pool).addLiquidity(
                new uint256[](0),
                0,
                block.timestamp
            );
        } else if (paramsHash == keccak256(bytes("reentrancy_swap"))) {
            ISwapFlashLoan(pool).swap(1, 0, 1e6, 0, now);
        } else if (
            paramsHash == keccak256(bytes("reentrancy_removeLiquidity"))
        ) {
            ISwapFlashLoan(pool).removeLiquidity(1e18, new uint256[](0), now);
        } else if (
            paramsHash == keccak256(bytes("reentrancy_removeLiquidityOneToken"))
        ) {
            ISwapFlashLoan(pool).removeLiquidityOneToken(1e18, 0, 1e18, now);
        }

        // 3. Payback debt
        uint256 totalDebt = amount.add(fee);
        IERC20(token).transfer(pool, totalDebt);
    }

    function flashLoan(
        ISwapFlashLoan swap,
        IERC20 token,
        uint256 amount,
        bytes memory params
    ) external {
        swap.flashLoan(address(this), token, amount, params);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ISwap.sol";

interface ISwapFlashLoan is ISwap {
    function flashLoan(
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes memory params
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../interfaces/ISwap.sol";
import "hardhat/console.sol";

contract TestSwapReturnValues {
    using SafeMath for uint256;

    ISwap public swap;
    IERC20 public lpToken;
    uint8 public n;

    uint256 public constant MAX_INT = 2**256 - 1;

    constructor(
        ISwap swapContract,
        IERC20 lpTokenContract,
        uint8 numOfTokens
    ) public {
        swap = swapContract;
        lpToken = lpTokenContract;
        n = numOfTokens;

        // Pre-approve tokens
        for (uint8 i; i < n; i++) {
            swap.getToken(i).approve(address(swap), MAX_INT);
        }
        lpToken.approve(address(swap), MAX_INT);
    }

    function test_swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) public {
        uint256 balanceBefore =
            swap.getToken(tokenIndexTo).balanceOf(address(this));
        uint256 returnValue =
            swap.swap(tokenIndexFrom, tokenIndexTo, dx, minDy, block.timestamp);
        uint256 balanceAfter =
            swap.getToken(tokenIndexTo).balanceOf(address(this));

        console.log(
            "swap: Expected %s, got %s",
            balanceAfter.sub(balanceBefore),
            returnValue
        );

        require(
            returnValue == balanceAfter.sub(balanceBefore),
            "swap()'s return value does not match received amount"
        );
    }

    function test_addLiquidity(uint256[] calldata amounts, uint256 minToMint)
        public
    {
        uint256 balanceBefore = lpToken.balanceOf(address(this));
        uint256 returnValue = swap.addLiquidity(amounts, minToMint, MAX_INT);
        uint256 balanceAfter = lpToken.balanceOf(address(this));

        console.log(
            "addLiquidity: Expected %s, got %s",
            balanceAfter.sub(balanceBefore),
            returnValue
        );

        require(
            returnValue == balanceAfter.sub(balanceBefore),
            "addLiquidity()'s return value does not match minted amount"
        );
    }

    function test_removeLiquidity(uint256 amount, uint256[] memory minAmounts)
        public
    {
        uint256[] memory balanceBefore = new uint256[](n);
        uint256[] memory balanceAfter = new uint256[](n);

        for (uint8 i = 0; i < n; i++) {
            balanceBefore[i] = swap.getToken(i).balanceOf(address(this));
        }

        uint256[] memory returnValue =
            swap.removeLiquidity(amount, minAmounts, MAX_INT);

        for (uint8 i = 0; i < n; i++) {
            balanceAfter[i] = swap.getToken(i).balanceOf(address(this));
            console.log(
                "removeLiquidity: Expected %s, got %s",
                balanceAfter[i].sub(balanceBefore[i]),
                returnValue[i]
            );
            require(
                balanceAfter[i].sub(balanceBefore[i]) == returnValue[i],
                "removeLiquidity()'s return value does not match received amounts of tokens"
            );
        }
    }

    function test_removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount
    ) public {
        uint256 balanceBefore = lpToken.balanceOf(address(this));
        uint256 returnValue =
            swap.removeLiquidityImbalance(amounts, maxBurnAmount, MAX_INT);
        uint256 balanceAfter = lpToken.balanceOf(address(this));

        console.log(
            "removeLiquidityImbalance: Expected %s, got %s",
            balanceBefore.sub(balanceAfter),
            returnValue
        );

        require(
            returnValue == balanceBefore.sub(balanceAfter),
            "removeLiquidityImbalance()'s return value does not match burned lpToken amount"
        );
    }

    function test_removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount
    ) public {
        uint256 balanceBefore =
            swap.getToken(tokenIndex).balanceOf(address(this));
        uint256 returnValue =
            swap.removeLiquidityOneToken(
                tokenAmount,
                tokenIndex,
                minAmount,
                MAX_INT
            );
        uint256 balanceAfter =
            swap.getToken(tokenIndex).balanceOf(address(this));

        console.log(
            "removeLiquidityOneToken: Expected %s, got %s",
            balanceAfter.sub(balanceBefore),
            returnValue
        );

        require(
            returnValue == balanceAfter.sub(balanceBefore),
            "removeLiquidityOneToken()'s return value does not match received token amount"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ISwap.sol";

contract SwapDeployer is Ownable {
    event NewSwapPool(
        address indexed deployer,
        address swapAddress,
        IERC20[] pooledTokens
    );

    constructor() public Ownable() {}

    function deploy(
        address swapAddress,
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address lpTokenTargetAddress
    ) external returns (address) {
        address swapClone = Clones.clone(swapAddress);
        ISwap(swapClone).initialize(
            _pooledTokens,
            decimals,
            lpTokenName,
            lpTokenSymbol,
            _a,
            _fee,
            _adminFee,
            _withdrawFee,
            lpTokenTargetAddress
        );
        Ownable(swapClone).transferOwnership(owner());
        emit NewSwapPool(msg.sender, swapClone, _pooledTokens);
        return swapClone;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/ISwap.sol";
import "../interfaces/IMetaSwap.sol";
import "../interfaces/IMetaSwapDeposit.sol";

/**
 * @title MetaSwapDeployer
 * @notice A library to be used to permissionlessly deploy Metapools.
 */

contract MetaSwapDeployer is Ownable {
    event NewMetaSwapPool(
        address indexed deployer,
        address metaSwapAddress,
        address metaSwapDepositAddress
    );

    struct MetaSwapPoolInfo {
        address metaSwapAddress;
        address metaSwapDepositAddress;
    }

    MetaSwapPoolInfo[] public metaSwapPoolInfo;
    address public metaSwapAddress;
    address public metaSwapDepositAddress;

    constructor(address _swapAddress, address _swapDepositAddress)
        public
        Ownable()
    {
        metaSwapAddress = _swapAddress;
        metaSwapDepositAddress = _swapDepositAddress;
    }

    function metaSwapPoolLength() external view returns (uint256) {
        return metaSwapPoolInfo.length;
    }

    function deploy(
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address lpTokenTargetAddress,
        address baseSwap
    ) external returns (address) {
        address metaSwapClone = Clones.clone(metaSwapAddress);
        address metaSwapDepositClone = Clones.clone(metaSwapDepositAddress);
        IMetaSwap(metaSwapClone).initializeMetaSwap(
            _pooledTokens,
            decimals,
            lpTokenName,
            lpTokenSymbol,
            _a,
            _fee,
            _adminFee,
            _withdrawFee,
            lpTokenTargetAddress,
            baseSwap
        );
        (, , , , , , , address lpToken) =
            IMetaSwap(metaSwapClone).swapStorage();

        IMetaSwapDeposit(metaSwapDepositClone).initialize(
            ISwap(baseSwap),
            IMetaSwap(metaSwapClone),
            IERC20(lpToken)
        );
        Ownable(metaSwapClone).transferOwnership(owner());
        metaSwapPoolInfo.push(
            MetaSwapPoolInfo({
                metaSwapAddress: metaSwapClone,
                metaSwapDepositAddress: metaSwapDepositClone
            })
        );
        emit NewMetaSwapPool(msg.sender, metaSwapClone, metaSwapDepositClone);
        return metaSwapClone;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMetaSwap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function isGuarded() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateSwapUnderlying(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidity(address account, uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initializeMetaSwap(
        IERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        uint256 withdrawFee,
        address lpTokenTargetAddress,
        address baseSwap
    ) external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function swapUnderlying(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    // withdraw fee update function
    function updateUserWithdrawFee(address recipient, uint256 transferAmount)
        external;

    function swapStorage()
        external
        view
        returns (
            uint256 initialA,
            uint256 futureA,
            uint256 initialATime,
            uint256 futureATime,
            uint256 swapFee,
            uint256 adminFee,
            uint256 defaultWithdrawFee,
            address lpToken
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ISwap.sol";
import "./IMetaSwap.sol";

interface IMetaSwapDeposit {
    function initialize(
        ISwap baseSwap_,
        IMetaSwap metaSwap_,
        IERC20 metaLPToken_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../LPToken.sol";
import "../interfaces/ISwap.sol";
import "../interfaces/IMetaSwap.sol";

/**
 * @title MetaSwapDeposit
 * @notice This contract flattens the LP token in a MetaSwap pool for easier user access. MetaSwap must be
 * deployed before this contract can be initialized successfully.
 *
 * For example, suppose there exists a base Swap pool consisting of [DAI, USDC, USDT].
 * Then a MetaSwap pool can be created with [sUSD, BaseSwapLPToken] to allow trades between either
 * the LP token or the underlying tokens and sUSD.
 *
 * MetaSwapDeposit flattens the LP token and remaps them to a single array, allowing users
 * to ignore the dependency on BaseSwapLPToken. Using the above example, MetaSwapDeposit can act
 * as a Swap containing [sUSD, DAI, USDC, USDT] tokens.
 */
contract MetaSwapDeposit is Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ISwap public baseSwap;
    IMetaSwap public metaSwap;
    IERC20[] public baseTokens;
    IERC20[] public metaTokens;
    IERC20[] public tokens;
    IERC20 public metaLPToken;

    uint256 constant MAX_UINT256 = 2**256 - 1;

    struct RemoveLiquidityImbalanceInfo {
        ISwap baseSwap;
        IMetaSwap metaSwap;
        IERC20 metaLPToken;
        uint8 baseLPTokenIndex;
        bool withdrawFromBase;
        uint256 leftoverMetaLPTokenAmount;
    }

    /**
     * @notice Sets the address for the base Swap contract, MetaSwap contract, and the
     * MetaSwap LP token contract.
     * @param _baseSwap the address of the base Swap contract
     * @param _metaSwap the address of the MetaSwap contract
     * @param _metaLPToken the address of the MetaSwap LP token contract
     */
    function initialize(
        ISwap _baseSwap,
        IMetaSwap _metaSwap,
        IERC20 _metaLPToken
    ) external initializer {
        __ReentrancyGuard_init();
        // Check and approve base level tokens to be deposited to the base Swap contract
        {
            uint8 i;
            for (; i < 32; i++) {
                try _baseSwap.getToken(i) returns (IERC20 token) {
                    baseTokens.push(token);
                    token.safeApprove(address(_baseSwap), MAX_UINT256);
                    token.safeApprove(address(_metaSwap), MAX_UINT256);
                } catch {
                    break;
                }
            }
            require(i > 1, "baseSwap must have at least 2 tokens");
        }

        // Check and approve meta level tokens to be deposited to the MetaSwap contract
        IERC20 baseLPToken;
        {
            uint8 i;
            for (; i < 32; i++) {
                try _metaSwap.getToken(i) returns (IERC20 token) {
                    baseLPToken = token;
                    metaTokens.push(token);
                    tokens.push(token);
                    token.safeApprove(address(_metaSwap), MAX_UINT256);
                } catch {
                    break;
                }
            }
            require(i > 1, "metaSwap must have at least 2 tokens");
        }

        // Flatten baseTokens and append it to tokens array
        tokens[tokens.length - 1] = baseTokens[0];
        for (uint8 i = 1; i < baseTokens.length; i++) {
            tokens.push(baseTokens[i]);
        }

        // Approve base Swap LP token to be burned by the base Swap contract for withdrawing
        baseLPToken.safeApprove(address(_baseSwap), MAX_UINT256);
        // Approve MetaSwap LP token to be burned by the MetaSwap contract for withdrawing
        _metaLPToken.safeApprove(address(_metaSwap), MAX_UINT256);

        // Initialize storage variables
        baseSwap = _baseSwap;
        metaSwap = _metaSwap;
        metaLPToken = _metaLPToken;
    }

    // Mutative functions

    /**
     * @notice Swap two underlying tokens using the meta pool and the base pool
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external nonReentrant returns (uint256) {
        tokens[tokenIndexFrom].safeTransferFrom(msg.sender, address(this), dx);
        uint256 tokenToAmount =
            metaSwap.swapUnderlying(
                tokenIndexFrom,
                tokenIndexTo,
                dx,
                minDy,
                deadline
            );
        tokens[tokenIndexTo].safeTransfer(msg.sender, tokenToAmount);
        return tokenToAmount;
    }

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external nonReentrant returns (uint256) {
        // Read to memory to save on gas
        IERC20[] memory memBaseTokens = baseTokens;
        IERC20[] memory memMetaTokens = metaTokens;
        uint256 baseLPTokenIndex = memMetaTokens.length - 1;

        require(amounts.length == memBaseTokens.length + baseLPTokenIndex);

        uint256 baseLPTokenAmount;
        {
            // Transfer base tokens from the caller and deposit to the base Swap pool
            uint256[] memory baseAmounts = new uint256[](memBaseTokens.length);
            bool shouldDepositBaseTokens;
            for (uint8 i = 0; i < memBaseTokens.length; i++) {
                IERC20 token = memBaseTokens[i];
                uint256 depositAmount = amounts[baseLPTokenIndex + i];
                if (depositAmount > 0) {
                    token.safeTransferFrom(
                        msg.sender,
                        address(this),
                        depositAmount
                    );
                    baseAmounts[i] = token.balanceOf(address(this)); // account for any fees on transfer
                    // if there are any base Swap level tokens, flag it for deposits
                    shouldDepositBaseTokens = true;
                }
            }
            if (shouldDepositBaseTokens) {
                // Deposit any base Swap level tokens and receive baseLPToken
                baseLPTokenAmount = baseSwap.addLiquidity(
                    baseAmounts,
                    0,
                    deadline
                );
            }
        }

        uint256 metaLPTokenAmount;
        {
            // Transfer remaining meta level tokens from the caller
            uint256[] memory metaAmounts = new uint256[](metaTokens.length);
            for (uint8 i = 0; i < baseLPTokenIndex; i++) {
                IERC20 token = memMetaTokens[i];
                uint256 depositAmount = amounts[i];
                if (depositAmount > 0) {
                    token.safeTransferFrom(
                        msg.sender,
                        address(this),
                        depositAmount
                    );
                    metaAmounts[i] = token.balanceOf(address(this)); // account for any fees on transfer
                }
            }
            // Update the baseLPToken amount that will be deposited
            metaAmounts[baseLPTokenIndex] = baseLPTokenAmount;

            // Deposit the meta level tokens and the baseLPToken
            metaLPTokenAmount = metaSwap.addLiquidity(
                metaAmounts,
                minToMint,
                deadline
            );
        }

        // Transfer the meta lp token to the caller
        metaLPToken.safeTransfer(msg.sender, metaLPTokenAmount);

        return metaLPTokenAmount;
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amounts of tokens user received
     */
    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external nonReentrant returns (uint256[] memory) {
        IERC20[] memory memBaseTokens = baseTokens;
        IERC20[] memory memMetaTokens = metaTokens;
        uint256[] memory totalRemovedAmounts;

        {
            uint256 numOfAllTokens =
                memBaseTokens.length + memMetaTokens.length - 1;
            require(minAmounts.length == numOfAllTokens, "out of range");
            totalRemovedAmounts = new uint256[](numOfAllTokens);
        }

        // Transfer meta lp token from the caller to this
        metaLPToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 baseLPTokenAmount;
        {
            // Remove liquidity from the MetaSwap pool
            uint256[] memory removedAmounts;
            uint256 baseLPTokenIndex = memMetaTokens.length - 1;
            {
                uint256[] memory metaMinAmounts =
                    new uint256[](memMetaTokens.length);
                for (uint8 i = 0; i < baseLPTokenIndex; i++) {
                    metaMinAmounts[i] = minAmounts[i];
                }
                removedAmounts = metaSwap.removeLiquidity(
                    amount,
                    metaMinAmounts,
                    deadline
                );
            }

            // Send the meta level tokens to the caller
            for (uint8 i = 0; i < baseLPTokenIndex; i++) {
                totalRemovedAmounts[i] = removedAmounts[i];
                memMetaTokens[i].safeTransfer(msg.sender, removedAmounts[i]);
            }
            baseLPTokenAmount = removedAmounts[baseLPTokenIndex];

            // Remove liquidity from the base Swap pool
            {
                uint256[] memory baseMinAmounts =
                    new uint256[](memBaseTokens.length);
                for (uint8 i = 0; i < baseLPTokenIndex; i++) {
                    baseMinAmounts[i] = minAmounts[baseLPTokenIndex + i];
                }
                removedAmounts = baseSwap.removeLiquidity(
                    baseLPTokenAmount,
                    baseMinAmounts,
                    deadline
                );
            }

            // Send the base level tokens to the caller
            for (uint8 i = 0; i < memBaseTokens.length; i++) {
                totalRemovedAmounts[baseLPTokenIndex + i] = removedAmounts[i];
                memBaseTokens[i].safeTransfer(msg.sender, removedAmounts[i]);
            }
        }

        return totalRemovedAmounts;
    }

    /**
     * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param tokenAmount the amount of the token you want to receive
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param deadline latest timestamp to accept this transaction
     * @return amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external nonReentrant returns (uint256) {
        uint8 baseLPTokenIndex = uint8(metaTokens.length - 1);
        uint8 baseTokensLength = uint8(baseTokens.length);

        // Transfer metaLPToken from the caller
        metaLPToken.safeTransferFrom(msg.sender, address(this), tokenAmount);

        IERC20 token;
        if (tokenIndex < baseLPTokenIndex) {
            // When the desired token is meta level token, we can just call `removeLiquidityOneToken` directly
            metaSwap.removeLiquidityOneToken(
                tokenAmount,
                tokenIndex,
                minAmount,
                deadline
            );
            token = metaTokens[tokenIndex];
        } else if (tokenIndex < baseLPTokenIndex + baseTokensLength) {
            // When the desired token is a base level token, we need to first withdraw via baseLPToken, then withdraw
            // the desired token from the base Swap contract.
            uint256 removedBaseLPTokenAmount =
                metaSwap.removeLiquidityOneToken(
                    tokenAmount,
                    baseLPTokenIndex,
                    0,
                    deadline
                );

            baseSwap.removeLiquidityOneToken(
                removedBaseLPTokenAmount,
                tokenIndex - baseLPTokenIndex,
                minAmount,
                deadline
            );
            token = baseTokens[tokenIndex - baseLPTokenIndex];
        } else {
            revert("out of range");
        }

        uint256 amountWithdrawn = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amountWithdrawn);
        return amountWithdrawn;
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external nonReentrant returns (uint256) {
        IERC20[] memory memBaseTokens = baseTokens;
        IERC20[] memory memMetaTokens = metaTokens;
        uint256[] memory metaAmounts = new uint256[](memMetaTokens.length);
        uint256[] memory baseAmounts = new uint256[](memBaseTokens.length);

        require(
            amounts.length == memBaseTokens.length + memMetaTokens.length - 1,
            "out of range"
        );

        RemoveLiquidityImbalanceInfo memory v =
            RemoveLiquidityImbalanceInfo(
                baseSwap,
                metaSwap,
                metaLPToken,
                uint8(metaAmounts.length - 1),
                false,
                0
            );

        for (uint8 i = 0; i < v.baseLPTokenIndex; i++) {
            metaAmounts[i] = amounts[i];
        }

        for (uint8 i = 0; i < baseAmounts.length; i++) {
            baseAmounts[i] = amounts[v.baseLPTokenIndex + i];
            if (baseAmounts[i] > 0) {
                v.withdrawFromBase = true;
            }
        }

        // Calculate how much base LP token we need to get the desired amount of underlying tokens
        if (v.withdrawFromBase) {
            metaAmounts[v.baseLPTokenIndex] = v
                .baseSwap
                .calculateTokenAmount(address(this), baseAmounts, false)
                .mul(10005)
                .div(10000);
        }

        // Transfer MetaSwap LP token from the caller to this contract
        v.metaLPToken.safeTransferFrom(
            msg.sender,
            address(this),
            maxBurnAmount
        );

        // Withdraw the paired meta level tokens and the base LP token from the MetaSwap pool
        uint256 burnedMetaLPTokenAmount =
            v.metaSwap.removeLiquidityImbalance(
                metaAmounts,
                maxBurnAmount,
                deadline
            );
        v.leftoverMetaLPTokenAmount = maxBurnAmount.sub(
            burnedMetaLPTokenAmount
        );

        // If underlying tokens are desired, withdraw them from the base Swap pool
        if (v.withdrawFromBase) {
            v.baseSwap.removeLiquidityImbalance(
                baseAmounts,
                metaAmounts[v.baseLPTokenIndex],
                deadline
            );

            // Base Swap may require LESS base LP token than the amount we have
            // In that case, deposit it to the MetaSwap pool.
            uint256[] memory leftovers = new uint256[](metaAmounts.length);
            IERC20 baseLPToken = memMetaTokens[v.baseLPTokenIndex];
            uint256 leftoverBaseLPTokenAmount =
                baseLPToken.balanceOf(address(this));
            if (leftoverBaseLPTokenAmount > 0) {
                leftovers[v.baseLPTokenIndex] = leftoverBaseLPTokenAmount;
                v.leftoverMetaLPTokenAmount = v.leftoverMetaLPTokenAmount.add(
                    v.metaSwap.addLiquidity(leftovers, 0, deadline)
                );
            }
        }

        // Transfer all withdrawn tokens to the caller
        for (uint8 i = 0; i < amounts.length; i++) {
            IERC20 token;
            if (i < v.baseLPTokenIndex) {
                token = memMetaTokens[i];
            } else {
                token = memBaseTokens[i - v.baseLPTokenIndex];
            }
            if (amounts[i] > 0) {
                token.safeTransfer(msg.sender, amounts[i]);
            }
        }

        // If there were any extra meta lp token, transfer them back to the caller as well
        if (v.leftoverMetaLPTokenAmount > 0) {
            v.metaLPToken.safeTransfer(msg.sender, v.leftoverMetaLPTokenAmount);
        }

        return maxBurnAmount - v.leftoverMetaLPTokenAmount;
    }

    // VIEW FUNCTIONS

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running. When withdrawing from the base pool in imbalanced
     * fashion, the recommended slippage setting is 0.2% or higher.
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param account address that is depositing or withdrawing tokens
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return token amount the user will receive
     */
    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256) {
        account = address(this);
        uint256[] memory metaAmounts = new uint256[](metaTokens.length);
        uint256[] memory baseAmounts = new uint256[](baseTokens.length);
        uint256 baseLPTokenIndex = metaAmounts.length - 1;

        for (uint8 i = 0; i < baseLPTokenIndex; i++) {
            metaAmounts[i] = amounts[i];
        }

        for (uint8 i = 0; i < baseAmounts.length; i++) {
            baseAmounts[i] = amounts[baseLPTokenIndex + i];
        }

        uint256 baseLPTokenAmount =
            baseSwap.calculateTokenAmount(account, baseAmounts, deposit);
        metaAmounts[baseLPTokenIndex] = baseLPTokenAmount;

        return metaSwap.calculateTokenAmount(account, metaAmounts, deposit);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param account the address that is withdrawing tokens
     * @param amount the amount of LP tokens that would be burned on withdrawal
     * @return array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(address account, uint256 amount)
        external
        view
        returns (uint256[] memory)
    {
        account = address(this); // overwrite account
        uint256[] memory metaAmounts =
            metaSwap.calculateRemoveLiquidity(account, amount);
        uint8 baseLPTokenIndex = uint8(metaAmounts.length - 1);
        uint256[] memory baseAmounts =
            baseSwap.calculateRemoveLiquidity(
                account,
                metaAmounts[baseLPTokenIndex]
            );

        uint256[] memory totalAmounts =
            new uint256[](baseLPTokenIndex + baseAmounts.length);
        for (uint8 i = 0; i < baseLPTokenIndex; i++) {
            totalAmounts[i] = metaAmounts[i];
        }
        for (uint8 i = 0; i < baseAmounts.length; i++) {
            totalAmounts[baseLPTokenIndex + i] = baseAmounts[i];
        }

        return totalAmounts;
    }

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param account the address that is withdrawing tokens
     * @param tokenAmount the amount of LP token to burn
     * @param tokenIndex index of which token will be withdrawn
     * @return availableTokenAmount calculated amount of underlying token
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256) {
        account = address(this); // overwrite account
        uint8 baseLPTokenIndex = uint8(metaTokens.length - 1);

        if (tokenIndex < baseLPTokenIndex) {
            return
                metaSwap.calculateRemoveLiquidityOneToken(
                    account,
                    tokenAmount,
                    tokenIndex
                );
        } else {
            uint256 baseLPTokenAmount =
                metaSwap.calculateRemoveLiquidityOneToken(
                    account,
                    tokenAmount,
                    baseLPTokenIndex
                );
            return
                baseSwap.calculateRemoveLiquidityOneToken(
                    account,
                    baseLPTokenAmount,
                    tokenIndex - baseLPTokenIndex
                );
        }
    }

    /**
     * @notice Returns the address of the pooled token at given index. Reverts if tokenIndex is out of range.
     * This is a flattened representation of the pooled tokens.
     * @param index the index of the token
     * @return address of the token at given index
     */
    function getToken(uint256 index) external view returns (IERC20) {
        require(index < tokens.length, "index out of range");
        return tokens[index];
    }

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256) {
        return
            metaSwap.calculateSwapUnderlying(tokenIndexFrom, tokenIndexTo, dx);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../LPToken.sol";
import "../interfaces/ISwap.sol";
import "../MathUtils.sol";
import "../SwapUtils.sol";

/**
 * @title MetaSwapUtils library
 * @notice A library to be used within MetaSwap.sol. Contains functions responsible for custody and AMM functionalities.
 *
 * MetaSwap is a modified version of Swap that allows Swap's LP token to be utilized in pooling with other tokens.
 * As an example, if there is a Swap pool consisting of [DAI, USDC, USDT]. Then a MetaSwap pool can be created
 * with [sUSD, BaseSwapLPToken] to allow trades between either the LP token or the underlying tokens and sUSD.
 *
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library MetaSwapUtils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;
    using AmplificationUtils for SwapUtils.Swap;

    /*** EVENTS ***/

    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event TokenSwapUnderlying(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);

    struct MetaSwap {
        // Meta-Swap related parameters
        ISwap baseSwap;
        uint256 baseVirtualPrice;
        uint256 baseCacheLastUpdated;
        IERC20[] baseTokens;
    }

    // Struct storing variables used in calculations in the
    // calculateWithdrawOneTokenDY function to avoid stack too deep errors
    struct CalculateWithdrawOneTokenDYInfo {
        uint256 d0;
        uint256 d1;
        uint256 newY;
        uint256 feePerToken;
        uint256 preciseA;
        uint256 xpi;
    }

    // Struct storing variables used in calculation in removeLiquidityImbalance function
    // to avoid stack too deep error
    struct ManageLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        LPToken lpToken;
        uint256 totalSupply;
        uint256 preciseA;
        uint256 baseVirtualPrice;
        uint256[] tokenPrecisionMultipliers;
        uint256[] newBalances;
    }

    struct SwapUnderlyingInfo {
        uint256 x;
        uint256 dx;
        uint256 dy;
        uint256[] tokenPrecisionMultipliers;
        uint256[] oldBalances;
        IERC20[] baseTokens;
        IERC20 tokenFrom;
        uint8 metaIndexFrom;
        IERC20 tokenTo;
        uint8 metaIndexTo;
        uint256 baseVirtualPrice;
    }

    struct CalculateSwapUnderlyingInfo {
        uint256 baseVirtualPrice;
        ISwap baseSwap;
        uint8 baseLPTokenIndex;
        uint8 baseTokensLength;
        uint8 metaIndexTo;
        uint256 x;
        uint256 dy;
    }

    // the denominator used to calculate admin and LP fees. For example, an
    // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
    uint256 private constant FEE_DENOMINATOR = 10**10;

    // Cache expire time for the stored value of base Swap's virtual price
    uint256 public constant BASE_CACHE_EXPIRE_TIME = 10 minutes;
    uint256 public constant BASE_VIRTUAL_PRICE_PRECISION = 10**18;

    /*** VIEW & PURE FUNCTIONS ***/

    /**
     * @notice Return the stored value of base Swap's virtual price. If
     * value was updated past BASE_CACHE_EXPIRE_TIME, then read it directly
     * from the base Swap contract.
     * @param metaSwapStorage MetaSwap struct to read from
     * @return base Swap's virtual price
     */
    function _getBaseVirtualPrice(MetaSwap storage metaSwapStorage)
        internal
        view
        returns (uint256)
    {
        if (
            block.timestamp >
            metaSwapStorage.baseCacheLastUpdated + BASE_CACHE_EXPIRE_TIME
        ) {
            return metaSwapStorage.baseSwap.getVirtualPrice();
        }
        return metaSwapStorage.baseVirtualPrice;
    }

    /**
     * @notice Calculate how much the user would receive when withdrawing via single token
     * @param self Swap struct to read from
     * @param metaSwapStorage MetaSwap struct to read from
     * @param account the address that is withdrawing
     * @param tokenAmount the amount to withdraw in the pool's precision
     * @param tokenIndex which token will be withdrawn
     * @return dy the amount of token user will receive
     */
    function calculateWithdrawOneToken(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 dy) {
        (dy, ) = _calculateWithdrawOneToken(
            self,
            account,
            tokenAmount,
            tokenIndex,
            _getBaseVirtualPrice(metaSwapStorage),
            self.lpToken.totalSupply()
        );
    }

    function _calculateWithdrawOneToken(
        SwapUtils.Swap storage self,
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 baseVirtualPrice,
        uint256 totalSupply
    ) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 dySwapFee;

        {
            uint256 currentY;
            uint256 newY;

            // Calculate how much to withdraw
            (dy, newY, currentY) = _calculateWithdrawOneTokenDY(
                self,
                tokenIndex,
                tokenAmount,
                baseVirtualPrice,
                totalSupply
            );

            // Calculate the associated swap fee
            dySwapFee = currentY
                .sub(newY)
                .div(self.tokenPrecisionMultipliers[tokenIndex])
                .sub(dy);
        }

        // Adjust by withdraw fee
        dy = dy
            .mul(
            FEE_DENOMINATOR.sub(
                SwapUtils._calculateCurrentWithdrawFee(self, account)
            )
        )
            .div(FEE_DENOMINATOR);

        return (dy, dySwapFee);
    }

    /**
     * @notice Calculate the dy of withdrawing in one token
     * @param self Swap struct to read from
     * @param tokenIndex which token will be withdrawn
     * @param tokenAmount the amount to withdraw in the pools precision
     * @param baseVirtualPrice the virtual price of the base swap's LP token
     * @return the dy excluding swap fee, the new y after withdrawing one token, and current y
     */
    function _calculateWithdrawOneTokenDY(
        SwapUtils.Swap storage self,
        uint8 tokenIndex,
        uint256 tokenAmount,
        uint256 baseVirtualPrice,
        uint256 totalSupply
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Get the current D, then solve the stableswap invariant
        // y_i for D - tokenAmount
        uint256[] memory xp = _xp(self, baseVirtualPrice);
        require(tokenIndex < xp.length, "Token index out of range");

        CalculateWithdrawOneTokenDYInfo memory v =
            CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, self._getAPrecise(), 0);
        v.d0 = SwapUtils.getD(xp, v.preciseA);
        v.d1 = v.d0.sub(tokenAmount.mul(v.d0).div(totalSupply));

        require(tokenAmount <= xp[tokenIndex], "Withdraw exceeds available");

        v.newY = SwapUtils.getYD(v.preciseA, tokenIndex, xp, v.d1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        v.feePerToken = SwapUtils._feePerToken(self.swapFee, xp.length);
        for (uint256 i = 0; i < xp.length; i++) {
            v.xpi = xp[i];
            // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
            // else dxExpected = xp[i] - (xp[i] * d1 / d0)
            // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
            xpReduced[i] = v.xpi.sub(
                (
                    (i == tokenIndex)
                        ? v.xpi.mul(v.d1).div(v.d0).sub(v.newY)
                        : v.xpi.sub(v.xpi.mul(v.d1).div(v.d0))
                )
                    .mul(v.feePerToken)
                    .div(FEE_DENOMINATOR)
            );
        }

        uint256 dy =
            xpReduced[tokenIndex].sub(
                SwapUtils.getYD(v.preciseA, tokenIndex, xpReduced, v.d1)
            );

        if (tokenIndex == xp.length.sub(1)) {
            dy = dy.mul(BASE_VIRTUAL_PRICE_PRECISION).div(baseVirtualPrice);
        }
        dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

        return (dy, v.newY, xp[tokenIndex]);
    }

    /**
     * @notice Given a set of balances and precision multipliers, return the
     * precision-adjusted balances. The last element will also get scaled up by
     * the given baseVirtualPrice.
     *
     * @param balances an array of token balances, in their native precisions.
     * These should generally correspond with pooled tokens.
     *
     * @param precisionMultipliers an array of multipliers, corresponding to
     * the amounts in the balances array. When multiplied together they
     * should yield amounts at the pool's precision.
     *
     * @param baseVirtualPrice the base virtual price to scale the balance of the
     * base Swap's LP token.
     *
     * @return an array of amounts "scaled" to the pool's precision
     */
    function _xp(
        uint256[] memory balances,
        uint256[] memory precisionMultipliers,
        uint256 baseVirtualPrice
    ) internal pure returns (uint256[] memory) {
        uint256[] memory xp = SwapUtils._xp(balances, precisionMultipliers);
        uint256 baseLPTokenIndex = balances.length.sub(1);
        xp[baseLPTokenIndex] = xp[baseLPTokenIndex].mul(baseVirtualPrice).div(
            BASE_VIRTUAL_PRICE_PRECISION
        );
        return xp;
    }

    /**
     * @notice Return the precision-adjusted balances of all tokens in the pool
     * @param self Swap struct to read from
     * @return the pool balances "scaled" to the pool's precision, allowing
     * them to be more easily compared.
     */
    function _xp(SwapUtils.Swap storage self, uint256 baseVirtualPrice)
        internal
        view
        returns (uint256[] memory)
    {
        return
            _xp(
                self.balances,
                self.tokenPrecisionMultipliers,
                baseVirtualPrice
            );
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @param self Swap struct to read from
     * @param metaSwapStorage MetaSwap struct to read from
     * @return the virtual price, scaled to precision of BASE_VIRTUAL_PRICE_PRECISION
     */
    function getVirtualPrice(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage
    ) external view returns (uint256) {
        uint256 d =
            SwapUtils.getD(
                _xp(
                    self.balances,
                    self.tokenPrecisionMultipliers,
                    _getBaseVirtualPrice(metaSwapStorage)
                ),
                self._getAPrecise()
            );
        uint256 supply = self.lpToken.totalSupply();
        if (supply != 0) {
            return d.mul(BASE_VIRTUAL_PRICE_PRECISION).div(supply);
        }
        return 0;
    }

    /**
     * @notice Externally calculates a swap between two tokens. The SwapUtils.Swap storage and
     * MetaSwap storage should be from the same MetaSwap contract.
     * @param self Swap struct to read from
     * @param metaSwapStorage MetaSwap struct from the same contract
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return dy the number of tokens the user will get
     */
    function calculateSwap(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(
            self,
            tokenIndexFrom,
            tokenIndexTo,
            dx,
            _getBaseVirtualPrice(metaSwapStorage)
        );
    }

    /**
     * @notice Internally calculates a swap between two tokens.
     *
     * @dev The caller is expected to transfer the actual amounts (dx and dy)
     * using the token contracts.
     *
     * @param self Swap struct to read from
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param baseVirtualPrice the virtual price of the base LP token
     * @return dy the number of tokens the user will get and dyFee the associated fee
     */
    function _calculateSwap(
        SwapUtils.Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 baseVirtualPrice
    ) internal view returns (uint256 dy, uint256 dyFee) {
        uint256[] memory xp = _xp(self, baseVirtualPrice);
        require(
            tokenIndexFrom < xp.length && tokenIndexTo < xp.length,
            "Token index out of range"
        );
        uint256 x =
            dx.mul(self.tokenPrecisionMultipliers[tokenIndexFrom]).add(
                xp[tokenIndexFrom]
            );
        uint256 y =
            SwapUtils.getY(
                self._getAPrecise(),
                tokenIndexFrom,
                tokenIndexTo,
                x,
                xp
            );
        dy = xp[tokenIndexTo].sub(y).sub(1);
        dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        dy = dy.sub(dyFee).div(self.tokenPrecisionMultipliers[tokenIndexTo]);
    }

    /**
     * @notice Calculates the expected return amount from swapping between
     * the pooled tokens and the underlying tokens of the base Swap pool.
     *
     * @param self Swap struct to read from
     * @param metaSwapStorage MetaSwap struct from the same contract
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return dy the number of tokens the user will get
     */
    function calculateSwapUnderlying(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256) {
        CalculateSwapUnderlyingInfo memory v =
            CalculateSwapUnderlyingInfo(
                _getBaseVirtualPrice(metaSwapStorage),
                metaSwapStorage.baseSwap,
                0,
                uint8(metaSwapStorage.baseTokens.length),
                0,
                0,
                0
            );

        uint256[] memory xp = _xp(self, v.baseVirtualPrice);
        v.baseLPTokenIndex = uint8(xp.length.sub(1));
        {
            uint8 maxRange = v.baseLPTokenIndex + v.baseTokensLength;
            require(
                tokenIndexFrom < maxRange && tokenIndexTo < maxRange,
                "Token index out of range"
            );
        }

        if (tokenIndexFrom < v.baseLPTokenIndex) {
            // tokenFrom is from this pool
            v.x = xp[tokenIndexFrom].add(
                dx.mul(self.tokenPrecisionMultipliers[tokenIndexFrom])
            );
        } else {
            // tokenFrom is from the base pool
            tokenIndexFrom = tokenIndexFrom - v.baseLPTokenIndex;
            if (tokenIndexTo < v.baseLPTokenIndex) {
                uint256[] memory baseInputs = new uint256[](v.baseTokensLength);
                baseInputs[tokenIndexFrom] = dx;
                v.x = v
                    .baseSwap
                    .calculateTokenAmount(address(this), baseInputs, true)
                    .mul(v.baseVirtualPrice)
                    .div(BASE_VIRTUAL_PRICE_PRECISION)
                    .add(xp[v.baseLPTokenIndex]);
            } else {
                // both from and to are from the base pool
                return
                    v.baseSwap.calculateSwap(
                        tokenIndexFrom,
                        tokenIndexTo - v.baseLPTokenIndex,
                        dx
                    );
            }
            tokenIndexFrom = v.baseLPTokenIndex;
        }

        v.metaIndexTo = v.baseLPTokenIndex;
        if (tokenIndexTo < v.baseLPTokenIndex) {
            v.metaIndexTo = tokenIndexTo;
        }

        {
            uint256 y =
                SwapUtils.getY(
                    self._getAPrecise(),
                    tokenIndexFrom,
                    v.metaIndexTo,
                    v.x,
                    xp
                );
            v.dy = xp[v.metaIndexTo].sub(y).sub(1);
            uint256 dyFee = v.dy.mul(self.swapFee).div(FEE_DENOMINATOR);
            v.dy = v.dy.sub(dyFee);
        }

        if (tokenIndexTo < v.baseLPTokenIndex) {
            // tokenTo is from this pool
            v.dy = v.dy.div(self.tokenPrecisionMultipliers[v.metaIndexTo]);
        } else {
            // tokenTo is from the base pool
            v.dy = v.baseSwap.calculateRemoveLiquidityOneToken(
                address(this),
                v.dy.mul(BASE_VIRTUAL_PRICE_PRECISION).div(v.baseVirtualPrice),
                tokenIndexTo - v.baseLPTokenIndex
            );
        }

        return v.dy;
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param self Swap struct to read from
     * @param metaSwapStorage MetaSwap struct to read from
     * @param account address of the account depositing or withdrawing tokens
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return if deposit was true, total amount of lp token that will be minted and if
     * deposit was false, total amount of lp token that will be burned
     */
    function calculateTokenAmount(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256) {
        uint256 a = self._getAPrecise();
        uint256 d0;
        uint256 d1;
        {
            uint256 baseVirtualPrice = _getBaseVirtualPrice(metaSwapStorage);
            uint256[] memory balances1 = self.balances;
            uint256[] memory tokenPrecisionMultipliers =
                self.tokenPrecisionMultipliers;
            uint256 numTokens = balances1.length;
            d0 = SwapUtils.getD(
                _xp(balances1, tokenPrecisionMultipliers, baseVirtualPrice),
                a
            );
            for (uint256 i = 0; i < numTokens; i++) {
                if (deposit) {
                    balances1[i] = balances1[i].add(amounts[i]);
                } else {
                    balances1[i] = balances1[i].sub(
                        amounts[i],
                        "Cannot withdraw more than available"
                    );
                }
            }
            d1 = SwapUtils.getD(
                _xp(balances1, tokenPrecisionMultipliers, baseVirtualPrice),
                a
            );
        }
        uint256 totalSupply = self.lpToken.totalSupply();

        if (deposit) {
            return d1.sub(d0).mul(totalSupply).div(d0);
        } else {
            return
                d0.sub(d1).mul(totalSupply).div(d0).mul(FEE_DENOMINATOR).div(
                    FEE_DENOMINATOR.sub(
                        SwapUtils._calculateCurrentWithdrawFee(self, account)
                    )
                );
        }
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice swap two tokens in the pool
     * @param self Swap struct to read from and write to
     * @param metaSwapStorage MetaSwap struct to read from and write to
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell
     * @param minDy the min amount the user would like to receive, or revert.
     * @return amount of token user received on swap
     */
    function swap(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256) {
        {
            uint256 pooledTokensLength = self.pooledTokens.length;
            require(
                tokenIndexFrom < pooledTokensLength &&
                    tokenIndexTo < pooledTokensLength,
                "Token index is out of range"
            );
        }

        uint256 transferredDx;
        {
            IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
            require(
                dx <= tokenFrom.balanceOf(msg.sender),
                "Cannot swap more than you own"
            );

            {
                // Transfer tokens first to see if a fee was charged on transfer
                uint256 beforeBalance = tokenFrom.balanceOf(address(this));
                tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

                // Use the actual transferred amount for AMM math
                transferredDx = tokenFrom.balanceOf(address(this)).sub(
                    beforeBalance
                );
            }
        }

        (uint256 dy, uint256 dyFee) =
            _calculateSwap(
                self,
                tokenIndexFrom,
                tokenIndexTo,
                transferredDx,
                _updateBaseVirtualPrice(metaSwapStorage)
            );
        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee =
            dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
                self.tokenPrecisionMultipliers[tokenIndexTo]
            );

        self.balances[tokenIndexFrom] = self.balances[tokenIndexFrom].add(
            transferredDx
        );
        self.balances[tokenIndexTo] = self.balances[tokenIndexTo].sub(dy).sub(
            dyAdminFee
        );

        self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(
            msg.sender,
            transferredDx,
            dy,
            tokenIndexFrom,
            tokenIndexTo
        );

        return dy;
    }

    /**
     * @notice Swaps with the underlying tokens of the base Swap pool. For this function,
     * the token indices are flattened out so that underlying tokens are represented
     * in the indices.
     * @dev Since this calls multiple external functions during the execution,
     * it is recommended to protect any function that depends on this with reentrancy guards.
     * @param self Swap struct to read from and write to
     * @param metaSwapStorage MetaSwap struct to read from and write to
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell
     * @param minDy the min amount the user would like to receive, or revert.
     * @return amount of token user received on swap
     */
    function swapUnderlying(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256) {
        SwapUnderlyingInfo memory v =
            SwapUnderlyingInfo(
                0,
                0,
                0,
                self.tokenPrecisionMultipliers,
                self.balances,
                metaSwapStorage.baseTokens,
                IERC20(address(0)),
                0,
                IERC20(address(0)),
                0,
                _updateBaseVirtualPrice(metaSwapStorage)
            );

        uint8 baseLPTokenIndex = uint8(v.oldBalances.length.sub(1));

        {
            uint8 maxRange = uint8(baseLPTokenIndex + v.baseTokens.length);
            require(
                tokenIndexFrom < maxRange && tokenIndexTo < maxRange,
                "Token index out of range"
            );
        }

        ISwap baseSwap = metaSwapStorage.baseSwap;

        // Find the address of the token swapping from and the index in MetaSwap's token list
        if (tokenIndexFrom < baseLPTokenIndex) {
            v.tokenFrom = self.pooledTokens[tokenIndexFrom];
            v.metaIndexFrom = tokenIndexFrom;
        } else {
            v.tokenFrom = v.baseTokens[tokenIndexFrom - baseLPTokenIndex];
            v.metaIndexFrom = baseLPTokenIndex;
        }

        // Find the address of the token swapping to and the index in MetaSwap's token list
        if (tokenIndexTo < baseLPTokenIndex) {
            v.tokenTo = self.pooledTokens[tokenIndexTo];
            v.metaIndexTo = tokenIndexTo;
        } else {
            v.tokenTo = v.baseTokens[tokenIndexTo - baseLPTokenIndex];
            v.metaIndexTo = baseLPTokenIndex;
        }

        // Check for possible fee on transfer
        v.dx = v.tokenFrom.balanceOf(address(this));
        v.tokenFrom.safeTransferFrom(msg.sender, address(this), dx);
        v.dx = v.tokenFrom.balanceOf(address(this)).sub(v.dx); // update dx in case of fee on transfer

        if (
            tokenIndexFrom < baseLPTokenIndex || tokenIndexTo < baseLPTokenIndex
        ) {
            // Either one of the tokens belongs to the MetaSwap tokens list
            uint256[] memory xp =
                _xp(
                    v.oldBalances,
                    v.tokenPrecisionMultipliers,
                    v.baseVirtualPrice
                );

            if (tokenIndexFrom < baseLPTokenIndex) {
                // Swapping from a MetaSwap token
                v.x = xp[tokenIndexFrom].add(
                    dx.mul(v.tokenPrecisionMultipliers[tokenIndexFrom])
                );
            } else {
                // Swapping from a base Swap token
                // This case requires adding the underlying token to the base Swap, then
                // using the base LP token to swap to the desired token
                uint256[] memory baseAmounts =
                    new uint256[](v.baseTokens.length);
                baseAmounts[tokenIndexFrom - baseLPTokenIndex] = v.dx;

                // Add liquidity to the underlying Swap contract and receive base LP token
                v.dx = baseSwap.addLiquidity(baseAmounts, 0, block.timestamp);

                // Calculate the value of total amount of baseLPToken we end up with
                v.x = v
                    .dx
                    .mul(v.baseVirtualPrice)
                    .div(BASE_VIRTUAL_PRICE_PRECISION)
                    .add(xp[baseLPTokenIndex]);
            }

            // Calculate how much to withdraw in MetaSwap level and the the associated swap fee
            uint256 dyFee;
            {
                uint256 y =
                    SwapUtils.getY(
                        self._getAPrecise(),
                        v.metaIndexFrom,
                        v.metaIndexTo,
                        v.x,
                        xp
                    );
                v.dy = xp[v.metaIndexTo].sub(y).sub(1);
                dyFee = v.dy.mul(self.swapFee).div(FEE_DENOMINATOR);
                v.dy = v.dy.sub(dyFee).div(
                    v.tokenPrecisionMultipliers[v.metaIndexTo]
                );
            }

            if (tokenIndexTo >= baseLPTokenIndex) {
                // When swapping to a base Swap token, scale down dy by its virtual price
                v.dy = v.dy.mul(BASE_VIRTUAL_PRICE_PRECISION).div(
                    v.baseVirtualPrice
                );
            }

            // Update the balances array according to the calculated input and output amount
            {
                uint256 dyAdminFee =
                    dyFee.mul(self.adminFee).div(FEE_DENOMINATOR);
                dyAdminFee = dyAdminFee.div(
                    v.tokenPrecisionMultipliers[v.metaIndexTo]
                );
                self.balances[v.metaIndexFrom] = v.oldBalances[v.metaIndexFrom]
                    .add(v.dx);
                self.balances[v.metaIndexTo] = v.oldBalances[v.metaIndexTo]
                    .sub(v.dy)
                    .sub(dyAdminFee);
            }

            if (tokenIndexTo >= baseLPTokenIndex) {
                // When swapping to a token that belongs to the base Swap, burn the LP token
                // and withdraw the desired token from the base pool
                uint256 oldBalance = v.tokenTo.balanceOf(address(this));
                baseSwap.removeLiquidityOneToken(
                    v.dy,
                    tokenIndexTo - baseLPTokenIndex,
                    0,
                    block.timestamp
                );
                v.dy = v.tokenTo.balanceOf(address(this)) - oldBalance;
            }

            // Check the amount of token to send meets minDy
            require(v.dy >= minDy, "Swap didn't result in min tokens");
        } else {
            // Both tokens are from the base Swap pool
            // Do a swap through the base Swap
            v.dy = v.tokenTo.balanceOf(address(this));
            baseSwap.swap(
                tokenIndexFrom - baseLPTokenIndex,
                tokenIndexTo - baseLPTokenIndex,
                v.dx,
                minDy,
                block.timestamp
            );
            v.dy = v.tokenTo.balanceOf(address(this)).sub(v.dy);
        }

        // Send the desired token to the caller
        v.tokenTo.safeTransfer(msg.sender, v.dy);

        emit TokenSwapUnderlying(
            msg.sender,
            dx,
            v.dy,
            tokenIndexFrom,
            tokenIndexTo
        );

        return v.dy;
    }

    /**
     * @notice Add liquidity to the pool
     * @param self Swap struct to read from and write to
     * @param metaSwapStorage MetaSwap struct to read from and write to
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
     * @return amount of LP token user received
     */
    function addLiquidity(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint256[] memory amounts,
        uint256 minToMint
    ) external returns (uint256) {
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(
            amounts.length == pooledTokens.length,
            "Amounts must match pooled tokens"
        );

        uint256[] memory fees = new uint256[](pooledTokens.length);

        // current state
        ManageLiquidityInfo memory v =
            ManageLiquidityInfo(
                0,
                0,
                0,
                self.lpToken,
                0,
                self._getAPrecise(),
                _updateBaseVirtualPrice(metaSwapStorage),
                self.tokenPrecisionMultipliers,
                self.balances
            );
        v.totalSupply = v.lpToken.totalSupply();

        if (v.totalSupply != 0) {
            v.d0 = SwapUtils.getD(
                _xp(
                    v.newBalances,
                    v.tokenPrecisionMultipliers,
                    v.baseVirtualPrice
                ),
                v.preciseA
            );
        }

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            require(
                v.totalSupply != 0 || amounts[i] > 0,
                "Must supply all tokens in pool"
            );

            // Transfer tokens first to see if a fee was charged on transfer
            if (amounts[i] != 0) {
                uint256 beforeBalance =
                    pooledTokens[i].balanceOf(address(this));
                pooledTokens[i].safeTransferFrom(
                    msg.sender,
                    address(this),
                    amounts[i]
                );

                // Update the amounts[] with actual transfer amount
                amounts[i] = pooledTokens[i].balanceOf(address(this)).sub(
                    beforeBalance
                );
            }

            v.newBalances[i] = v.newBalances[i].add(amounts[i]);
        }

        // invariant after change
        v.d1 = SwapUtils.getD(
            _xp(v.newBalances, v.tokenPrecisionMultipliers, v.baseVirtualPrice),
            v.preciseA
        );
        require(v.d1 > v.d0, "D should increase");

        // updated to reflect fees and calculate the user's LP tokens
        v.d2 = v.d1;
        uint256 toMint;

        if (v.totalSupply != 0) {
            uint256 feePerToken =
                SwapUtils._feePerToken(self.swapFee, pooledTokens.length);
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(self.balances[i]).div(v.d0);
                fees[i] = feePerToken
                    .mul(idealBalance.difference(v.newBalances[i]))
                    .div(FEE_DENOMINATOR);
                self.balances[i] = v.newBalances[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR)
                );
                v.newBalances[i] = v.newBalances[i].sub(fees[i]);
            }
            v.d2 = SwapUtils.getD(
                _xp(
                    v.newBalances,
                    v.tokenPrecisionMultipliers,
                    v.baseVirtualPrice
                ),
                v.preciseA
            );
            toMint = v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
        } else {
            // the initial depositor doesn't pay fees
            self.balances = v.newBalances;
            toMint = v.d1;
        }

        require(toMint >= minToMint, "Couldn't mint min requested");

        // mint the user's LP tokens
        self.lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(
            msg.sender,
            amounts,
            fees,
            v.d1,
            v.totalSupply.add(toMint)
        );

        return toMint;
    }

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param self Swap struct to read from and write to
     * @param metaSwapStorage MetaSwap struct to read from and write to
     * @param tokenAmount the amount of the lp tokens to burn
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @return amount chosen token that user received
     */
    function removeLiquidityOneToken(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount
    ) external returns (uint256) {
        LPToken lpToken = self.lpToken;
        uint256 totalSupply = lpToken.totalSupply();
        uint256 numTokens = self.pooledTokens.length;
        require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(tokenIndex < numTokens, "Token not found");

        uint256 dyFee;
        uint256 dy;

        (dy, dyFee) = _calculateWithdrawOneToken(
            self,
            msg.sender,
            tokenAmount,
            tokenIndex,
            _updateBaseVirtualPrice(metaSwapStorage),
            totalSupply
        );

        require(dy >= minAmount, "dy < minAmount");

        // Update balances array
        self.balances[tokenIndex] = self.balances[tokenIndex].sub(
            dy.add(dyFee.mul(self.adminFee).div(FEE_DENOMINATOR))
        );

        // Burn the associated LP token from the caller and send the desired token
        lpToken.burnFrom(msg.sender, tokenAmount);
        self.pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(
            msg.sender,
            tokenAmount,
            totalSupply,
            tokenIndex,
            dy
        );

        return dy;
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     *
     * @param self Swap struct to read from and write to
     * @param metaSwapStorage MetaSwap struct to read from and write to
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @return actual amount of LP tokens burned in the withdrawal
     */
    function removeLiquidityImbalance(
        SwapUtils.Swap storage self,
        MetaSwap storage metaSwapStorage,
        uint256[] memory amounts,
        uint256 maxBurnAmount
    ) public returns (uint256) {
        // Using this struct to avoid stack too deep error
        ManageLiquidityInfo memory v =
            ManageLiquidityInfo(
                0,
                0,
                0,
                self.lpToken,
                0,
                self._getAPrecise(),
                _updateBaseVirtualPrice(metaSwapStorage),
                self.tokenPrecisionMultipliers,
                self.balances
            );
        v.totalSupply = v.lpToken.totalSupply();

        require(
            amounts.length == v.newBalances.length,
            "Amounts should match pool tokens"
        );
        require(maxBurnAmount != 0, "Must burn more than 0");

        uint256 feePerToken =
            SwapUtils._feePerToken(self.swapFee, v.newBalances.length);

        // Calculate how much LPToken should be burned
        uint256[] memory fees = new uint256[](v.newBalances.length);
        {
            uint256[] memory balances1 = new uint256[](v.newBalances.length);

            v.d0 = SwapUtils.getD(
                _xp(
                    v.newBalances,
                    v.tokenPrecisionMultipliers,
                    v.baseVirtualPrice
                ),
                v.preciseA
            );
            for (uint256 i = 0; i < v.newBalances.length; i++) {
                balances1[i] = v.newBalances[i].sub(
                    amounts[i],
                    "Cannot withdraw more than available"
                );
            }
            v.d1 = SwapUtils.getD(
                _xp(balances1, v.tokenPrecisionMultipliers, v.baseVirtualPrice),
                v.preciseA
            );

            for (uint256 i = 0; i < v.newBalances.length; i++) {
                uint256 idealBalance = v.d1.mul(v.newBalances[i]).div(v.d0);
                uint256 difference = idealBalance.difference(balances1[i]);
                fees[i] = feePerToken.mul(difference).div(FEE_DENOMINATOR);
                self.balances[i] = balances1[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR)
                );
                balances1[i] = balances1[i].sub(fees[i]);
            }

            v.d2 = SwapUtils.getD(
                _xp(balances1, v.tokenPrecisionMultipliers, v.baseVirtualPrice),
                v.preciseA
            );
        }

        uint256 tokenAmount = v.d0.sub(v.d2).mul(v.totalSupply).div(v.d0);
        require(tokenAmount != 0, "Burnt amount cannot be zero");

        // Scale up by withdraw fee
        tokenAmount = tokenAmount.add(1).mul(FEE_DENOMINATOR).div(
            FEE_DENOMINATOR.sub(
                SwapUtils._calculateCurrentWithdrawFee(self, msg.sender)
            )
        );

        // Check for max burn amount
        require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

        // Burn the calculated amount of LPToken from the caller and send the desired tokens
        v.lpToken.burnFrom(msg.sender, tokenAmount);
        for (uint256 i = 0; i < v.newBalances.length; i++) {
            self.pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(
            msg.sender,
            amounts,
            fees,
            v.d1,
            v.totalSupply.sub(tokenAmount)
        );

        return tokenAmount;
    }

    /**
     * @notice Determines if the stored value of base Swap's virtual price is expired.
     * If the last update was past the BASE_CACHE_EXPIRE_TIME, then update the stored value.
     *
     * @param metaSwapStorage MetaSwap struct to read from and write to
     * @return base Swap's virtual price
     */
    function _updateBaseVirtualPrice(MetaSwap storage metaSwapStorage)
        internal
        returns (uint256)
    {
        if (
            block.timestamp >
            metaSwapStorage.baseCacheLastUpdated + BASE_CACHE_EXPIRE_TIME
        ) {
            // When the cache is expired, update it
            uint256 baseVirtualPrice =
                ISwap(metaSwapStorage.baseSwap).getVirtualPrice();
            metaSwapStorage.baseVirtualPrice = baseVirtualPrice;
            metaSwapStorage.baseCacheLastUpdated = block.timestamp;
            return baseVirtualPrice;
        } else {
            return metaSwapStorage.baseVirtualPrice;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../MathUtils.sol";

contract TestMathUtils {
    using MathUtils for uint256;

    function difference(uint256 a, uint256 b) public pure returns (uint256) {
        return a.difference(b);
    }

    function within1(uint256 a, uint256 b) public pure returns (bool) {
        return a.within1(b);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Generic ERC20 token
 * @notice This contract simulates a generic ERC20 token that is mintable and burnable.
 */
contract GenericERC20 is ERC20, Ownable {
    /**
     * @notice Deploy this contract with given name, symbol, and decimals
     * @dev the caller of this constructor will become the owner of this contract
     * @param name_ name of this token
     * @param symbol_ symbol of this token
     * @param decimals_ number of decimals this token will be based on
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public ERC20(name_, symbol_) {
        _setupDecimals(decimals_);
    }

    /**
     * @notice Mints given amount of tokens to recipient
     * @dev only owner can call this mint function
     * @param recipient address of account to receive the tokens
     * @param amount amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(amount != 0, "amount == 0");
        _mint(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../Swap.sol";
import "./MetaSwapUtils.sol";

/**
 * @title MetaSwap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * MetaSwap is a modified version of Swap that allows Swap's LP token to be utilized in pooling with other tokens.
 * As an example, if there is a Swap pool consisting of [DAI, USDC, USDT], then a MetaSwap pool can be created
 * with [sUSD, BaseSwapLPToken] to allow trades between either the LP token or the underlying tokens and sUSD.
 * Note that when interacting with MetaSwap, users cannot deposit or withdraw via underlying tokens. In that case,
 * `MetaSwapDeposit.sol` can be additionally deployed to allow interacting with unwrapped representations of the tokens.
 *
 * @dev Most of the logic is stored as a library `MetaSwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract MetaSwap is Swap {
    using MetaSwapUtils for SwapUtils.Swap;

    MetaSwapUtils.MetaSwap public metaSwapStorage;

    uint256 constant MAX_UINT256 = 2**256 - 1;

    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients
    event TokenSwapUnderlying(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );

    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return MetaSwapUtils.getVirtualPrice(swapStorage, metaSwapStorage);
    }

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view virtual override returns (uint256) {
        return
            MetaSwapUtils.calculateSwap(
                swapStorage,
                metaSwapStorage,
                tokenIndexFrom,
                tokenIndexTo,
                dx
            );
    }

    /**
     * @notice Calculate amount of tokens you receive on swap. For this function,
     * the token indices are flattened out so that underlying tokens are represented.
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function calculateSwapUnderlying(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view virtual returns (uint256) {
        return
            MetaSwapUtils.calculateSwapUnderlying(
                swapStorage,
                metaSwapStorage,
                tokenIndexFrom,
                tokenIndexTo,
                dx
            );
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param account address that is depositing or withdrawing tokens
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return token amount the user will receive
     */
    function calculateTokenAmount(
        address account,
        uint256[] calldata amounts,
        bool deposit
    ) external view virtual override returns (uint256) {
        return
            MetaSwapUtils.calculateTokenAmount(
                swapStorage,
                metaSwapStorage,
                account,
                amounts,
                deposit
            );
    }

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param account the address that is withdrawing tokens
     * @param tokenAmount the amount of LP token to burn
     * @param tokenIndex index of which token will be withdrawn
     * @return availableTokenAmount calculated amount of underlying token
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view virtual override returns (uint256) {
        return
            MetaSwapUtils.calculateWithdrawOneToken(
                swapStorage,
                metaSwapStorage,
                account,
                tokenAmount,
                tokenIndex
            );
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice This overrides Swap's initialize function to prevent initializing
     * without the address of the base Swap contract.
     *
     * @param _pooledTokens an array of ERC20s this pool will accept
     * @param decimals the decimals to use for each pooled token,
     * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param _withdrawFee default withdrawFee to be initialized with
     */
    function initialize(
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address lpTokenTargetAddress
    ) public virtual override initializer {
        revert("use initializeMetaSwap() instead");
    }

    /**
     * @notice Initializes this MetaSwap contract with the given parameters.
     * MetaSwap uses an existing Swap pool to expand the available liquidity.
     * _pooledTokens array should contain the base Swap pool's LP token as
     * the last element. For example, if there is a Swap pool consisting of
     * [DAI, USDC, USDT]. Then a MetaSwap pool can be created with [sUSD, BaseSwapLPToken]
     * as _pooledTokens.
     *
     * This will also deploy the LPToken that represents users'
     * LP position. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint new tokens.
     *
     * @param _pooledTokens an array of ERC20s this pool will accept. The last
     * element must be an existing Swap pool's LP token's address.
     * @param decimals the decimals to use for each pooled token,
     * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param _withdrawFee default withdrawFee to be initialized with
     */
    function initializeMetaSwap(
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        uint256 _withdrawFee,
        address lpTokenTargetAddress,
        ISwap baseSwap
    ) external virtual initializer {
        Swap.initialize(
            _pooledTokens,
            decimals,
            lpTokenName,
            lpTokenSymbol,
            _a,
            _fee,
            _adminFee,
            _withdrawFee,
            lpTokenTargetAddress
        );

        // MetaSwap initializer
        metaSwapStorage.baseSwap = baseSwap;
        metaSwapStorage.baseVirtualPrice = baseSwap.getVirtualPrice();
        metaSwapStorage.baseCacheLastUpdated = block.timestamp;

        // Read all tokens that belong to baseSwap
        {
            uint8 i;
            for (; i < 32; i++) {
                try baseSwap.getToken(i) returns (IERC20 token) {
                    metaSwapStorage.baseTokens.push(token);
                    token.safeApprove(address(baseSwap), MAX_UINT256);
                } catch {
                    break;
                }
            }
            require(i > 1, "baseSwap must pool at least 2 tokens");
        }

        // Check the last element of _pooledTokens is owned by baseSwap
        IERC20 baseLPToken = _pooledTokens[_pooledTokens.length - 1];
        require(
            LPToken(address(baseLPToken)).owner() == address(baseSwap),
            "baseLPToken is not owned by baseSwap"
        );

        // Pre-approve the baseLPToken to be used by baseSwap
        baseLPToken.safeApprove(address(baseSwap), MAX_UINT256);
    }

    /**
     * @notice Swap two tokens using this pool
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            MetaSwapUtils.swap(
                swapStorage,
                metaSwapStorage,
                tokenIndexFrom,
                tokenIndexTo,
                dx,
                minDy
            );
    }

    /**
     * @notice Swap two tokens using this pool and the base pool.
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swapUnderlying(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
        external
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            MetaSwapUtils.swapUnderlying(
                swapStorage,
                metaSwapStorage,
                tokenIndexFrom,
                tokenIndexTo,
                dx,
                minDy
            );
    }

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            MetaSwapUtils.addLiquidity(
                swapStorage,
                metaSwapStorage,
                amounts,
                minToMint
            );
    }

    /**
     * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param tokenAmount the amount of the token you want to receive
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param deadline latest timestamp to accept this transaction
     * @return amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            MetaSwapUtils.removeLiquidityOneToken(
                swapStorage,
                metaSwapStorage,
                tokenAmount,
                tokenIndex,
                minAmount
            );
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            MetaSwapUtils.removeLiquidityImbalance(
                swapStorage,
                metaSwapStorage,
                amounts,
                maxBurnAmount
            );
    }
}

