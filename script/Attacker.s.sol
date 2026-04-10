// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "../src/Challenge2.sol";

contract Challenge2 is Script {
    address constant CHALLENGE = 0x72Ab9921469D911274c31AeF3046942064c2C99F;

    function run() external {
        vm.startBroadcast();

        Attacker attacker = new Attacker(CHALLENGE);
        attacker.attack("MarkDavid");

        vm.stopBroadcast();
    }
}
