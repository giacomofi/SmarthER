/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/interfaces/IFactory.sol

pragma solidity ^0.8.9;

interface IFactory {
    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pair,
        uint256
    );

    function getPair(
        address token0,
        address token1
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function feeArg() external view returns (uint32);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function allPairsLength() external view returns (uint256);

    function initialize(address _twammAdd) external;

    function twammAdd() external view returns (address);

    function createPair(
        address token0,
        address token1
    ) external returns (address pair);

    function setFeeArg(uint32) external;

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.0;

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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File prb-math/contracts/[email protected]

pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2 ** 128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2 ** 64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2 ** 32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2 ** 16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2 ** 8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2 ** 4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2 ** 2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2 ** 1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(
                            sub(prod1, gt(remainder, prod0)),
                            add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1)
                        )
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (
            x == type(int256).min ||
            y == type(int256).min ||
            denominator == type(int256).min
        ) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// File prb-math/contracts/[email protected]

pragma solidity >=0.8.4;

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// File contracts/libraries/OrderPool.sol

pragma solidity ^0.8.9;

///@notice An Order Pool is an abstraction for a pool of long term orders that sells a token at a constant rate to the embedded AMM.
///the order pool handles the logic for distributing the proceeds from these sales to the owners of the long term orders through a modified
///version of the staking algorithm from  https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
library OrderPoolLib {
    using PRBMathUD60x18 for uint256;

    ///@notice you can think of this as a staking pool where all long term orders are staked.
    /// The pool is paid when virtual long term orders are executed, and each order is paid proportionally
    /// by the order's sale rate per block
    struct OrderPool {
        ///@notice current rate that tokens are being sold (per block)
        uint256 currentSalesRate;
        ///@notice sum of (salesProceeds_k / salesRate_k) over every period k. Stored as a fixed precision floating point number
        uint256 rewardFactor;
        ///@notice this maps block numbers to the cumulative sales rate of orders that expire on that block
        mapping(uint256 => uint256) salesRateEndingPerBlock;
        ///@notice map order ids to the block in which they expire
        mapping(uint256 => uint256) orderExpiry;
        ///@notice map order ids to their sales rate
        mapping(uint256 => uint256) salesRate;
        ///@notice reward factor per order at time of submission
        mapping(uint256 => uint256) rewardFactorAtSubmission;
        ///@notice reward factor at a specific block
        mapping(uint256 => uint256) rewardFactorAtBlock;
    }

    ///@notice distribute payment amount to pool (in the case of TWAMM, proceeds from trades against amm)
    function distributePayment(OrderPool storage self, uint256 amount) public {
        if (self.currentSalesRate != 0) {
            //floating point arithmetic
            self.rewardFactor += amount
                .fromUint()
                .mul(PRBMathUD60x18.fromUint(10000))
                .div(self.currentSalesRate.fromUint());
        }
    }

    ///@notice deposit an order into the order pool.
    function depositOrder(
        OrderPool storage self,
        uint256 orderId,
        uint256 amountPerBlock,
        uint256 orderExpiry
    ) public {
        self.currentSalesRate += amountPerBlock;
        self.rewardFactorAtSubmission[orderId] = self.rewardFactor;
        self.orderExpiry[orderId] = orderExpiry;
        self.salesRate[orderId] = amountPerBlock;
        self.salesRateEndingPerBlock[orderExpiry] += amountPerBlock;
    }

    ///@notice when orders expire after a given block, we need to update the state of the pool
    function updateStateFromBlockExpiry(
        OrderPool storage self,
        uint256 blockNumber
    ) public {
        uint256 ordersExpiring = self.salesRateEndingPerBlock[blockNumber];
        self.currentSalesRate -= ordersExpiring;
        self.rewardFactorAtBlock[blockNumber] = self.rewardFactor;
    }

    ///@notice cancel order and remove from the order pool
    function cancelOrder(
        OrderPool storage self,
        uint256 orderId
    ) public returns (uint256 unsoldAmount, uint256 purchasedAmount) {
        uint256 expiry = self.orderExpiry[orderId];
        require(expiry > block.number, "Order Already Finished");

        //calculate amount that wasn't sold, and needs to be returned
        uint256 salesRate = self.salesRate[orderId];
        uint256 blocksRemaining = expiry - block.number;
        unsoldAmount = (blocksRemaining * salesRate) / 10000;

        //calculate amount of other token that was purchased
        uint256 rewardFactorAtSubmission = self.rewardFactorAtSubmission[
            orderId
        ];
        purchasedAmount = (self.rewardFactor - rewardFactorAtSubmission)
            .mul(salesRate.fromUint())
            .div(PRBMathUD60x18.fromUint(10000))
            .toUint();

        //update state
        self.currentSalesRate -= salesRate;
        self.salesRate[orderId] = 0;
        self.orderExpiry[orderId] = 0;
        self.salesRateEndingPerBlock[expiry] -= salesRate;
    }

    ///@notice withdraw proceeds from pool for a given order. This can be done before or after the order has expired.
    //If the order has expired, we calculate the reward factor at time of expiry. If order has not yet expired, we
    //use current reward factor, and update the reward factor at time of staking (effectively creating a new order)
    function withdrawProceeds(
        OrderPool storage self,
        uint256 orderId
    ) public returns (uint256 totalReward) {
        uint256 stakedAmount = self.salesRate[orderId];
        require(stakedAmount > 0, "Sales Rate Amount Must Be Positive");
        uint256 orderExpiry = self.orderExpiry[orderId];
        uint256 rewardFactorAtSubmission = self.rewardFactorAtSubmission[
            orderId
        ];

        //if order has expired, we need to calculate the reward factor at expiry
        if (block.number >= orderExpiry) {
            uint256 rewardFactorAtExpiry = self.rewardFactorAtBlock[
                orderExpiry
            ];
            totalReward = (rewardFactorAtExpiry - rewardFactorAtSubmission)
                .mul(stakedAmount.fromUint())
                .div(PRBMathUD60x18.fromUint(10000))
                .toUint();
            //remove stake
            self.salesRate[orderId] = 0;
        }
        //if order has not yet expired, we just adjust the start
        else {
            totalReward = (self.rewardFactor - rewardFactorAtSubmission)
                .mul(stakedAmount.fromUint())
                .div(PRBMathUD60x18.fromUint(10000))
                .toUint();
            self.rewardFactorAtSubmission[orderId] = self.rewardFactor;
        }
    }
}

