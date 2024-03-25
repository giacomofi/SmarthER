// SPDX-License-Identifier: MIT
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@*,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@,,,*@@@@@@,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,@@@@@@*,,,,@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@****@@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@@@@@#@@@@@@@(**%@@@@@@,,@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@*,,,*@@@@@@@@,@*@@@@@@@@@@@@@@@@***@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@,,@@@@@@**(@@@@@@@,,,,,**@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,@@@@@@***@@@@@*,,,,,,,,,@@@@@*,,*@@@@@(@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@,,,,@@@#,,,,,,*,@@*,,,,,,,,@@@,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@**,**@@@@,,,,,,,**@@***,,*@@@**,,,,,,,*@@@@,,*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@(,******@@@@@#(@@@@@@@**,,,,*@*,,,,,,*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,*@@@@****(@@@@@,,,,,,@@@@@**@@(@@,,,,,,,,@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@*,,,,,,,@@@@/(@@,,,*,,,,,,,,,,@@(@@@@@***,,*/*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,,**@@@@#@@,,,,,,,,,,,,,,,,,#@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@****@@@@@@#(,,,,,,,,,,,,,,,,,,,,,,,,*,,@@@@#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@(@@@@***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@,,,,,,,,,,,*,****,,,,,,,,,***,,,,,,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@,,,,,,**,,,,,,,,,,,,,,******,,*****(@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,,*,***,*******,,*****,****(***@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,**,********(@@@*@@@((@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@***********@@@@@@@@*@@*,*@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@@@@@((*@@@@@@@@@@@@(@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pragma solidity 0.8.18;

import { JailBreakCommitment } from "../shared/Types.sol";

