// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "../src/Coinflip.sol";

contract CoinflipScript is Script {
    Coinflip public coinflip;

    function setUp() public {}

    function run() public {
        vm.createSelectFork(
            "https://eth-sepolia.g.alchemy.com/v2/Vap1yI4yAqw0i1_7ADk3T"
        );
        vm.startBroadcast();

        coinflip = new Coinflip();
        address coinflipAddress = address(
            0xA350993E0429602bA762FEa740d196257D90Ef67
        );

        coinflip.flip(true);

        vm.stopBroadcast();
    }
}