// File contracts/libraries/BinarySearchTree.sol

pragma solidity ^0.8.9;

library BinarySearchTreeLib {
    uint256 private constant TIME_EXTENSION = 50400;

    struct Node {
        uint256 parent;
        uint256 value;
        uint256 left;
        uint256 right;
    }

    struct Tree {
        uint256 root;
        uint256 rootLast;
        mapping(uint256 => Node) nodes;
        mapping(uint256 => uint256[]) rootToList;
        mapping(uint256 => uint256[]) futureExpiries; //map from last divisible root to a list of exipiries sine that root. not ordered
    }

    // helper function for insert
    function insertHelper(
        Tree storage self,
        uint256 newValue,
        uint256 nodeId
    ) public {
        // current node
        Node memory curNode = self.nodes[nodeId];
        // if value exists, no need to insert
        if (newValue != curNode.value) {
            if (newValue < curNode.value) {
                if (curNode.left == 0) {
                    self.nodes[curNode.value].left = newValue;
                    self.nodes[newValue] = Node(curNode.value, newValue, 0, 0);
                } else {
                    insertHelper(self, newValue, curNode.left);
                }
            } else {
                if (curNode.right == 0) {
                    self.nodes[curNode.value].right = newValue;
                    self.nodes[newValue] = Node(curNode.value, newValue, 0, 0);
                } else {
                    insertHelper(self, newValue, curNode.right);
                }
            }
        }
    }

    function insert(Tree storage self, uint256 newValue) public {
        // no tree exists
        if (self.root == 0) {
            self.root = newValue;
            self.rootLast = newValue;
            self.nodes[newValue] = Node(0, newValue, 0, 0);
            self.futureExpiries[self.root].push(newValue);
        } else {
            insertHelper(self, newValue, self.root);
        }
    }

    function returnListHelperEx(
        Tree storage self,
        uint256 start,
        uint256 end,
        uint256 nodeId,
        uint256 extension
    ) public {
        if (start <= end && end < extension) {
            // current node
            Node memory curNode = self.nodes[nodeId];
            if (curNode.value != 0) {
                if (curNode.value > start) {
                    returnListHelperEx(
                        self,
                        start,
                        end,
                        curNode.left,
                        extension
                    );
                }

                if (curNode.value <= end && curNode.value >= start) {
                    if (
                        self.rootToList[self.root].length == 0 ||
                        (self.rootToList[self.root].length > 0 &&
                            self.rootToList[self.root][
                                self.rootToList[self.root].length - 1
                            ] !=
                            curNode.value)
                    ) {
                        self.rootToList[self.root].push(curNode.value);
                    }
                }

                if (curNode.value <= extension && curNode.value > end) {
                    if (
                        self.futureExpiries[self.root].length == 0 ||
                        (self.futureExpiries[self.root].length > 0 &&
                            self.futureExpiries[self.root][
                                self.futureExpiries[self.root].length - 1
                            ] !=
                            curNode.value)
                    ) {
                        self.futureExpiries[self.root].push(curNode.value);
                    }
                }

                if (curNode.value < extension) {
                    returnListHelperEx(
                        self,
                        start,
                        end,
                        curNode.right,
                        extension
                    );
                }
            }
        }
    }

    function deleteNodeHelper(
        Tree storage self,
        uint256 deleteValue,
        uint256 nodeId
    ) public returns (uint256 newValue) {
        Node memory curNode = self.nodes[nodeId];
        if (curNode.value == deleteValue) {
            newValue = deleteLeaf(self, curNode.value);
        } else if (curNode.value < deleteValue) {
            if (curNode.right == 0) {
                newValue = 0;
            } else {
                newValue = deleteNodeHelper(self, deleteValue, curNode.right);
            }
        } else {
            if (curNode.left == 0) {
                newValue = 0;
            } else {
                newValue = deleteNodeHelper(self, deleteValue, curNode.left);
            }
        }
    }

    function deleteLeaf(
        Tree storage self,
        uint256 nodeId
    ) public returns (uint256 newNodeId) {
        Node memory curNode = self.nodes[nodeId];
        if (curNode.left != 0) {
            uint256 tempValue = curNode.left;
            while (self.nodes[tempValue].right != 0) {
                tempValue = self.nodes[tempValue].right;
            }
            if (tempValue != curNode.left) {
                if (curNode.parent != 0) {
                    if (curNode.value < curNode.parent) {
                        self.nodes[curNode.parent].left = tempValue;
                    } else {
                        self.nodes[curNode.parent].right = tempValue;
                    }
                }

                if (curNode.right != 0) {
                    self.nodes[curNode.right].parent = tempValue;
                }

                self.nodes[curNode.left].parent = tempValue;
                curNode.value = tempValue;

                deleteNodeHelper(self, tempValue, curNode.left);
                self.nodes[tempValue] = curNode;
                self.nodes[nodeId] = Node(0, 0, 0, 0);
            } else {
                if (curNode.parent != 0) {
                    if (curNode.value < curNode.parent) {
                        self.nodes[curNode.parent].left = curNode.left;
                    } else {
                        self.nodes[curNode.parent].right = curNode.left;
                    }
                }

                if (curNode.right != 0) {
                    self.nodes[curNode.right].parent = curNode.left;
                }

                self.nodes[curNode.left].parent = curNode.parent;
                self.nodes[curNode.left].right = curNode.right;
                self.nodes[nodeId] = Node(0, 0, 0, 0);
            }
            newNodeId = tempValue;
        } else if (curNode.left == 0 && curNode.right != 0) {
            uint256 tempValue = curNode.right;
            if (curNode.parent != 0) {
                if (curNode.value < curNode.parent) {
                    self.nodes[curNode.parent].left = tempValue;
                } else {
                    self.nodes[curNode.parent].right = tempValue;
                }
            }

            self.nodes[curNode.right].parent = curNode.parent;
            self.nodes[nodeId] = Node(0, 0, 0, 0);
            newNodeId = tempValue;
        } else {
            if (curNode.parent != 0) {
                if (curNode.value < curNode.parent) {
                    self.nodes[curNode.parent].left = 0;
                } else {
                    self.nodes[curNode.parent].right = 0;
                }
            }
            self.nodes[nodeId] = Node(0, 0, 0, 0);
            newNodeId = 0;
        }
    }

    function deleteNode(
        Tree storage self,
        uint256 deleteValue
    ) public returns (uint256 newRoot) {
        if (deleteValue != self.root) {
            deleteNodeHelper(self, deleteValue, self.root);
            newRoot = self.root;
        } else {
            newRoot = deleteLeaf(self, self.root);
            self.root = newRoot;
        }
    }

    function trimTreeHelper(
        Tree storage self,
        uint256 start,
        uint256 end,
        uint256 nodeId
    ) public {
        if (start <= end) {
            // current node
            Node memory curNode = self.nodes[nodeId];
            if (curNode.value != 0) {
                if (curNode.value < start) {
                    trimTreeHelper(self, start, end, curNode.right);
                } else if (curNode.value >= start && curNode.value <= end) {
                    uint256 newNodeId = deleteLeaf(self, curNode.value);
                    if (newNodeId != 0) {
                        trimTreeHelper(self, start, end, newNodeId);
                    }
                } else {
                    trimTreeHelper(self, start, end, curNode.left);
                }
            }
        }
    }

    function trimTree(
        Tree storage self,
        uint256 start,
        uint256 end
    ) public returns (uint256 newRoot) {
        if (start <= end) {
            // current root
            Node memory rootNode = self.nodes[self.root];
            if (rootNode.value != 0) {
                if (rootNode.value < start) {
                    trimTreeHelper(self, start, end, rootNode.right);
                    newRoot = self.root;
                } else if (rootNode.value >= start && rootNode.value <= end) {
                    newRoot = deleteNode(self, rootNode.value);
                    if (newRoot != 0) {
                        newRoot = trimTree(self, start, end);
                    }
                } else {
                    trimTreeHelper(self, start, end, rootNode.left);
                    newRoot = self.root;
                }
            }
        }
    }

    function processExpiriesListNTrimTree(
        Tree storage self,
        uint256 start,
        uint256 end
    ) public {
        if (self.root != 0) {
            //must have a tree
            delete self.futureExpiries[self.root];
            self.futureExpiries[self.root].push(end);
            if (self.root == self.rootLast) {
                delete self.rootToList[self.root];
            }
            returnListHelperEx(
                self,
                start,
                end,
                self.root,
                end + TIME_EXTENSION
            );
            self.rootLast = self.root;
            trimTree(self, start, end);
        }
    }

    function getExpiriesList(
        Tree storage self
    ) public view returns (uint256[] storage) {
        return self.rootToList[self.rootLast];
    }

    function getFutureExpiriesList(
        Tree storage self
    ) public view returns (uint256[] storage) {
        return self.futureExpiries[self.rootLast];
    }
}

