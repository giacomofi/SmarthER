// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Old God's Fossils
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//    ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────    //
//    ─██████████████─██████─────────████████████──────██████████████─██████████████─████████████───██████─██████████████─    //
//    ─██░░░░░░░░░░██─██░░██─────────██░░░░░░░░████────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████─██░░██─██░░░░░░░░░░██─    //
//    ─██░░██████░░██─██░░██─────────██░░████░░░░██────██░░██████████─██░░██████░░██─██░░████░░░░██─██████─██░░██████████─    //
//    ─██░░██──██░░██─██░░██─────────██░░██──██░░██────██░░██─────────██░░██──██░░██─██░░██──██░░██─────██─██░░██─────────    //
//    ─██░░██──██░░██─██░░██─────────██░░██──██░░██────██░░██─────────██░░██──██░░██─██░░██──██░░██────────██░░██████████─    //
//    ─██░░██──██░░██─██░░██─────────██░░██──██░░██────██░░██──██████─██░░██──██░░██─██░░██──██░░██────────██░░░░░░░░░░██─    //
//    ─██░░██──██░░██─██░░██─────────██░░██──██░░██────██░░██──██░░██─██░░██──██░░██─██░░██──██░░██────────██████████░░██─    //
//    ─██░░██──██░░██─██░░██─────────██░░██──██░░██────██░░██──██░░██─██░░██──██░░██─██░░██──██░░██────────────────██░░██─    //
//    ─██░░██████░░██─██░░██████████─██░░████░░░░██────██░░██████░░██─██░░██████░░██─██░░████░░░░██────────██████████░░██─    //
//    ─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░████────────██░░░░░░░░░░██─    //
//    ─██████████████─██████████████─████████████──────██████████████─██████████████─████████████──────────██████████████─    //
//    ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────    //
//            ──────────────────────────────────────────────────────────────────────────────────────────────────────          //
//            ─██████████████─██████████████─██████████████─██████████████─██████████─██████─────────██████████████─          //
//            ─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░██─██░░██─────────██░░░░░░░░░░██─          //
//            ─██░░██████████─██░░██████░░██─██░░██████████─██░░██████████─████░░████─██░░██─────────██░░██████████─          //
//            ─██░░██─────────██░░██──██░░██─██░░██─────────██░░██───────────██░░██───██░░██─────────██░░██─────────          //
//            ─██░░██████████─██░░██──██░░██─██░░██████████─██░░██████████───██░░██───██░░██─────────██░░██████████─          //
//            ─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██───██░░██───██░░██─────────██░░░░░░░░░░██─          //
//            ─██░░██████████─██░░██──██░░██─██████████░░██─██████████░░██───██░░██───██░░██─────────██████████░░██─          //
//            ─██░░██─────────██░░██──██░░██─────────██░░██─────────██░░██───██░░██───██░░██─────────────────██░░██─          //
//            ─██░░██─────────██░░██████░░██─██████████░░██─██████████░░██─████░░████─██░░██████████─██████████░░██─          //
//            ─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─          //
//            ─██████─────────██████████████─██████████████─██████████████─██████████─██████████████─██████████████─          //
//            ──────────────────────────────────────────────────────────────────────────────────────────────────────          //
//                                                                                                                            //
//            @@@@G!^!?7??5Y!:::~~!~~?YY5YYG####BGPPBBBB####&&###&&&#####BBBGPPGGB#BBBBPYYPPJ?!!!^:::::^^:^YB#####            //
//            &@#7.:^~?J?7^::^~!~!7J55Y5PGGGP5P5PGBGB##BPY5PGGGGGGGPP5PPPGPPPPPPGPPGBB#BGPPPPG5J77!^:.:^~~^:~5####            //
//            &G^.:.::^^...^!7!7?YY555GBG55YPP55PGBBGPPY5PPGGBB##BBBBBBGGGGGGPPPPPPP555PGGBGPYY5J?!77~^^:^~!~:!G#B            //
//            ?....::^...:~!!77JYJJ5PGPYYYPGY??J55YJ?77?Y5PPPPPPGGBBB##########BP555PPP555PGGP5Y5PPY7!~~^:^^77^^5#            //
//            ::::::::::^~!~!?JJJ5GPY77YPPP5Y55YYJ??JYPGGBBB##########BBBBB#######BP555555Y55PPP5JJ55?!!!^:^^^!^^Y            //
//            ^^:^^:..^~~~!7J?J5PPJ!?Y55YJJY55Y555PGB###############B######BBGGB##BBBG5JYYYYY5P5YJJJY5Y777!^:^~~^^            //
//            ~:^^:::^!?77?55Y5YJ77J55YJJYPG5YYPGB###BB###BBBB###BB##############BGGBBGGYJJ?JJJY5PY?7?YJ7!~~::~!!~            //
//            ^~~^~^~!7!7?YJ5PY?77JJ?77J55Y?J5GB##BBBB#########################BBBBGPPPPPP5J??Y5JJYYJ??J5?7??7?77?            //
//            ~~^~^~!7???JYYYY7?YYJ???Y5J77YGBGPGPGGBBBBB###########BBBBBBB####BGGGPPP5P5PGPYJ?YJJJYYYJYP55Y?7!!!7            //
//            7~~:~7!!!7??JP?7J55??YYYJ77J5PPPPP5GBGGGB###################BBBBBBBBGP55P55Y555YJ7??77?YYYY5JJJJ?7?!            //
//            !!!777!?JYJ?YJ77J5??JY5YJJY5GP5YJPGGPGB########BBBBGGGGPGBBBB##BGPPPPP5555YYJYYYJ?7??7?J?77J5YJJJ77!            //
//            !7!!77JYYYJJY?77???JJYY?JYPGPPPPPPPGGBBBGGBBGBBGGGGGGP5Y5PPPPPPPGP555P55YYYYYJY5J777?7777777?J??77~!            //
//            7!77?7JJ??JJYYYYY??JJY??Y5P5Y5PGGPGPPPPPPPGGGGGGGGGGGPPP555555Y55PP5Y5P55YJYYJ?JJ?7!7!!!77!!!??!7777            //
//            7!7?J?J?J?JY7~?YY?JY5Y?JY55J5YY5Y55555555PP55PGPGPP55PP5YYYYYJ?Y5Y5J?JY5YYJJYJ777?7!!!!77!?!~!77!??7            //
//            7!777J??Y??Y?!7JJJYY5Y?JYYJJJYYJJJJYJJJY55YYYY5Y555JJPP5YJ?YYYJ7J?JYJJ?JJJ?7JJJJ?J7!!777777!~!??7?J?            //
//            !?Y??JJJJ?JY?Y5YJY5YYJ7?YJ?JJJJ?JJ?J??JJYJJYJYJYJJJJY5YYJ??YJ?JYY??J????J?J77777777!!!7!!??!7??JJJYY            //
//            J?YJYYJJ?J55JJ5YYYYY5YJYYJJ??J???????JYY5JJJJYYYYJ?7?YJYJJ??JJY?7777????7??!~7!~!7?!~!!~!!7!!777?JY?            //
//            5JYYJY?J??7?77?JJYJJ5JJJY?7?JJJ???J?7?YJYJ?JJJJJJJ?7JJYJ~~7?JJJ7~7?!7!7!!!^^^!!!!77~~~!!~~!!!?!?7JY7            //
//            ?YYYYYY5YJ?J7!7!~77?YJ7?J?7?7?J7!!7??777??77??JJJ?7YYY?J7!77?J?7!77!~~^!!~^^^!!!!!~~~~!!~~!7?!:!?JYJ            //
//            JY55YYYYYYJJ?77!!?!!JY????!~~~77!~~!7?!77??777?7J??J?????!77!!~~!7!!~^^^^^:^!!~~!!!~~!7!!!!!7~^!?5Y?            //
//            55YJJJYJY?JJ?7?J?77!77?!777!~~!!~^^^~77!~~!!!7!?J??!!???7~!~~~!7!!~^^^^:::^!~^~!7~!~~!!~~!!!!~~7J5?!            //
//            JPP55JYJJ????7~~!77!7???7777!^:^!77!~^~~!!!~!!!!!7!!!~~~^^^~!7!!~^^^^^^^~!7!^~!77!~~~!!^~!~7~:!?YJ7J            //
//            ?YPGP5YJ??7!!77!7J?77?7!!!!!!~77!~!!~~~~!7777!7?7!~~~~~~~!~~^^^:::^^^^^^~7~^~!~~!~^~!!~^!!!!~7J55??7            //
//            ?JPGBPY????7JJJ7!?JJ!!!!~~~!~7!~~^~!7!77!~^~~!!!~~!~~^~~~~^^^::::::::~~!!^^~~~~~^~~~~~^!!!!!?Y55YYYY            //
//            ?!JPGPPY???YJ?JJ!7???7~7?7~~~~~!7!~^~~~!!7!~77^^^^^~^^^^^^:::::::::^^~~!~^^^~^^^~!~^^~~!7!7?JYYJYJ7^            //
//            777?5PGPPY??J?7?77?7?J?~!77!~~~~!7!!~~^^^^^~~~^^^!~^:^^:::::::::^^~~^^^^^^^^^^~~~~~^~~!!77??Y5Y?!~::            //
//            ~JJ?JYGP5PYJJJ??77J?77??7~~!!~~~^~~~!!7!~~^^^^^^^^:::^^^::^^^~~!~~^^^^^^^^^^^~!!~!~~~~7???J5PJ777~~!            //
//            ^:7YJ?YPP5PPYYYYJJJJJJ77J?7~^~~!~^^~~~~^^~!777!7~~~~^~^^~~~~^^~!~~!!^:::^^^^^^~^!!!!!?JJJ5YJ?77!^^!Y            //
//            G?:!YYJ5BBBBPY555JJJ?YJJ77??!!~^^~~~^^^^^^~!~!!7!!!~~!~~~~~^^^!~!~~^::^~~~^^^^^~!!7???JY55YJJ?~~~7Y5            //
//            G57^^7JYYPGBBGP555JJJ???!7!!77!~~^:^^^^^^^^^~~!!!!!~!~^^^^^^!7~^^:^~~!!!~^^^^~^~~!?JJJYYYJJ?7~~?JP5Y            //
//            #B5?~:^!JY5GB#BG5YYYJJJ7!~77!!77!!7??!!~!~~!~~~~^^~~~^^^^~~^^~~~~~!~~!7!^~~~~~~~!7?J55YY??~~!!7YP5Y5            //
//            &&#B5J7^^!?YPB#BBGPYYYJ???7??7!?77!!!!!~~~!7~!!~!!~~~~!~!!!!!~~!!!~^~!7!~~~~7!!7JJY5YJJJ?7!~7JY55P#@            //
//            &&&&#BPY7^^!?YPB##BBGPYYJJ???777J?77~^^^~~^~~~~!~~~~~~!~~^~!~!^^~~^~!~^^!77??7?Y5P55J7!~^[email protected]@@            //
//            &&&@@&&#G5J!~7?J5B####BG55Y?JJ?7777!!!!~!!!77!77!!!!!~!~~!!~~~!~~~~!!!!7????JY5PPPY7~~^~~7J5GBG#@@@@            //
//            &&@@@@@@&#G5J7!!77YPB####BP5YJ?J?7?7!7???77?77??!77!~!77!!!!7!!!~!!?????JY55PP5?!!~~~!~!JPB###@@@@@@            //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OGFOSSIL is ERC721Creator {
    constructor() ERC721Creator("Old God's Fossils", "OGFOSSIL") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}