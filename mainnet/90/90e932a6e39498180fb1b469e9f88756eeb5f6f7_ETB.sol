// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EthBoy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    :!?JYYYJJJ??77^                                                                                                             //
//                                              ^?PB#&&&&&&&#&###BP?^                                                             //
//                                            !P#&&###&#######BBGGB#B5:                                                           //
//                                           7#&######BBBBBB###BBGB##&G?YY555Y?7!^:..                                             //
//                                    :^^:::^G###BBBGGGP5555PPGGBBGB####&#########BBGPYJ7!^:.                                     //
//                                   :B#BBBBB#BBBP5YJY5YJ?77?JYY5BBBBBB#BBB##B############BGGP5555YYYYJ7^                         //
//                                    PBB#BBGBBBGJ!!!!!!7!!7?JJJYGBBBBB#BBBBGGGB###########BB#B#########G?:                       //
//                                    ~BB####BBB5!!??J?????JY5YYYPBGBBB###BBBBB############B#BBBB####BY777!~~:                    //
//                                     ::^^^~~YB?!YY555J7?55P555YJ55PB#######B######B##########B##BB#G!?!~!!!?                    //
//                                           .JY!~~!777~^?JJ????J?J5PPPB###########B##BB############BBPJ?77!~^                    //
//                                            :?7!!7??7?JYYJJ??JJ?Y55YYJYB###########BB#############B##G?J^.                      //
//                                           . :!77?J?!?Y555YYJJ?JPPYJYJ??P###BB############B##########J7!                        //
//                                    :~^~~~!!77??77!7!7?JYYJJJJJ5G5JJJJ?7!?G############B############P77.                        //
//                                    .^!!!!777?????7!!~!7JJJYY555PJJ7~!!~~!!B##B#BBB###BBB###B#######Y7^                         //
//                                    .~!!!!!!!!7777?777?JYYYYYYYJJ?7~~~!!!~?#####BB##BBB#B##BB######G77                          //
//                                     :~!!!~~~~~!!!77!!!!?JJYYJ?!~~~~~~~~!!?P###B###B###############Y7~                          //
//                                      .~!~!!!!!7!!7?77777?J?7!~!7!!!77!!!7775####################BG!7:                          //
//                                      ^J!~7777???!??7!7!77J?77??777777!77???P####################BJ!!                           //
//                                   :7YGG7!!!!777!!?7!!!!!!7J?7!7!7777!!!?Y?!!Y###################G!7~                           //
//                                  :?5GP5?~~!!!!~!!?7!~~~~!~!J?!~!77!!~~??J7777Y##################P!7~                           //
//                                 ^!?J7!~~^^~~~^~~~!!!~^^!~^^7?~^~!!!77JG5!7JYPBGB&###############5~7:                           //
//                               .~7?5Y^^~7!^^~^~!~^~!~^::~~^^~~~~~!!!7JYPP!~!!?5J?################Y!!                            //
//                               75PPBBJ7JJJY55~~~~!77Y5J!~!~!7?PY!~~!7?!J?~~~^~~J75###############J!~                            //
//                              ^7?JP5?7J5GB&#BY~!?JJYBBB5!~~7J5BBP?!?YY!!?Y!~~~!YPJ##############B7!.                            //
//                             :!~75Y!~!77YPPPPJ~7Y5PG#BBG?^7Y5PBBG57Y55Y?JG5!~!7YBPG#############P~^                             //
//                             !!!J7~~~~7YGPP5?~~~!77JPGP?^~!77?PGJ~~!?5J7JGGP775GB5P#############J!^                             //
//                            :77JG7~~~!JYJJ5J?~~~~~7JGY!^~!!!7?57~~!!7J?YJ777!!?J5!P############G77:                             //
//                            !5PBBY!!?5PY??7!!~!!~~!?J~!!!!!!7??7!7JY5PGGJ^~~~~!JJ!B############5!7.                             //
//                            !JGGY?7Y555?!~~~~~~~~~!JGY!77!!!777777?55Y?7755YJJ5Y!7B###########B?7^                              //
//                           .7757^~!!7!^^^~~~~~~~~~^!?777!!!!!7777777~~^~7PB##GY!~5############5!7                               //
//                           .?7JJ7!^~~~^~~~!!!!!!!~~!!!!!77!~!!7777!777??YYY55J!!J############B77~                               //
//                            :??YGPJ7~~~~~!!!!!!~~~~!!!!~~~!!7!!!!!!?55?!!!!77JYP####B########Y77                                //
//                   ..:^~~!!7?YY7JBP~~!!!7~~~7~~~~~!!~!?7~~~777!!777JPJJJJJYY?5#####BB#######B7?~                                //
//               :75PGBBB#&##&&##G55?^~!!!!~~!7!~~~~!777?7~~~^~77!!7?JY?GBPYJ!^!#############BJ!?.                                //
//             .?B&&#&&##########&B!~~~!!!!!!!!??77??JYJ7!!!!!~??7!!!??JG#&&G7~7B###########BJ!!.                                 //
//            7B#########&#########BB5777!!!!!~~7JJ!!7JJ???JJYYJJ?JYJJJ555PPG?~JG##########BJ7!.                                  //
//           7&#####B##&############&&##G!~~!~~~7YJ?7YJ?J???J5BP??JBBP!!777YG!~7J5B########Y77.                                   //
//           5&####&#&#########BB###&#&&#GY!!7?GPJ???PB5!~~!JPBPJJPB#5^^~!7YY~~~~!Y#######G77:                                    //
//           Y######&###&###B#BBB####&&&&&&#B##&#YJ5GB##G?~~75GPJYYYY?^^^^~??^^~~!!5#B####J7~                                     //
//           Y####&&&##############BB####&&&&&&##P?JYGBBG?^!7?5Y??!~7~^~~^^!J7~~~!!JBB##BG7?:                                     //
//           7BB#####&############&#######&##&&##G?77?GP7^^^~!Y7?J7!?5!~~^^!JGY7~~!JBP5J7777                                      //
//          :77?JYPGBB##&&##&####&&#&&#######&&&&BJ!!?5!^^^^^~?~?J77?GP7~~~7YBBBP?!??77777?!                                      //
//          .!?!77!!7?JY5PBBB############&&&&&&&##5?~7J~~^^^~!Y5?J?YGB#5!~75GGB##57?J7?77?7.                                      //
//           :?!!!7!!7!!7!!??J5PGGB######&&&&&&&&&GJ!75P?~^~?YG#GYJY55G5!~!????YP7~77777!?:                                       //
//           .7!!!!!!!!!7777!!!!!!7?JY5PGB##&&&&#B5?77YBGJ!YPGGBBPJ77JP7~~~~!775J~~!7!7!!?:                                       //
//            ~777777!~~~!~~!!!7777!!7!!!??JJYYJ?!7JJ5B#B5!!7?JP5JY?!7?~~~~^^~7J~~~~!!!!!7~                                       //
//            !?77???7777!!!~~~~~!!777?77??7!7!?7777YYYPP?~^^~?5?J5Y7!YJ~~~~^^7J~~~!!!!!!!!                                       //
//            !7777????7?7!77!!!!!~~~!!!!777J7?!!!!~!7?GY7!~^~!Y?JY5??PBJ~~~~!?GY~~!!!!~!!7.                                      //
//           .7!!777??7?7?77?7!77??77!!!!77J!~77!77777JPJ7!!!7?PB5Y55PB#BY!~!J5BBP777!7!!!?.                                      //
//            ~7!!!!!!7!!7!777!!!!!!7777??YJ??JJJJ?J???5G5?7YPG#&B5J5YPBGP7~!7JGBY!7!77!!!~                                       //
//             ~?77!7!!!7!7!77!~!!!~!7!!7??7JYYJ??J?7?!!YG5?JJYPPY??YYJPG?~~!775GY~~!!!!!!!.                                      //
//             :7!7!77!77777!!!~!!~~!!~~7777JJ?????7!7!!!?YJ7!!!?!7YY5JP?!!~~!!75!~~!7!!!!7^                                      //
//             :?77!~!!!!!!7!7!!!77!!~!!7?777!?!!!!!!7!777J5J7!~!7?5GGYJJ!!~~~~!Y~~~!777??7~                                      //
//              7777!7!!!!!!~~~~!~~!!!77??!7!!?7!!!!!!7?7!!JGPJ7!??5BGY?G57~~!7?GY~~!7???7!.                                      //
//              ^?!!77?777?!!!~~~~~~~~!7?7!!~!!7!7!!!7??!777?5GPJ?77?7!7JYJ?!~!!?J7!!~!7!!!.                                      //
//              .J77??7..:^~!^^!7!!77!!7?!!!!!~7!77!?7!J77?7!.?7!!!!~~!77!755!^~^^7PJ. .~~^.                                      //
//              ^?7!!7:         .:~!!7?7?7!7?!!?7!7J?77P?7?!::7!~!!!!!!7?7JG#G7~~7755                                             //
//              .?!!!7               .^!??77J7!7?7?Y?!^!^..  :!!!!!777!^77JY55Y!!?7J?.                                            //
//               ~?7?!                  ~?!??!!?77J~.       .~!!7!!!!!!.7!!!!!!!!!!!!!^.                                          //
//               .77J~                   ^?J!!77!J!         :!~!!!!!!!~.~!!7!!!!!77!!!!~:                                         //
//               ^!77:                    .?777!!J.           .^^^::.    .:~~~!!!7!!!!!!~^.                                       //
//                                         :7!77!:                            ..^~!!777!~~.                                       //
//                                          ^J?J!                                 .::^^:.                                         //
//                                          :J77J:                                                                                //
//                                           ~??7.                                                                                //
//                                            ..                                                                                  //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETB is ERC721Creator {
    constructor() ERC721Creator("EthBoy", "ETB") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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