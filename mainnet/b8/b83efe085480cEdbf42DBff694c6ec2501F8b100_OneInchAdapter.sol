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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMintGateway} from "../../Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "../../Gateways/interfaces/ILockGateway.sol";

abstract contract IGatewayRegistry {
    function signatureVerifier() external view virtual returns (address);

    function chainId() external view virtual returns (uint256);

    function chainName() external view virtual returns (string memory);

    function getMintGatewaySymbols(uint256 from, uint256 count) external view virtual returns (string[] memory);

    function getLockGatewaySymbols(uint256 from, uint256 count) external view virtual returns (string[] memory);

    function getMintGatewayByToken(address token) external view virtual returns (IMintGateway);

    function getMintGatewayBySymbol(string calldata tokenSymbol) external view virtual returns (IMintGateway);

    function getRenAssetBySymbol(string calldata tokenSymbol) external view virtual returns (IERC20);

    function getLockGatewayByToken(address token) external view virtual returns (ILockGateway);

    function getLockGatewayBySymbol(string calldata tokenSymbol) external view virtual returns (ILockGateway);

    function getLockAssetBySymbol(string calldata tokenSymbol) external view virtual returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

abstract contract ILockGateway {
    event LogRelease(address indexed recipient, uint256 amount, bytes32 indexed sigHash, bytes32 indexed nHash);
    event LogLockToChain(
        string recipientAddress,
        string recipientChain,
        bytes recipientPayload,
        uint256 amount,
        uint256 indexed lockNonce,
        // Indexed versions of previous parameters.
        string indexed recipientAddressIndexed,
        string indexed recipientChainIndexed
    );

    function lock(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external virtual returns (uint256);

    function release(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

abstract contract IMintGateway {
    /// @dev For backwards compatiblity reasons, the sigHash is cast to a
    /// uint256.
    event LogMint(address indexed to, uint256 amount, uint256 indexed sigHash, bytes32 indexed nHash);

    /// @dev Once `LogBurnToChain` is enabled on mainnet, LogBurn may be
    /// replaced by LogBurnToChain with empty payload and chain fields.
    /// @dev For backwards compatibility, `to` is bytes instead of a string.
    event LogBurn(
        bytes to,
        uint256 amount,
        uint256 indexed burnNonce,
        // Indexed versions of previous parameters.
        bytes indexed indexedTo
    );
    event LogBurnToChain(
        string recipientAddress,
        string recipientChain,
        bytes recipientPayload,
        uint256 amount,
        uint256 indexed burnNonce,
        // Indexed versions of previous parameters.
        string indexed recipientAddressIndexed,
        string indexed recipientChainIndexed
    );

    function mint(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external virtual returns (uint256);

    function burnWithPayload(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external virtual returns (uint256);

    function burn(string calldata recipient, uint256 amount) external virtual returns (uint256);

    function burn(bytes calldata recipient, uint256 amount) external virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGatewayRegistry} from "@renproject/gateway-sol/src/GatewayRegistry/interfaces/IGatewayRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Payment, FEE_CURRENCY} from "./libraries/Payment.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

interface OneInch {
    function swap(
        address caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256);

    function unoswap(
        IERC20 srcToken,
        uint256 _amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount);

    function clipperSwapTo(
        address payable recipient,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount);
}

contract OneInchAdapter is Context, Payment {
    using SafeERC20 for IERC20;

    OneInch public oneInch;

    constructor(OneInch oneInch_) {
        oneInch = oneInch_;
    }

    function swap(
        address caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) public payable returns (uint256) {
        uint256 amount;
        if (address(desc.srcToken) == FEE_CURRENCY) {
            amount = msg.value;
        } else {
            amount = desc.srcToken.allowance(_msgSender(), address(this));
            desc.srcToken.safeApprove(address(oneInch), amount);
        }
        acceptPayment(address(desc.srcToken), amount);

        return
            oneInch.swap{value: msg.value}(
                caller,
                SwapDescription({
                    srcToken: desc.srcToken,
                    dstToken: desc.dstToken,
                    srcReceiver: desc.srcReceiver,
                    dstReceiver: desc.dstReceiver == address(0x0)
                        ? payable(_msgSender())
                        : desc.dstReceiver,
                    amount: amount,
                    minReturnAmount: desc.minReturnAmount,
                    flags: desc.flags,
                    permit: desc.permit
                }),
                data
            );
    }

    function unoswap(
        IERC20 srcToken,
        uint256 _amount,
        uint256 minReturn,
        bytes32[] calldata pools,
        IERC20 dstToken
    ) public payable returns (uint256) {
        uint256 approvedAmount;
        if (
            address(srcToken) == FEE_CURRENCY ||
            address(srcToken) == address(0x0)
        ) {
            approvedAmount = msg.value;
        } else {
            approvedAmount = srcToken.allowance(_msgSender(), address(this));
            srcToken.safeApprove(address(oneInch), approvedAmount);
        }
        acceptPayment(address(srcToken), approvedAmount);

        uint256 returnedAmount = oneInch.unoswap(
            srcToken,
            approvedAmount,
            minReturn,
            pools
        );

        dstToken.safeTransfer(_msgSender(), returnedAmount);
        return returnedAmount;
    }

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        IERC20 srcToken
    ) external payable returns (uint256) {
        return
            uniswapV3SwapTo(
                payable(_msgSender()),
                amount,
                minReturn,
                pools,
                srcToken
            );
    }

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        IERC20 srcToken
    ) public payable returns (uint256) {
        uint256 approvedAmount;
        if (
            address(srcToken) == FEE_CURRENCY ||
            address(srcToken) == address(0x0)
        ) {
            approvedAmount = msg.value;
        } else {
            approvedAmount = srcToken.allowance(_msgSender(), address(this));
            srcToken.safeApprove(address(oneInch), approvedAmount);
        }
        acceptPayment(address(srcToken), approvedAmount);

        return oneInch.uniswapV3SwapTo(recipient, amount, minReturn, pools);
    }

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256) {
        return
            clipperSwapTo(
                payable(_msgSender()),
                srcToken,
                dstToken,
                amount,
                minReturn
            );
    }

    function clipperSwapTo(
        address payable recipient,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 _amount,
        uint256 minReturn
    ) public payable returns (uint256) {
        uint256 approvedAmount;
        if (
            address(srcToken) == FEE_CURRENCY ||
            address(srcToken) == address(0x0)
        ) {
            approvedAmount = msg.value;
        } else {
            approvedAmount = srcToken.allowance(_msgSender(), address(this));
            srcToken.safeApprove(address(oneInch), approvedAmount);
        }
        acceptPayment(address(srcToken), approvedAmount);

        return
            oneInch.clipperSwapTo(
                recipient,
                srcToken,
                dstToken,
                approvedAmount,
                minReturn
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

address constant FEE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract Payment is Context {
    using SafeERC20 for IERC20;

    function acceptPayment(address token, uint256 amount) internal {
        if (token == FEE_CURRENCY || token == address(0x0)) {
            require(msg.value == amount, "Payment: insufficient msg.value");
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        }
    }

    function payToken(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (token == FEE_CURRENCY || token == address(0x0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}