// File contracts/libraries/LongTermOrders.sol

pragma solidity ^0.8.9;

// import "prb-math/contracts/PRBMathSD59x18.sol";

///@notice This library handles the state and execution of long term orders.
library LongTermOrdersLib {
    //using PRBMathSD59x18 for int256;
    using OrderPoolLib for OrderPoolLib.OrderPool;
    using BinarySearchTreeLib for BinarySearchTreeLib.Tree;
    using SafeERC20 for IERC20;

    ///@notice fee for LP providers, 4 decimal places, i.e. 30 = 0.3%
    uint256 public constant LP_FEE = 30;

    ///@notice information associated with a long term order
    struct Order {
        uint256 id;
        uint256 submitBlock;
        uint256 expirationBlock;
        uint256 saleRate;
        uint256 sellAmount;
        uint256 buyAmount;
        address owner;
        address sellTokenId;
        address buyTokenId;
    }

    ///@notice structure contains full state related to long term orders
    struct LongTermOrders {
        ///@notice minimum block interval between order expiries
        uint256 orderBlockInterval;
        ///@notice last virtual orders were executed immediately before this block
        uint256 lastVirtualOrderBlock;
        ///@notice token pair being traded in embedded amm
        address tokenA;
        address tokenB;
        ///@notice useful addresses for TWAMM transactions
        address refTWAMM;
        ///@notice mapping from token address to pool that is selling that token
        ///we maintain two order pools, one for each token that is tradable in the AMM
        mapping(address => OrderPoolLib.OrderPool) OrderPoolMap;
        ///@notice incrementing counter for order ids
        uint256 orderId;
        ///@notice mapping from order ids to Orders
        mapping(uint256 => Order) orderMap;
        ///@notice mapping from account address to its corresponding list of order ids
        mapping(address => uint256[]) orderIdMap;
        ///@notice mapping from order id to its status (false for nonactive true for active)
        mapping(uint256 => bool) orderIdStatusMap;
        ///@notice record all expiry blocks since the latest executed block
        BinarySearchTreeLib.Tree expiryBlockTreeSinceLastExecution;
    }

    ///@notice initialize state
    function initialize(
        LongTermOrders storage self,
        address tokenA,
        address tokenB,
        address refTWAMM,
        uint256 lastVirtualOrderBlock,
        uint256 orderBlockInterval
    ) public {
        self.tokenA = tokenA;
        self.tokenB = tokenB;
        self.refTWAMM = refTWAMM;
        self.lastVirtualOrderBlock = lastVirtualOrderBlock;
        self.orderBlockInterval = orderBlockInterval;
        self.expiryBlockTreeSinceLastExecution.insert(
            lastVirtualOrderBlock - (lastVirtualOrderBlock % orderBlockInterval)
        );
    }

    ///@notice long term swap token A for token B. Amount represents total amount being sold, numberOfBlockIntervals determines when order expires
    function longTermSwapFromAToB(
        LongTermOrders storage self,
        address sender,
        uint256 amountA,
        uint256 numberOfBlockIntervals,
        mapping(address => uint256) storage reserveMap
    ) public returns (uint256) {
        return
            performLongTermSwap(
                self,
                self.tokenA,
                self.tokenB,
                sender,
                amountA,
                numberOfBlockIntervals,
                reserveMap
            );
    }

    ///@notice long term swap token B for token A. Amount represents total amount being sold, numberOfBlockIntervals determines when order expires
    function longTermSwapFromBToA(
        LongTermOrders storage self,
        address sender,
        uint256 amountB,
        uint256 numberOfBlockIntervals,
        mapping(address => uint256) storage reserveMap
    ) public returns (uint256) {
        return
            performLongTermSwap(
                self,
                self.tokenB,
                self.tokenA,
                sender,
                amountB,
                numberOfBlockIntervals,
                reserveMap
            );
    }

    ///@notice adds long term swap to order pool
    function performLongTermSwap(
        LongTermOrders storage self,
        address from,
        address to,
        address sender,
        uint256 amount,
        uint256 numberOfBlockIntervals,
        mapping(address => uint256) storage reserveMap
    ) private returns (uint256) {
        //determine the selling rate based on number of blocks to expiry and total amount
        uint256 currentBlock = block.number;
        uint256 lastExpiryBlock = currentBlock -
            (currentBlock % self.orderBlockInterval);
        uint256 orderExpiry = self.orderBlockInterval *
            (numberOfBlockIntervals + 1) +
            lastExpiryBlock;
        uint256 sellingRate = (amount * 10000) / (orderExpiry - currentBlock); //multiply by 10000 to reduce precision loss

        //insert order expiry and update virtual order state
        self.expiryBlockTreeSinceLastExecution.insert(orderExpiry);
        executeVirtualOrdersUntilSpecifiedBlock(self, reserveMap, block.number);

        //add order to correct pool
        OrderPoolLib.OrderPool storage OrderPool = self.OrderPoolMap[from];
        OrderPool.depositOrder(self.orderId, sellingRate, orderExpiry);

        //add to order map
        self.orderMap[self.orderId] = Order(
            self.orderId,
            currentBlock,
            orderExpiry,
            sellingRate,
            0,
            0,
            sender,
            from,
            to
        );

        // add user's corresponding orderId to orderId mapping list content
        self.orderIdMap[sender].push(self.orderId);

        self.orderIdStatusMap[self.orderId] = true;

        return self.orderId++;
    }

    ///@notice cancel long term swap, pay out unsold tokens and well as purchased tokens
    function cancelLongTermSwap(
        LongTermOrders storage self,
        address sender,
        uint256 orderId,
        mapping(address => uint256) storage reserveMap
    ) public returns (uint256, uint256) {
        //update virtual order state
        executeVirtualOrdersUntilSpecifiedBlock(self, reserveMap, block.number);

        Order storage order = self.orderMap[orderId];

        require(self.orderIdStatusMap[orderId] == true, "Order Invalid");
        require(order.owner == sender, "Sender Must Be Order Owner");

        OrderPoolLib.OrderPool storage OrderPoolSell = self.OrderPoolMap[
            order.sellTokenId
        ];
        OrderPoolLib.OrderPool storage OrderPoolBuy = self.OrderPoolMap[
            order.buyTokenId
        ];

        (uint256 unsoldAmount, uint256 purchasedAmount) = OrderPoolSell
            .cancelOrder(orderId);
        require(
            unsoldAmount > 0 || purchasedAmount > 0,
            "No Proceeds To Withdraw"
        );

        order.sellAmount =
            ((block.number - order.submitBlock) * order.saleRate) /
            10000;
        order.buyAmount += purchasedAmount;

        if (
            OrderPoolSell.salesRateEndingPerBlock[order.expirationBlock] == 0 &&
            OrderPoolBuy.salesRateEndingPerBlock[order.expirationBlock] == 0
        ) {
            self.expiryBlockTreeSinceLastExecution.deleteNode(
                order.expirationBlock
            );
        }

        // delete orderId from account list
        self.orderIdStatusMap[orderId] = false;

        //transfer to owner
        IERC20(order.buyTokenId).safeTransfer(self.refTWAMM, purchasedAmount);
        IERC20(order.sellTokenId).safeTransfer(self.refTWAMM, unsoldAmount);

        return (unsoldAmount, purchasedAmount);
    }

    ///@notice withdraw proceeds from a long term swap (can be expired or ongoing)
    function withdrawProceedsFromLongTermSwap(
        LongTermOrders storage self,
        address sender,
        uint256 orderId,
        mapping(address => uint256) storage reserveMap
    ) public returns (uint256) {
        //update virtual order state
        executeVirtualOrdersUntilSpecifiedBlock(self, reserveMap, block.number);

        Order storage order = self.orderMap[orderId];

        require(self.orderIdStatusMap[orderId] == true, "Order Invalid");
        require(order.owner == sender, "Sender Must Be Order Owner");

        OrderPoolLib.OrderPool storage OrderPool = self.OrderPoolMap[
            order.sellTokenId
        ];
        uint256 proceeds = OrderPool.withdrawProceeds(orderId);
        require(proceeds > 0, "No Proceeds To Withdraw");

        order.buyAmount += proceeds;

        if (order.expirationBlock <= block.number) {
            // delete orderId from account list
            self.orderIdStatusMap[orderId] = false;
            order.sellAmount =
                ((order.expirationBlock - order.submitBlock) * order.saleRate) /
                10000;
        } else {
            order.sellAmount =
                ((block.number - order.submitBlock) * order.saleRate) /
                10000;
        }

        //transfer to owner
        IERC20(order.buyTokenId).safeTransfer(self.refTWAMM, proceeds);

        return proceeds;
    }

    ///@notice executes all virtual orders between current lastVirtualOrderBlock and blockNumber
    //also handles orders that expire at end of final block. This assumes that no orders expire inside the given interval
    function executeVirtualTradesAndOrderExpiries(
        LongTermOrders storage self,
        mapping(address => uint256) storage reserveMap,
        uint256 blockNumber
    ) private {
        //amount sold from virtual trades
        uint256 blockNumberIncrement = blockNumber - self.lastVirtualOrderBlock;
        uint256 tokenASellAmount = (self
            .OrderPoolMap[self.tokenA]
            .currentSalesRate * blockNumberIncrement) / 10000;
        uint256 tokenBSellAmount = (self
            .OrderPoolMap[self.tokenB]
            .currentSalesRate * blockNumberIncrement) / 10000;

        //initial amm balance
        uint256 tokenAStart = reserveMap[self.tokenA];
        uint256 tokenBStart = reserveMap[self.tokenB];

        //updated balances from sales
        (
            uint256 tokenAOut,
            uint256 tokenBOut,
            uint256 ammEndTokenA,
            uint256 ammEndTokenB
        ) = computeVirtualBalances(
                tokenAStart,
                tokenBStart,
                tokenASellAmount,
                tokenBSellAmount
            );

        //charge LP fee
        ammEndTokenA += (tokenAOut * LP_FEE) / 10000;
        ammEndTokenB += (tokenBOut * LP_FEE) / 10000;

        tokenAOut = (tokenAOut * (10000 - LP_FEE)) / 10000;
        tokenBOut = (tokenBOut * (10000 - LP_FEE)) / 10000;

        //update balances reserves
        reserveMap[self.tokenA] = ammEndTokenA;
        reserveMap[self.tokenB] = ammEndTokenB;

        //distribute proceeds to pools
        OrderPoolLib.OrderPool storage OrderPoolA = self.OrderPoolMap[
            self.tokenA
        ];
        OrderPoolLib.OrderPool storage OrderPoolB = self.OrderPoolMap[
            self.tokenB
        ];

        OrderPoolA.distributePayment(tokenBOut);
        OrderPoolB.distributePayment(tokenAOut);

        //handle orders expiring at end of interval
        OrderPoolA.updateStateFromBlockExpiry(blockNumber);
        OrderPoolB.updateStateFromBlockExpiry(blockNumber);

        //update last virtual trade block
        self.lastVirtualOrderBlock = blockNumber;
    }

    ///@notice executes all virtual orders until specified block, includ current block.
    function executeVirtualOrdersUntilSpecifiedBlock(
        LongTermOrders storage self,
        mapping(address => uint256) storage reserveMap,
        uint256 blockNumber
    ) public {
        require(
            blockNumber <= block.number &&
                blockNumber >= self.lastVirtualOrderBlock,
            "Specified Block Number Invalid!"
        );

        OrderPoolLib.OrderPool storage OrderPoolA = self.OrderPoolMap[
            self.tokenA
        ];
        OrderPoolLib.OrderPool storage OrderPoolB = self.OrderPoolMap[
            self.tokenB
        ];

        // get list of expiryBlocks given points that are divisible by int blockInterval
        // then trim the tree to have root tree to be node correponding to the last argument (%5=0)
        self.expiryBlockTreeSinceLastExecution.processExpiriesListNTrimTree(
            self.lastVirtualOrderBlock -
                (self.lastVirtualOrderBlock % self.orderBlockInterval),
            blockNumber - (blockNumber % self.orderBlockInterval)
        );
        uint256[] storage expiriesList = self
            .expiryBlockTreeSinceLastExecution
            .getExpiriesList();

        for (uint256 i = 0; i < expiriesList.length; i++) {
            if (
                (OrderPoolA.salesRateEndingPerBlock[expiriesList[i]] > 0 ||
                    OrderPoolB.salesRateEndingPerBlock[expiriesList[i]] > 0) &&
                (expiriesList[i] > self.lastVirtualOrderBlock &&
                    expiriesList[i] < blockNumber)
            ) {
                executeVirtualTradesAndOrderExpiries(
                    self,
                    reserveMap,
                    expiriesList[i]
                );
            }
        }

        executeVirtualTradesAndOrderExpiries(self, reserveMap, blockNumber);
    }

    ///@notice computes the result of virtual trades by the token pools
    function computeVirtualBalances(
        uint256 tokenAStart,
        uint256 tokenBStart,
        uint256 tokenAIn,
        uint256 tokenBIn
    )
        private
        pure
        returns (
            uint256 tokenAOut,
            uint256 tokenBOut,
            uint256 ammEndTokenA,
            uint256 ammEndTokenB
        )
    {
        // if (
        //     tokenAStart == 0 ||
        //     tokenBStart == 0 ||
        //     tokenAIn == 0 ||
        //     tokenBIn == 0
        // ) {
        //     //in the case where only one pool is selling, we just perform a normal swap
        //constant product formula
        tokenAOut =
            ((tokenAStart + tokenAIn) * tokenBIn) /
            (tokenBStart + tokenBIn);
        tokenBOut =
            ((tokenBStart + tokenBIn) * tokenAIn) /
            (tokenAStart + tokenAIn);
        ammEndTokenA = tokenAStart + tokenAIn - tokenAOut;
        ammEndTokenB = tokenBStart + tokenBIn - tokenBOut;
    }
    //     //when both pools sell, we use the TWAMM formula
    //     else {
    //         //signed, fixed point arithmetic
    //         int256 aIn = int256(tokenAIn).fromInt();
    //         int256 bIn = int256(tokenBIn).fromInt();
    //         int256 aStart = int256(tokenAStart).fromInt();
    //         int256 bStart = int256(tokenBStart).fromInt();
    //         int256 k = aStart.mul(bStart);

    //         int256 c = computeC(aStart, bStart, aIn, bIn);
    //         int256 endA = computeAmmEndTokenA(aIn, bIn, c, k, aStart, bStart);
    //         int256 endB = aStart.div(endA).mul(bStart);

    //         int256 outA = aStart + aIn - endA;
    //         int256 outB = bStart + bIn - endB;
    //         require(outA >= 0 && outB >= 0, "Invalid Amount");

    //         return (
    //             uint256(outA.toInt()),
    //             uint256(outB.toInt()),
    //             uint256(endA.toInt()),
    //             uint256(endB.toInt())
    //         );
    //     }
    // }

    // //helper function for TWAMM formula computation, helps avoid stack depth errors
    // function computeC(
    //     int256 tokenAStart,
    //     int256 tokenBStart,
    //     int256 tokenAIn,
    //     int256 tokenBIn
    // ) private pure returns (int256 c) {
    //     int256 c1 = tokenAStart.sqrt().mul(tokenBIn.sqrt());
    //     int256 c2 = tokenBStart.sqrt().mul(tokenAIn.sqrt());
    //     int256 cNumerator = c1 - c2;
    //     int256 cDenominator = c1 + c2;
    //     c = cNumerator.div(cDenominator);
    // }

    // //helper function for TWAMM formula computation, helps avoid stack depth errors
    // function computeAmmEndTokenA(
    //     int256 tokenAIn,
    //     int256 tokenBIn,
    //     int256 c,
    //     int256 k,
    //     int256 aStart,
    //     int256 bStart
    // ) private pure returns (int256 ammEndTokenA) {
    //     //rearranged for numerical stability
    //     int256 eNumerator = PRBMathSD59x18.fromInt(4).mul(tokenAIn).sqrt().mul(
    //         tokenBIn.sqrt()
    //     );
    //     int256 eDenominator = aStart.sqrt().mul(bStart.sqrt()).inv();
    //     int256 exponent = eNumerator.mul(eDenominator).exp();
    //     require(exponent > PRBMathSD59x18.abs(c), "Invalid Amount");
    //     int256 fraction = (exponent + c).div(exponent - c);
    //     int256 scaling = k.div(tokenBIn).sqrt().mul(tokenAIn.sqrt());
    //     ammEndTokenA = fraction.mul(scaling);
    // }
}

