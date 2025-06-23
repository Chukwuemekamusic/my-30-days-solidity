// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {SaveMyName} from "../src/SaveMyName.sol";

contract DeploySaveMyName is Script {
    function run() external returns (SaveMyName) {
        vm.startBroadcast();
        SaveMyName saveMyName = new SaveMyName();
        vm.stopBroadcast();
        return saveMyName;
    }
}
