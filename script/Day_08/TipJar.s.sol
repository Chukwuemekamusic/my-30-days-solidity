// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TipJar} from "../../src/Day_08/TipJar.sol";

contract DeployTipJar is Script {
    function run() external returns (TipJar) {
        vm.startBroadcast();
        TipJar tipJar = new TipJar();
        vm.stopBroadcast();

        return tipJar;
    }
}