// File contracts/interfaces/IPair.sol

pragma solidity ^0.8.9;

interface IPair {
    function factory() external view returns (address);

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function rootKLast() external view returns (uint256);

    function LP_FEE() external pure returns (uint256);

    function orderBlockInterval() external pure returns (uint256);

    function reserveMap(address) external view returns (uint256);

    function tokenAReserves() external view returns (uint256);

    function tokenBReserves() external view returns (uint256);

    function getTotalSupply() external view returns (uint256);

    event InitialLiquidityProvided(
        address indexed addr,
        uint256 lpTokenAmount,
        uint256 amountA,
        uint256 amountB
    );
    event LiquidityProvided(
        address indexed addr,
        uint256 lpTokenAmount,
        uint256 amountAIn,
        uint256 amountBIn
    );
    event LiquidityRemoved(
        address indexed addr,
        uint256 lpTokenAmount,
        uint256 amountAOut,
        uint256 amountBOut
    );
    event InstantSwapAToB(
        address indexed addr,
        uint256 amountAIn,
        uint256 amountBOut
    );
    event InstantSwapBToA(
        address indexed addr,
        uint256 amountBIn,
        uint256 amountAOut
    );
    event LongTermSwapAToB(
        address indexed addr,
        uint256 amountAIn,
        uint256 orderId
    );
    event LongTermSwapBToA(
        address indexed addr,
        uint256 amountBIn,
        uint256 orderId
    );
    event CancelLongTermOrder(
        address indexed addr,
        uint256 orderId,
        uint256 unsoldAmount,
        uint256 purchasedAmount
    );
    event WithdrawProceedsFromLongTermOrder(
        address indexed addr,
        uint256 orderId,
        uint256 proceeds
    );