library JailBreakStorage {
    struct Layout {
        mapping(address => JailBreakCommitment) commitments;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("copium.wars.storage.jailbreak");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@*,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@,,,*@@@@@@,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,@@@@@@*,,,,@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@****@@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@@@@@#@@@@@@@(**%@@@@@@,,@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@*,,,*@@@@@@@@,@*@@@@@@@@@@@@@@@@***@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@,,@@@@@@**(@@@@@@@,,,,,**@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,@@@@@@***@@@@@*,,,,,,,,,@@@@@*,,*@@@@@(@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@,,,,@@@#,,,,,,*,@@*,,,,,,,,@@@,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@**,**@@@@,,,,,,,**@@***,,*@@@**,,,,,,,*@@@@,,*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@(,******@@@@@#(@@@@@@@**,,,,*@*,,,,,,*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,*@@@@****(@@@@@,,,,,,@@@@@**@@(@@,,,,,,,,@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@*,,,,,,,@@@@/(@@,,,*,,,,,,,,,,@@(@@@@@***,,*/*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,,**@@@@#@@,,,,,,,,,,,,,,,,,#@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@****@@@@@@#(,,,,,,,,,,,,,,,,,,,,,,,,*,,@@@@#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@(@@@@***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@,,,,,,,,,,,*,****,,,,,,,,,***,,,,,,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@,,,,,,**,,,,,,,,,,,,,,******,,*****(@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,,*,***,*******,,*****,****(***@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,**,********(@@@*@@@((@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@***********@@@@@@@@*@@*,*@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@@@@@((*@@@@@@@@@@@@(@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pragma solidity 0.8.18;
import { JailBreakStorage, JailBreakCommitment } from "./JailBreakStorage.sol";
import { CopiumWarsSlayersStorage } from "../slayers/CopiumWarsSlayersStorage.sol";

contract JailBreakFacet {
    error InvalidDoor();
    error AlreadyPlayed();
    error AlreadyUnlocked();
    error TooEarly();
    error DoorNotChosen();

    event DoorChosen(uint256 door, uint256 revealBlock);
    event NewPriceSet(uint256 newPrice);

    function chooseDoor(uint256 door) external {
        if (door > 2) revert InvalidDoor();
        if (
            JailBreakStorage.layout().commitments[msg.sender].blockNumber > 0 ||
            CopiumWarsSlayersStorage.layout().customPriceUnlock[msg.sender] != 0
        ) revert AlreadyPlayed();
        if (CopiumWarsSlayersStorage.layout().lockedBalance[msg.sender] == 0) revert AlreadyUnlocked();
        JailBreakStorage.layout().commitments[msg.sender] = JailBreakCommitment(uint8(door), uint248(block.number + 5));
        CopiumWarsSlayersStorage.layout().customPriceUnlock[msg.sender] = 0.138 ether;
        emit DoorChosen(door, block.number + 5);
    }

    function openDoor() external {
        JailBreakCommitment memory commitment = JailBreakStorage.layout().commitments[msg.sender];
        if (commitment.blockNumber == 0) revert DoorNotChosen();
        if (commitment.blockNumber >= block.number) revert TooEarly();
        uint256 value = (commitment.door + uint256(blockhash(commitment.blockNumber))) % 3;
        uint256 newPrice;
        if (value == 0) {
            CopiumWarsSlayersStorage.layout().lockedBalance[msg.sender] = 0;
        } else if (value == 1) {
            newPrice = 0.069 ether;
        } else {
            newPrice = 0.138 ether;
        }
        delete JailBreakStorage.layout().commitments[msg.sender];
        CopiumWarsSlayersStorage.layout().customPriceUnlock[msg.sender] = newPrice;
        emit NewPriceSet(newPrice);
    }

    function getCommitment(address player) external view returns (JailBreakCommitment memory) {
        return JailBreakStorage.layout().commitments[player];
    }

    function isReady(address player) external view returns (bool ready) {
        JailBreakCommitment memory commitment = JailBreakStorage.layout().commitments[player];
        ready = commitment.blockNumber > 0 && commitment.blockNumber < block.number;
    }

    function customUnlockPrice(address player) external view returns (uint256) {
        return CopiumWarsSlayersStorage.layout().customPriceUnlock[player];
    }
}

//SPDX-License-Identifier: MIT
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@*,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@,,,*@@@@@@,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,@@@@@@*,,,,@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@****@@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@@@@@#@@@@@@@(**%@@@@@@,,@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@*,,,*@@@@@@@@,@*@@@@@@@@@@@@@@@@***@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@,,@@@@@@**(@@@@@@@,,,,,**@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,@@@@@@***@@@@@*,,,,,,,,,@@@@@*,,*@@@@@(@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@,,,,@@@#,,,,,,*,@@*,,,,,,,,@@@,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@**,**@@@@,,,,,,,**@@***,,*@@@**,,,,,,,*@@@@,,*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@(,******@@@@@#(@@@@@@@**,,,,*@*,,,,,,*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,*@@@@****(@@@@@,,,,,,@@@@@**@@(@@,,,,,,,,@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@*,,,,,,,@@@@/(@@,,,*,,,,,,,,,,@@(@@@@@***,,*/*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,,**@@@@#@@,,,,,,,,,,,,,,,,,#@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@****@@@@@@#(,,,,,,,,,,,,,,,,,,,,,,,,*,,@@@@#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@(@@@@***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@,,,,,,,,,,,*,****,,,,,,,,,***,,,,,,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@,,,,,,**,,,,,,,,,,,,,,******,,*****(@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,,*,***,*******,,*****,****(***@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,**,********(@@@*@@@((@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@***********@@@@@@@@*@@*,*@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@@@@@((*@@@@@@@@@@@@(@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pragma solidity 0.8.18;

enum Weapon {
    Hammer,
    Sword,
    Spear,
    Bow,
    Fart
}

struct Duel {
    bytes32 commitmentPlayerA;
    bytes32 commitmentPlayerB;
}

struct JailBreakCommitment {
    uint8 door;
    uint248 blockNumber;
}

// SPDX-License-Identifier: MIT
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@*,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@,,,*@@@@@@,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,@@@@@@*,,,,@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@****@@@@@@@,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@,,,,@@@@@@@@@#@@@@@@@(**%@@@@@@,,@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@*,,,*@@@@@@@@,@*@@@@@@@@@@@@@@@@***@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@,,@@@@@@**(@@@@@@@,,,,,**@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,@@@@@@***@@@@@*,,,,,,,,,@@@@@*,,*@@@@@(@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@,,,,@@@#,,,,,,*,@@*,,,,,,,,@@@,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@**,**@@@@,,,,,,,**@@***,,*@@@**,,,,,,,*@@@@,,*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@(,******@@@@@#(@@@@@@@**,,,,*@*,,,,,,*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,*@@@@****(@@@@@,,,,,,@@@@@**@@(@@,,,,,,,,@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@*,,,,,,,@@@@/(@@,,,*,,,,,,,,,,@@(@@@@@***,,*/*@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@,,,,,**@@@@#@@,,,,,,,,,,,,,,,,,#@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@****@@@@@@#(,,,,,,,,,,,,,,,,,,,,,,,,*,,@@@@#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@(@@@@***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@##@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@,,,,,,,,,,,*,****,,,,,,,,,***,,,,,,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@,,,,,,**,,,,,,,,,,,,,,******,,*****(@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,,*,***,*******,,*****,****(***@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@***,,,**,********(@@@*@@@((@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@***********@@@@@@@@*@@*,*@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#@@@@@@@@((*@@@@@@@@@@@@(@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pragma solidity 0.8.18;

library CopiumWarsSlayersStorage {
    struct Layout {
        address payable copiumBank;
        address theExecutor;
        uint256 startTime;
        string baseURI;
        string contractURI;
        mapping(uint256 => bool) usedMintTokens;
        mapping(address => uint256) lockedBalance;
        mapping(address => uint256) customPriceUnlock;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("copium.wars.storage.slayers");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}