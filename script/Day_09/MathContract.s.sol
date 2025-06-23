// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {MathContract} from "../../src/Day_09/MathContract.sol";

contract DeployMathContract is Script {
    function run() external returns (MathContract) {
        vm.startBroadcast();
        MathContract _mathContract = new MathContract();
        vm.stopBroadcast();
        console.log("MathContract address", address(_mathContract));
        return _mathContract;
    }
}