    function provideInitialLiquidity(
        address to,
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 lpTokenAmount);

    function provideLiquidity(
        address to,
        uint256 lpTokenAmount
    ) external returns (uint256 amountAIn, uint256 amountBIn);

    function removeLiquidity(
        address to,
        uint256 lpTokenAmount
    ) external returns (uint256 amountAOut, uint256 amountBOut);

    function instantSwapFromAToB(
        address sender,
        uint256 amountAIn
    ) external returns (uint256 amountBOut);

    function longTermSwapFromAToB(
        address sender,
        uint256 amountAIn,
        uint256 numberOfBlockIntervals
    ) external returns (uint256 orderId);

    function instantSwapFromBToA(
        address sender,
        uint256 amountBIn
    ) external returns (uint256 amountAOut);

    function longTermSwapFromBToA(
        address sender,
        uint256 amountBIn,
        uint256 numberOfBlockIntervals
    ) external returns (uint256 orderId);

    function cancelLongTermSwap(
        address sender,
        uint256 orderId
    ) external returns (uint256 unsoldAmount, uint256 purchasedAmount);

    function withdrawProceedsFromLongTermSwap(
        address sender,
        uint256 orderId
    ) external returns (uint256 proceeds);

    function getPairOrdersAmount() external view returns (uint256);

