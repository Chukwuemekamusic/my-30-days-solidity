// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {VaultManager} from "../../src/Day_14/VaultManager.sol";

contract DeployVaultManager is Script {
    function run() external returns (VaultManager deployed) {
        vm.startBroadcast();
        deployed = new VaultManager();
        console2.log("VaultManager deployed at:", address(deployed));
        vm.stopBroadcast();
        // return deployed;
    }
} 


