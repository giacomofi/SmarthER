//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./VixenParts.sol";

contract Vixen {
    function viewVixen() public pure returns (string memory) {
        return string(abi.encodePacked(Vixen_1.getVixen(), Vixen_2.getVixen()));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
library Vixen_1 {
    string public constant Vixen = "7f454c4602010100000000000000000003003e000100000000130000000000004000000000000000803600000000000000000000400038000d0040001d001c000600000004000000400000000000000040000000000000004000000000000000d802000000000000d802000000000000080000000000000003000000040000001803000000000000180300000000000018030000000000001c000000000000001c0000000000000001000000000000000100000004000000000000000000000000000000000000000000000000000000100c000000000000100c00000000000000100000000000000100000005000000001000000000000000100000000000000010000000000000610f000000000000610f000000000000001000000000000001000000040000000020000000000000002000000000000000200000000000008402000000000000840200000000000000100000000000000100000006000000102d000000000000103d000000000000103d0000000000003608000000000000980900000000000000100000000000000200000006000000202d000000000000203d000000000000203d000000000000f001000000000000f00100000000000008000000000000000400000004000000380300000000000038030000000000003803000000000000300000000000000030000000000000000800000000000000040000000400000068030000000000006803000000000000680300000000000044000000000000004400000000000000040000000000000053e574640400000038030000000000003803000000000000380300000000000030000000000000003000000000000000080000000000000050e574640400000058200000000000005820000000000000582000000000000074000000000000007400000000000000040000000000000051e574640600000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000052e5746404000000102d000000000000103d000000000000103d000000000000f002000000000000f00200000000000001000000000000002f6c696236342f6c642d6c696e75782d7838362d36342e736f2e320000000000040000002000000005000000474e5500020000c0040000000300000000000000028000c0040000000100000000000000040000001400000003000000474e550027cf9e5cc2b1a63d50a5f22562bcacde8271e477040000001000000001000000474e55000000000003000000020000000000000000000000030000001b000000010000000600000030018100c00040021b0000001e00000000000000c4890590a6dda36bd165ce6dc4b99c4039f28b1c0000000000000000000000000000000000000000000000005900000012000000000000000000000000000000000000002300000012000000000000000000000000000000000000009300000012000000000000000000000000000000000000003201000020000000000000000000000000000000000000001700000012000000000000000000000000000000000000004b0000001200000000000000000000000000000000000000c00000001200000000000000000000000000000000000000440000001200000000000000000000000000000000000000600000001200000000000000000000000000000000000000d100000012000000000000000000000000000000000000003d00000012000000000000000000000000000000000000008400000012000000000000000000000000000000000000003500000012000000000000000000000000000000000000004e01000020000000000000000000000000000000000000001e00000012000000000000000000000000000000000000007d0000001200000000000000000000000000000000000000d80000001200000000000000000000000000000000000000100000001200000000000000000000000000000000000000a900000012000000000000000000000000000000000000006f0000001200000000000000000000000000000000000000670000001200000000000000000000000000000000000000a40000001200000000000000000000000000000000000000b900000012000000000000000000000000000000000000005d01000020000000000000000000000000000000000000005200000012000000000000000000000000000000000000008a0000001200000000000000000000000000000000000000de00000021001a0060450000000000000800000000000000df00000021001a0060450000000000000800000000000000010000002200000000000000000000000000000000000000dd00000011001a00604500000000000008000000000000007600000011001a0080450000000000000800000000000000005f5f6378615f66696e616c697a65006d616c6c6f63006765747069640073746174005f5f6c6962635f73746172745f6d61696e00667072696e746600707574656e76006d656d736574007374726c656e0073747264757000676574656e76006d656d636d7000737072696e74660065786563767000737464657272006d656d6370790061746f6c6c007374726572726f72005f5f6572726e6f5f6c6f636174696f6e0065786974005f5f69736f6339395f737363616e6600667772697465005f5f737461636b5f63686b5f6661696c0063616c6c6f630074696d65005f5f656e7669726f6e006c6962632e736f2e3600474c4942435f322e3700474c4942435f322e313400474c4942435f322e333300474c4942435f322e3400474c4942435f322e333400474c4942435f322e322e35005f49544d5f64657265676973746572544d436c6f6e655461626c65005f5f676d6f6e5f73746172745f5f005f49544d5f7265676973746572544d436c6f6e655461626c6500000000020003000200010002000200040002000200020002000200020001000500060002000200070002000200020002000100020002000200020002000200020001000600e700000010000000000000001769690d00000700f1000000100000009491960600000600fb00000010000000b39196060000050006010000100000001469690d000004001101000010000000b4919606000003001b01000010000000751a6909000002002601000000000000103d0000000000000800000000000000e013000000000000183d0000000000000800000000000000a013000000000000084000000000000008000000000000000840000000000000d83f00000000000006000000020000000000000000000000e03f00000000000006000000040000000000000000000000e83f000000000000060000000e0000000000000000000000f03f00000000000006000000180000000000000000000000f83f000000000000060000001d00000000000000000000006045000000000000050000001e00000000000000000000008045000000000000050000001f0000000000000000000000283f00000000000007000000010000000000000000000000303f00000000000007000000030000000000000000000000383f00000000000007000000050000000000000000000000403f00000000000007000000060000000000000000000000483f00000000000007000000070000000000000000000000503f00000000000007000000080000000000000000000000583f00000000000007000000090000000000000000000000603f000000000000070000000a0000000000000000000000683f000000000000070000000b0000000000000000000000703f000000000000070000000c0000000000000000000000783f000000000000070000000d0000000000000000000000803f000000000000070000000f0000000000000000000000883f00000000000007000000100000000000000000000000903f00000000000007000000110000000000000000000000983f00000000000007000000120000000000000000000000a03f00000000000007000000130000000000000000000000a83f00000000000007000000140000000000000000000000b03f00000000000007000000150000000000000000000000b83f00000000000007000000160000000000000000000000c03f00000000000007000000170000000000000000000000c83f00000000000007000000190000000000000000000000d03f000000000000070000001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f30f1efa4883ec08488b05d92f00004885c07402ffd04883c408c30000000000ff35f22e0000f2ff25f32e00000f1f00f30f1efa6800000000f2e9e1ffffff90f30f1efa6801000000f2e9d1ffffff90f30f1efa6802000000f2e9c1ffffff90f30f1efa6803000000f2e9b1ffffff90f30f1efa6804000000f2e9a1ffffff90f30f1efa6805000000f2e991ffffff90f30f1efa6806000000f2e981ffffff90f30f1efa6807000000f2e971ffffff90f30f1efa6808000000f2e961ffffff90f30f1efa6809000000f2e951ffffff90f30f1efa680a000000f2e941ffffff90f30f1efa680b000000f2e931ffffff90f30f1efa680c000000f2e921ffffff90f30f1efa680d000000f2e911ffffff90f30f1efa680e000000f2e901ffffff90f30f1efa680f000000f2e9f1feffff90f30f1efa6810000000f2e9e1feffff90f30f1efa6811000000f2e9d1feffff90f30f1efa6812000000f2e9c1feffff90f30f1efa6813000000f2e9b1feffff90f30f1efa6814000000f2e9a1feffff90f30f1efa6815000000f2e991feffff90f30f1efaf2ff255d2e00000f1f440000f30f1efaf2ff257d2d00000f1f440000f30f1efaf2ff25752d00000f1f440000f30f1efaf2ff256d2d00000f1f440000f30f1efaf2ff25652d00000f1f440000f30f1efaf2ff255d2d00000f1f440000f30f1efaf2ff25552d00000f1f440000f30f1efaf2ff254d2d00000f1f440000f30f1efaf2ff25452d00000f1f440000f30f1efaf2ff253d2d00000f1f440000f30f1efaf2ff25352d00000f1f440000f30f1efaf2ff252d2d00000f1f440000f30f1efaf2ff25252d00000f1f440000f30f1efaf2ff251d2d00000f1f440000f30f1efaf2ff25152d00000f1f440000f30f1efaf2ff250d2d00000f1f440000f30f1efaf2ff25052d00000f1f440000f30f1efaf2ff25fd2c00000f1f440000f30f1efaf2ff25f52c00000f1f440000f30f1efaf2ff25ed2c00000f1f440000f30f1efaf2ff25e52c00000f1f440000f30f1efaf2ff25dd2c00000f1f440000f30f1efaf2ff25d52c00000f1f440000f30f1efa31ed4989d15e4889e24883e4f050544531c031c9488d3d690b0000ff15b32c0000f4662e0f1f840000000000488d3d11320000488d050a3200004839f87415488b05962c00004885c07409ffe00f1f8000000000c30f1f8000000000488d3de1310000488d35da3100004829fe4889f048c1ee3f48c1f8034801c648d1fe7414488b05652c00004885c07408ffe0660f1f440000c30f1f8000000000f30f1efa803ddd31000000752b5548833d422c0000004889e5740c488b3d462c0000e8c9fdffffe864ffffffc605b5310000015dc30f1f00c30f1f8000000000f30f1efae977fffffff30f1efa554889e5c605aa320000000fb605a332000088059c3200000fb6059532000088058e3200000fb605873200000fb6c00fb6157d3200004898488d0d743100008814080fb6056a32000083c0018805613200000fb6055a32000084c075c890905dc3f30f1efa554889e548897de88975e4488b45e8488945f8e9cf0000000fb6052f3200000fb6c04898488d15233100000fb604108845f70fb615173200000fb645f701d088050b3200000fb605023200000fb6c099f77de489d04863d0488b45f84801d00fb6100fb605e731000001d08805df3100000fb605d83100000fb6c00fb615cc3100000fb6ca4898488d15c03000000fb614104863c1488d0db23000008814080fb605aa3100000fb6c04898488d0d9c3000000fb655f78814080fb6058e31000083c0018805853100000fb6057e31000084c00f8540ffffff488145f800010000816de400010000837de4000f8f27ffffff90905dc3f30f1efa554889e548897de88975e4488b45e8488945f8e9ca0000000fb6053631000083c00188052d3100000fb605263100000fb6c04898488d151a3000000fb604108845f70fb6150d3100000fb645f701d08805013100000fb605fa3000000fb6c00fb615ef3000000fb6ca4898488d15e32f00000fb614104863c1488d0dd52f00008814080fb605cc3000000fb6c04898488d0dbf2f00000fb655f78814080fb605b13000000fb6c04898488d15a52f00000fb604100045f7488b45f80fb6080fb645f74898488d158a2f00000fb6041031c189ca488b45f88810488345f801836de401837de4000f8f2cffffff90905dc3f30f1efa554889e54881ec400100004889bdc8feffff64488b042528000000488945f831c0488d95d0feffff488b85c8feffff4889d64889c7e8d7fbffff85c0790ab8ffffffffe98f000000488d8560ffffffba90000000be000000004889c7e850fbffff488b85d8feffff48898568ffffff488b85d0feffff48898560ffffff488b85f8feffff488945888b85ecfeffff89857cffffff8b85f0feffff894580488b8500ffffff48894590488b8528ffffff488945b8488b8538ffffff488945c8488d8560ffffffbe900000004889c7e83dfdffffb800000000488b55f864482b1425280000007405e8b6faffffc9c3f30f1efa554889e548897df8488975f0eb05488345f80848837df800742f488b45f8488b004885c07423488b45f8488b00483945f075dbeb14488b45f8488b5008488b45f8488910488345f80848837df800740c488b45f8488b004885c075d9905dc3f30f1efa554889e54881ec5002000089bdbcfdffff64488b042528000000488945f831c0e808faffff4898488985d8fdffffe823fcffff488d05b9010000488d15bbffffff4829d089c6488d05afffffff4889c7e866fcffffbe26050000488d052c2800004889c7e852fcffff488d85d8fdffffbe080000004889c7e83efcffff488d85d8fdffffbe080000004889c7e823fdffff488b95d8fdffff488d85f0fdffff488d0dcf0700004889ce4889c7b800000000e867faffff488d85f0fdffff4889c7e848f9ffff488985e8fdffff488d85f0fdffff4889c7e862f9ffff8985d0fdffff4883bde8fdffff00755b488b85d8fdffff488d8df0fdffff8b95d0fdffff4863d2488d3c118b95bcfdffff89d14889c2488d05620700004889c6b800000000e8f8f9ffff488d85f0fdffff4889c7e819faffff4889c7e851f9ffffb800000000e997000000488db5f0fdffff488d8dccfdffff488d95e0fdffff488b85e8fdffff4989f0488d35160700004889c7b800000000e884f9ffff8985d4fdffff83bdd4fdffff027550488b95e0fdffff488b85d8fdffff4839c2753d8b85d0fdfffff7d84898488d50ff488b85e8fdffff4801c2488b05132c00004889d64889c7e8d4fdffff8b95ccfdffff8b85bcfdffff29d083c001eb05b8ffffffff488b55f864482b1425280000007405e85cf8ffffc9c3f30f1efa554889e5905dc3f30f1efa554889e5534883ec48897dbc488975b0488b45b0488b00488945e048837de0007513488d05600600004889c7e8daf7ffff488945e048837de000752d488b05a82b00004889c1ba20000000be01000000488d05340600004889c7e8dcf8ffffbf01000000e8c2f8ffff8b45bc89c7e887fdffff8945d4e8d9f9ffffbe00010000488d05402600004889c7e82afaffffbe41000000488d05892700004889c7e80ffbffffbe01000000488d05172800004889c7e8fbfaffff0fb6050828000084c0742d488d05fd2700004889c7e8caf7ffff4889c3bf00000000e8fdf7ffff4839c37d0c488d053a270000e9fe030000be0a000000488d050b2700004889c7e8affaffffbe03000000488d05032700004889c7e89bfaffffbe0f000000488d05462700004889c7e887faffffbe01000000488d05422700004889c7e873faffffbe16000000488d054b2700004889c7e85ffaffffbe16000000488d05372700004889c7e852f9ffffbe16000000488d05542700004889c7e837faffffba16000000488d05402700004889c6488d05052700004889c7e8d2f6ffff85c0740c488d05f2260000e944030000be13000000488d05c92600004889c7e8f5f9ffff837dd400790c488d05b4260000e91e0300008b45bc83c00a4898be080000004889c7e897f6ffff488945e848837de800750ab800000000e9f4020000837dd4000f8428010000be01000000488d05f52500004889c7e89bf9ffff0fb605e625000084c0751f488d05dd2500004889c7e875faffff85c0740c488d05ca250000e9ac020000be01000000488d052d2600004889c7e85df9ffffbe39020000488d059d2600004889c7e849f9ffffbe13000000488d053c2600004889c7e835f9ffffbe13000000488d05282600004889c7e828f8ffffbe13000000488d05502500004889c7e80df9ffffba13000000488d053c2500004889c6488d05f62500004889c7e8a8f5ffff85c0740c488d05e3250000e91a020000bf39120000e80ef6ffff488945d848837dd800750ab800000000e9fb010000488b45d8ba00100000be200000004889c7e853f5ffff488b45d8480500100000ba39020000488d0de02500004889ce4889c7e8a2f5ffffeb530fb6053725000084c07440bf00020000e8abf5ffff488945d848837dd800750ab800000000e998010000488b55e0488b45d8488d0d052500004889ce4889c7b800000000e8a7f5ffffeb08488b45e0488945d8c745d0000000008b45d08d50018955d04898488d14c500000000488b45e84801c2488b45b0488b00488902837dd400742f0fb605c424000084c074248b45d08d50018955d04898488d14c500000000488b45e84801d0488d159f2400004889100fb6052d24000084c074248b45d08d50018955d04898488d14c500000000488b45e84801d0488d15082400004889108b45d08d50018955d04898488d14c500000000488b45e84801c2488b45d84889020fb6054424000084c074248b45d08d50018955d04898488d14c500000000488b45e84801d0488d151f240000488910837dd4017e058b45d4eb05b8000000008945cceb3b8b45cc8d50018955cc4898488d14c500000000488b45b0488d0c028b45d08d50018955d04898488d14c500000000488b45e84801c2488b014889028b45cc3b45bc7cbd8b45d04898488d14c500000000488b45e84801d048c70000000000488b45e84889c6488d05282300004889c7e825f4ffff488d0519230000488b5df8c9c3f30f1efa554889e54154534883ec10897dec488975e0488b45e0488d5808488b55e08b45ec4889d689c7e8dafaffff488903488b45e04883c008488b004885c0740a488b45e04c8b6008eb074c8d2566010000e8d0f2ffff8b0085c07413e8c5f2ffff8b0089c7e8fcf3ffff4889c3eb07488d1d48010000e8abf2ffff8b0085c07409488d0537010000eb07488d052d010000488b55e0488b12488b3d572600004d89e14989d84889c1488d05130100004889c6b800000000e8faf2ffffb8010000004883c4105b415c5dc3f30f1efa4883ec084883c408c3000000000000000000000000000000000000000000000000000000000000000000000";
        function getVixen() public pure returns (string memory) {
        return Vixen;
    }
}

library Vixen_2 {
    string public constant Vixen = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010002000000000078256c78003d256c7520256400256c752025642563005f00453a206e65697468657220617267765b305d206e6f7220245f20776f726b732e003c6e756c6c3e00003a20002573257325733a2025730a00011b033b740000000d000000c8efffffa800000038f1ffffd000000048f1ffffe8000000a8f2ffff9000000091f3ffff00010000f6f3ffff20010000eff4ffff40010000e3f5ffff60010000d4f6ffff8001000037f7ffffa00100002ef9ffffc001000039f9ffffe001000030feffff04020000000000001400000000000000017a5200017810011b0c070890010000140000001c00000010f2ffff260000000044071000000000240000003400000018efffff70010000000e10460e184a0f0b770880003f1a3a2a33242200000000140000005c00000060f0ffff100000000000000000000000140000007400000058f0ffff6001000000000000000000001c0000008c00000089f2ffff6500000000450e108602430d06025c0c070800001c000000ac000000cef2fffff900000000450e108602430d0602f00c070800001c000000cc000000a7f3fffff400000000450e108602430d0602eb0c070800001c000000ec0000007bf4fffff100000000450e108602430d0602e80c070800001c0000000c0100004cf5ffff6300000000450e108602430d06025a0c070800001c0000002c0100008ff5fffff701000000450e108602430d0603ee010c0708001c0000004c01000066f7ffff0b00000000450e108602430d06420c0708000000200000006c01000051f7fffff704000000450e108602430d0645830303e9040c07080000200000009001000024fcffffcc00000000450e108602430d06478c03830402bc0c07080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e013000000000000a0130000000000000100000000000000e7000000000000000c0000000000000000100000000000000d00000000000000541f0000000000001900000000000000103d0000000000001b0000000000000008000000000000001a00000000000000183d0000000000001c000000000000000800000000000000f5feff6f00000000b0030000000000000500000000000000e8060000000000000600000000000000e8030000000000000a0000000000000077010000000000000b000000000000001800000000000000150000000000000000000000000000000300000000000000103f00000000000002000000000000001002000000000000140000000000000007000000000000001700000000000000000a000000000000070000000000000010090000000000000800000000000000f000000000000000090000000000000018000000000000001e000000000000000800000000000000fbffff6f000000000100000800000000feffff6f00000000a008000000000000ffffff6f000000000100000000000000f0ffff6f000000006008000000000000f9ffff6f0000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000203d000000000000000000000000000000000000000000003010000000000000401000000000000050100000000000006010000000000000701000000000000080100000000000009010000000000000a010000000000000b010000000000000c010000000000000d010000000000000e010000000000000f0100000000000000011000000000000101100000000000020110000000000003011000000000000401100000000000050110000000000006011000000000000701100000000000080110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000840000000000000000000000000000000000000000000009f9a1565f52b9a5c836d00f429d30facfac255dd4b1d8f630fb90c83befc195e972fc38c5a5ee9ddccead1f5bee1a2b9a3f897ef15275224e05fa89f51c3e041b8e143e90c954af5ec3856ace45eeeeef3abff8648a09296e3e1b835a599775d7bba46884f917d3cc9d4e8ad32d79b26829baccb3c3e6220201a56c5b4cd232f886ab7d8fb3514c50afd723cd40e6257aa0f23e64e85066ea05c34542a5884b2c33c8abe729f847d9cf6b970051cc8af2ceb957a709ce911f91e662376ebd6392861f89a007c179d73d10d78eed5271ac1bd9432597e43539caa7712954d4cbdaf4557b0c26f4d35415aad2f30d54af292df24ec5d683ff912b60ba7045865b39dbd635f2cb1956e0b429e3c18e82faac7539725bcd61ecf8d2a779282dc462099aa80c65b15346758d3a370bbd21b8326b2a8e389c7b217f129a9745bc1fdf2f0c07f4b1f6929eb54fbe012dc83cc807b636f908ac1b46a205d097c1f066f0fc7582eb8eea99dcf71459f039b571109d0d060c29d84d2ac7f93b19dfb6a6ddefc9efde591ef4b7846c653edaa72f41a82bc09dea36162750e486b224b3fa61661ac3b527fbefd4fde1030c1881487df378a6edb66e6a1073ee6b8fd2f04ddcf08ecd18d1d851e963e7c79f607aa5e282186941ba2e32dfca75ce127ce1a7b1455899f875aec8ec5a751db02bc0ee98d944c0d92f8cae5bbc4468b803a154634ec21f5c43022896690e8d1bc0bd5673925d7f3e78a38542c1b5b449f4d87f473bad15eaef0e319b3dc370160bfaa17c4732a4432e4f5b7b09e080b37f85c7308f956b02256313b4881a11012b52ae2bf926b8abc86255039c31fa932087b03665bb6ed09a7d112b2c3642306790891358eb686463122d18fe668dff0af7199db34a94fb422400c23a58f69cecb28c5066a7476d0d6c507019f930f6e0f32cfd8d762caa3c19d61874f2da3184e6c5b0096959ec828faa8bd82528f154f1d71616fbd9ce6aba3df3bcfc507e75d11b17c5c99017d38f48034a4130060caea277547b96679c1895d50df88da3b2c62bc666ec98d7e54444e2734f2eeb1427d23fe382218aba3a7a9830bfb765b9613c41d6edf8312829381dc39493502913fe42c899a22c8612daf5ff1e53db8426097f1625570d160eddcedaf4a2ac4076e83c6e2c7d469847cf8172a9bf001f35f1c4c4e94881119ff02f527f7c2f01c6a8c4396fa25f901907001daff61b4f9bb4939dac94c0b3483ed9320467b0e94296f37a540aac23f6251ea94d7a71cb9bf8af31042e693586d165ee6b41873d8b414ad02eb0b8118456d635ca45df4117844da9161c07ee1ceca90c387efdedc4ed950720b50180599299e600fe88cfa7c9975278adee090d2efba6bb768057abe2e0129bed8561ee515c315ab22ec42db216672b1f971fe5aa2826716f64780154fbe897d6ce60c21421311e5cffa8c93eb6e19622be0c456661e5b462aa80aa77c28819698d9d58b423cce8d1484c9a65b43cdd3b02fbb18db69b13312dd911c40505c8093a68f91ed0f13336436d895512d9a9aa1be803318e38f0f608901e5c5515ae43c218530e9d70805062474d4ef29e01b8ae39fc9083012ec4829154e4739db2929d05daed5217eefc047ca873fd4d2125dd5ee8b0f20118be5dfed341b50f3a4c99e3b619bf96e838ae161e8609bac8044de89bfe1f01b98dd243fae37f1729b1579151d0a4babc0d10da932a855b3ec343dac162dc7ae0becedba23df2cbff4a6d511b020bd71f2ca1a257270d85fa5150bbb43d36a4fbf5709e33736a32bdc783d8d99fafe8bc418b0378989962e9fa1e9e274533134ab3b17e271ba0d4e334bdbcc004743433a20285562756e74752031312e332e302d317562756e7475317e32322e3034292031312e332e3000002e7368737472746162002e696e74657270002e6e6f74652e676e752e70726f7065727479002e6e6f74652e676e752e6275696c642d6964002e6e6f74652e4142492d746167002e676e752e68617368002e64796e73796d002e64796e737472002e676e752e76657273696f6e002e676e752e76657273696f6e5f72002e72656c612e64796e002e72656c612e706c74002e696e6974002e706c742e676f74002e706c742e736563002e74657874002e66696e69002e726f64617461002e65685f6672616d655f686472002e65685f6672616d65002e696e69745f6172726179002e66696e695f6172726179002e64796e616d6963002e64617461002e627373002e636f6d6d656e74000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000010000000200000000000000180300000000000018030000000000001c000000000000000000000000000000010000000000000000000000000000001300000007000000020000000000000038030000000000003803000000000000300000000000000000000000000000000800000000000000000000000000000026000000070000000200000000000000680300000000000068030000000000002400000000000000000000000000000004000000000000000000000000000000390000000700000002000000000000008c030000000000008c03000000000000200000000000000000000000000000000400000000000000000000000000000047000000f6ffff6f0200000000000000b003000000000000b0030000000000003800000000000000060000000000000008000000000000000000000000000000510000000b0000000200000000000000e803000000000000e803000000000000000300000000000007000000010000000800000000000000180000000000000059000000030000000200000000000000e806000000000000e806000000000000770100000000000000000000000000000100000000000000000000000000000061000000ffffff6f02000000000000006008000000000000600800000000000040000000000000000600000000000000020000000000000002000000000000006e000000feffff6f0200000000000000a008000000000000a00800000000000070000000000000000700000001000000080000000000000000000000000000007d00000004000000020000000000000010090000000000001009000000000000f00000000000000006000000000000000800000000000000180000000000000087000000040000004200000000000000000a000000000000000a000000000000100200000000000006000000180000000800000000000000180000000000000091000000010000000600000000000000001000000000000000100000000000001b000000000000000000000000000000040000000000000000000000000000008c00000001000000060000000000000020100000000000002010000000000000700100000000000000000000000000001000000000000000100000000000000097000000010000000600000000000000901100000000000090110000000000001000000000000000000000000000000010000000000000001000000000000000a0000000010000000600000000000000a011000000000000a0110000000000006001000000000000000000000000000010000000000000001000000000000000a900000001000000060000000000000000130000000000000013000000000000540c000000000000000000000000000010000000000000000000000000000000af000000010000000600000000000000541f000000000000541f0000000000000d00000000000000000000000000000004000000000000000000000000000000b5000000010000000200000000000000002000000000000000200000000000005800000000000000000000000000000008000000000000000000000000000000bd000000010000000200000000000000582000000000000058200000000000007400000000000000000000000000000004000000000000000000000000000000cb000000010000000200000000000000d020000000000000d020000000000000b401000000000000000000000000000008000000000000000000000000000000d50000000e0000000300000000000000103d000000000000102d0000000000000800000000000000000000000000000008000000000000000800000000000000e10000000f0000000300000000000000183d000000000000182d0000000000000800000000000000000000000000000008000000000000000800000000000000ed000000060000000300000000000000203d000000000000202d000000000000f0010000000000000700000000000000080000000000000010000000000000009b000000010000000300000000000000103f000000000000102f000000000000f000000000000000000000000000000008000000000000000800000000000000f6000000010000000300000000000000004000000000000000300000000000004605000000000000000000000000000020000000000000000000000000000000fc00000008000000030000000000000060450000000000004635000000000000480100000000000000000000000000002000000000000000000000000000000001010000010000003000000000000000000000000000000046350000000000002b0000000000000000000000000000000100000000000000010000000000000001000000030000000000000000000000000000000000000071350000000000000a01000000000000000000000000000001000000000000000000000000000000";
    function getVixen() public pure returns (string memory) {
        return Vixen;
    }
}