    function getOrderDetails(
        uint256 orderId
    ) external view returns (LongTermOrdersLib.Order memory);

    function getOrderRewardFactor(
        uint256 orderId
    )
        external
        view
        returns (
            uint256 orderRewardFactorAtSubmission,
            uint256 orderRewardFactorAtExpiring
        );

    function getTWAMMState()
        external
        view
        returns (
            uint256 lastVirtualOrderBlock,
            uint256 tokenASalesRate,
            uint256 tokenBSalesRate,
            uint256 orderPoolARewardFactor,
            uint256 orderPoolBRewardFactor
        );

    function getTWAMMSalesRateEnding(
        uint256 blockNumber
    )
        external
        view
        returns (
            uint256 orderPoolASalesRateEnding,
            uint256 orderPoolBSalesRateEnding
        );

    function getExpiriesSinceLastExecuted()
        external
        view
        returns (uint256[] memory);

    function userIdsCheck(
        address userAddress
    ) external view returns (uint256[] memory);

    function orderIdStatusCheck(uint256 orderId) external view returns (bool);

    function executeVirtualOrders(uint256 blockNumber) external;
}

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File @rari-capital/solmate/src/utils/[email protected]

pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// File contracts/Pair.sol

// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm
// FrankieIsLost MVP code implementation: https://github.com/FrankieIsLost/TWAMM

pragma solidity ^0.8.9;

