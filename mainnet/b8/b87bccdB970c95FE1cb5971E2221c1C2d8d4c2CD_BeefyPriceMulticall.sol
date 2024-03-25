/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract BeefyPriceMulticall {

    function getUint(address addr, bytes memory data) internal view returns (uint result) {
        result = 0;

        assembly {
            let status := staticcall(16000, addr, add(data, 32), mload(data), 0, 0)

            if eq(status, 1) {
                if eq(returndatasize(), 32) {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
            }
        }
    }

    function getLpInfo(address[][] calldata pools) external view returns (uint[] memory) {
        uint[] memory results = new uint[](pools.length * 3);
        uint idx = 0;

        for (uint i = 0; i < pools.length; i++) {
            address lp = pools[i][0];
            address t0 = pools[i][1];
            address t1 = pools[i][2];

            results[idx++] = getUint(lp, abi.encodeWithSignature("totalSupply()"));
            results[idx++] = getUint(t0, abi.encodeWithSignature("balanceOf(address)", lp));
            results[idx++] = getUint(t1, abi.encodeWithSignature("balanceOf(address)", lp));
        }

        return results;
    }
}