contract Pair is IPair, ERC20, ReentrancyGuard {
    using LongTermOrdersLib for LongTermOrdersLib.LongTermOrders;
    using BinarySearchTreeLib for BinarySearchTreeLib.Tree;
    using SafeERC20 for IERC20;
    using PRBMathUD60x18 for uint256;

    address public override factory;
    address public override tokenA;
    address public override tokenB;
    address private twamm;
    uint256 public override rootKLast;

    ///@notice fee for LP providers, 4 decimal places, i.e. 30 = 0.3%
    uint256 public constant LP_FEE = 30;

    ///@notice interval between blocks that are eligible for order expiry
    uint256 public constant orderBlockInterval = 5;

    ///@notice map token addresses to current amm reserves
    mapping(address => uint256) public override reserveMap;

    ///@notice data structure to handle long term orders
    LongTermOrdersLib.LongTermOrders internal longTermOrders;

    constructor(
        address _tokenA,
        address _tokenB,
        address _twamm
    ) ERC20("Pulsar-LP", "PUL-LP") {
        factory = msg.sender;
        tokenA = _tokenA;
        tokenB = _tokenB;
        twamm = _twamm;
        longTermOrders.initialize(
            tokenA,
            tokenB,
            twamm,
            block.number,
            orderBlockInterval
        );
    }

    ///@notice pair contract caller check
    modifier checkCaller() {
        require(msg.sender == twamm, "Invalid Caller");
        _;
    }

    ///@notice get tokenA reserves
    function tokenAReserves() public view override returns (uint256) {
        return reserveMap[tokenA];
    }

    ///@notice get tokenB reserves
    function tokenBReserves() public view override returns (uint256) {
        return reserveMap[tokenB];
    }

    ///@notice get LP total supply
    function getTotalSupply() public view override returns (uint256) {
        return totalSupply();
    }

    // if fee is on, mint liquidity equivalent to 1/(feeArg+1)th of the growth in sqrt(k)
    function mintFee(
        uint256 reserveA,
        uint256 reserveB
    ) private returns (bool feeOn) {
        uint32 feeArg = IFactory(factory).feeArg();
        address feeTo = IFactory(factory).feeTo();
        feeOn = feeTo != address(0);

        if (feeOn) {
            if (rootKLast != 0) {
                uint256 rootK = reserveA
                    .fromUint()
                    .sqrt()
                    .mul(reserveB.fromUint().sqrt())
                    .toUint();
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() * (rootK - rootKLast);
                    uint256 denominator = rootK * feeArg + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (rootKLast != 0) {
            rootKLast = 0;
        }
    }

    ///@notice provide initial liquidity to the amm. This sets the relative price between tokens
    function provideInitialLiquidity(
        address to,
        uint256 amountA,
        uint256 amountB
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 lpTokenAmount)
    {
        require(amountA > 0 && amountB > 0, "Invalid Amount");
        require(totalSupply() == 0, "Liquidity Has Already Been Provided");

        reserveMap[tokenA] = amountA;
        reserveMap[tokenB] = amountB;

        //initial LP amount is the geometric mean of supplied tokens
        lpTokenAmount = amountA
            .fromUint()
            .sqrt()
            .mul(amountB.fromUint().sqrt())
            .toUint();

        bool feeOn = mintFee(0, 0);
        _mint(to, lpTokenAmount);

        if (feeOn) rootKLast = lpTokenAmount;
        emit InitialLiquidityProvided(to, lpTokenAmount, amountA, amountB);
    }

    ///@notice provide liquidity to the AMM
    ///@param lpTokenAmount number of lp tokens to mint with new liquidity
    function provideLiquidity(
        address to,
        uint256 lpTokenAmount
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 amountAIn, uint256 amountBIn)
    {
        //execute virtual orders
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            block.number
        );

        require(lpTokenAmount > 0, "Invalid Amount");
        require(totalSupply() != 0, "No Liquidity Has Been Provided Yet");

        uint256 reserveA = reserveMap[tokenA];
        uint256 reserveB = reserveMap[tokenB];

        //the ratio between the number of underlying tokens and the number of lp tokens must remain invariant after mint
        amountAIn = (lpTokenAmount * reserveA) / totalSupply();
        amountBIn = (lpTokenAmount * reserveB) / totalSupply();

        reserveMap[tokenA] += amountAIn;
        reserveMap[tokenB] += amountBIn;

        bool feeOn = mintFee(reserveA, reserveB);
        _mint(to, lpTokenAmount);

        if (feeOn)
            rootKLast = reserveMap[tokenA]
                .fromUint()
                .sqrt()
                .mul(reserveMap[tokenB].fromUint().sqrt())
                .toUint();
        emit LiquidityProvided(to, lpTokenAmount, amountAIn, amountBIn);
    }

    ///@notice remove liquidity to the AMM
    ///@param lpTokenAmount number of lp tokens to burn
    function removeLiquidity(
        address to,
        uint256 lpTokenAmount
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 amountAOut, uint256 amountBOut)
    {
        //execute virtual orders
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            block.number
        );

        require(lpTokenAmount > 0, "Invalid Amount");
        require(
            lpTokenAmount <= totalSupply(),
            "Not Enough Lp Tokens Available"
        );

        uint256 reserveA = reserveMap[tokenA];
        uint256 reserveB = reserveMap[tokenB];

        //the ratio between the number of underlying tokens and the number of lp tokens must remain invariant after burn
        amountAOut = (reserveA * lpTokenAmount) / totalSupply();
        amountBOut = (reserveB * lpTokenAmount) / totalSupply();

        reserveMap[tokenA] -= amountAOut;
        reserveMap[tokenB] -= amountBOut;

        bool feeOn = mintFee(reserveA, reserveB);
        _burn(to, lpTokenAmount);

        IERC20(tokenA).safeTransfer(twamm, amountAOut);
        IERC20(tokenB).safeTransfer(twamm, amountBOut);

        if (feeOn)
            rootKLast = reserveMap[tokenA]
                .fromUint()
                .sqrt()
                .mul(reserveMap[tokenB].fromUint().sqrt())
                .toUint();
        emit LiquidityRemoved(to, lpTokenAmount, amountAOut, amountBOut);
    }

    ///@notice instant swap a given amount of tokenA against embedded amm
    function instantSwapFromAToB(
        address sender,
        uint256 amountAIn
    ) external override checkCaller nonReentrant returns (uint256 amountBOut) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountAIn > 0, "Invalid Amount");
        amountBOut = performInstantSwap(tokenA, tokenB, amountAIn);

        emit InstantSwapAToB(sender, amountAIn, amountBOut);
    }

    ///@notice create a long term order to swap from tokenA
    ///@param amountAIn total amount of token A to swap
    ///@param numberOfBlockIntervals number of block intervals over which to execute long term order
    function longTermSwapFromAToB(
        address sender,
        uint256 amountAIn,
        uint256 numberOfBlockIntervals
    ) external override checkCaller nonReentrant returns (uint256 orderId) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountAIn > 0, "Invalid Amount");
        orderId = longTermOrders.longTermSwapFromAToB(
            sender,
            amountAIn,
            numberOfBlockIntervals,
            reserveMap
        );

        emit LongTermSwapAToB(sender, amountAIn, orderId);
    }

    ///@notice instant swap a given amount of tokenB against embedded amm
    function instantSwapFromBToA(
        address sender,
        uint256 amountBIn
    ) external override checkCaller nonReentrant returns (uint256 amountAOut) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountBIn > 0, "Invalid Amount");
        amountAOut = performInstantSwap(tokenB, tokenA, amountBIn);

        emit InstantSwapBToA(sender, amountBIn, amountAOut);
    }

    ///@notice create a long term order to swap from tokenB
    ///@param amountBIn total amount of tokenB to swap
    ///@param numberOfBlockIntervals number of block intervals over which to execute long term order
    function longTermSwapFromBToA(
        address sender,
        uint256 amountBIn,
        uint256 numberOfBlockIntervals
    ) external override checkCaller nonReentrant returns (uint256 orderId) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountBIn > 0, "Invalid Amount");
        orderId = longTermOrders.longTermSwapFromBToA(
            sender,
            amountBIn,
            numberOfBlockIntervals,
            reserveMap
        );

        emit LongTermSwapBToA(sender, amountBIn, orderId);
    }

    ///@notice stop the execution of a long term order
    function cancelLongTermSwap(
        address sender,
        uint256 orderId
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 unsoldAmount, uint256 purchasedAmount)
    {
        (unsoldAmount, purchasedAmount) = longTermOrders.cancelLongTermSwap(
            sender,
            orderId,
            reserveMap
        );

        emit CancelLongTermOrder(
            sender,
            orderId,
            unsoldAmount,
            purchasedAmount
        );
    }

    ///@notice withdraw proceeds from a long term swap
    function withdrawProceedsFromLongTermSwap(
        address sender,
        uint256 orderId
    ) external override checkCaller nonReentrant returns (uint256 proceeds) {
        proceeds = longTermOrders.withdrawProceedsFromLongTermSwap(
            sender,
            orderId,
            reserveMap
        );

        emit WithdrawProceedsFromLongTermOrder(sender, orderId, proceeds);
    }

    ///@notice private function which implements instant swap logic
    function performInstantSwap(
        address from,
        address to,
        uint256 amountIn
    ) private checkCaller returns (uint256 amountOutMinusFee) {
        //execute virtual orders
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            block.number
        );

        uint256 reserveFrom = reserveMap[from];
        uint256 reserveTo = reserveMap[to];
        //constant product formula
        uint256 amountOut = (reserveTo * amountIn) / (reserveFrom + amountIn);

        //charge LP fee
        amountOutMinusFee = (amountOut * (10000 - LP_FEE)) / 10000;

        reserveMap[from] += amountIn;
        reserveMap[to] -= amountOutMinusFee;

        IERC20(to).safeTransfer(twamm, amountOutMinusFee);
    }

    ///@notice get pair orders total amount
    function getPairOrdersAmount() external view override returns (uint256) {
        return longTermOrders.orderId;
    }

    ///@notice get user order details
    function getOrderDetails(
        uint256 orderId
    ) external view override returns (LongTermOrdersLib.Order memory) {
        return longTermOrders.orderMap[orderId];
    }

    ///@notice returns the user order reward factor
    function getOrderRewardFactor(
        uint256 orderId
    )
        external
        view
        override
        returns (
            uint256 orderRewardFactorAtSubmission,
            uint256 orderRewardFactorAtExpiring
        )
    {
        address orderSellToken = longTermOrders.orderMap[orderId].sellTokenId;
        uint256 orderExpirationBlock = longTermOrders
            .orderMap[orderId]
            .expirationBlock;
        orderRewardFactorAtSubmission = longTermOrders
            .OrderPoolMap[orderSellToken]
            .rewardFactorAtSubmission[orderId];
        orderRewardFactorAtExpiring = longTermOrders
            .OrderPoolMap[orderSellToken]
            .rewardFactorAtBlock[orderExpirationBlock];
    }

    ///@notice returns the current state of the twamm
    function getTWAMMState()
        external
        view
        override
        returns (
            uint256 lastVirtualOrderBlock,
            uint256 tokenASalesRate,
            uint256 tokenBSalesRate,
            uint256 orderPoolARewardFactor,
            uint256 orderPoolBRewardFactor
        )
    {
        lastVirtualOrderBlock = longTermOrders.lastVirtualOrderBlock;
        tokenASalesRate = longTermOrders.OrderPoolMap[tokenA].currentSalesRate;
        tokenBSalesRate = longTermOrders.OrderPoolMap[tokenB].currentSalesRate;
        orderPoolARewardFactor = longTermOrders
            .OrderPoolMap[tokenA]
            .rewardFactor;
        orderPoolBRewardFactor = longTermOrders
            .OrderPoolMap[tokenB]
            .rewardFactor;
    }

    ///@notice returns cumulative sales rate of orders ending on this block number
    function getTWAMMSalesRateEnding(
        uint256 blockNumber
    )
        external
        view
        override
        returns (
            uint256 orderPoolASalesRateEnding,
            uint256 orderPoolBSalesRateEnding
        )
    {
        orderPoolASalesRateEnding = longTermOrders
            .OrderPoolMap[tokenA]
            .salesRateEndingPerBlock[blockNumber];
        orderPoolBSalesRateEnding = longTermOrders
            .OrderPoolMap[tokenB]
            .salesRateEndingPerBlock[blockNumber];
    }

    ///@notice returns expiries list since last executed
    function getExpiriesSinceLastExecuted()
        external
        view
        override
        returns (uint256[] memory)
    {
        return
            longTermOrders
                .expiryBlockTreeSinceLastExecution
                .getFutureExpiriesList();
    }

    ///@notice get user orderIds
    function userIdsCheck(
        address userAddress
    ) external view override returns (uint256[] memory) {
        return longTermOrders.orderIdMap[userAddress];
    }

    ///@notice get user order status based on Ids
    function orderIdStatusCheck(
        uint256 orderId
    ) external view override returns (bool) {
        return longTermOrders.orderIdStatusMap[orderId];
    }

    ///@notice convenience function to execute virtual orders. Note that this already happens
    ///before most interactions with the AMM
    function executeVirtualOrders(uint256 blockNumber) public override {
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            blockNumber
        );
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File contracts/Factory.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

contract Factory is IFactory, Initializable {
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    uint32 public override feeArg;
    address public override feeTo;
    address public override feeToSetter;
    address public override twammAdd;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function initialize(address _twammAdd) external override initializer {
        twammAdd = _twammAdd;
    }

    function createPair(
        address token0,
        address token1
    ) external override returns (address pair) {
        require(
            msg.sender == twammAdd,
            "Invalid User, Only TWAMM Can Create Pair"
        );
        require(twammAdd != address(0), "Factory Not Initialized By TWAMM Yet");
        require(token0 != token1, "Factory: Identical Addresses");

        (address tokenA, address tokenB) = token0 < token1
            ? (token0, token1)
            : (token1, token0);
        require(tokenA != address(0), "Factory: Zero Address");
        require(getPair[tokenA][tokenB] == address(0), "Factory: Pair Exists"); // single check is sufficient

        bytes memory bytecode = type(Pair).creationCode;
        bytes memory bytecodeArg = abi.encodePacked(
            bytecode,
            abi.encode(tokenA, tokenB, twammAdd)
        );
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecodeArg, 0x20), mload(bytecodeArg), salt)
        }
        require(pair != address(0), "Create2: Failed On Deploy");
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
    }

    function setFeeArg(uint32 _feeArg) external override {
        require(msg.sender == feeToSetter, "Factory: Forbidden");
        feeArg = _feeArg;
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "Factory: Forbidden");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "Factory: Forbidden");
        feeToSetter = _feeToSetter;
    }
}