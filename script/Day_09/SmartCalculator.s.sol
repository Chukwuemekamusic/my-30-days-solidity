// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {SmartCalculator} from "../../src/Day_09/SmartCalculator.sol";
import {DeployMathContract} from "./MathContract.s.sol";

contract DeploySmartCalculator is Script {
    function run() external returns (SmartCalculator) {
        // First deploy the MathContract
        DeployMathContract mathDeployer = new DeployMathContract();
        address mathContractAddress = address(mathDeployer.run());
        console.log("MathContract deployed at:", mathContractAddress);

        // Then deploy SmartCalculator with the MathContract address
        vm.startBroadcast();
        SmartCalculator smartCalculator = new SmartCalculator(mathContractAddress);
        console.log("SmartCalculator deployed at:", address(smartCalculator));
        vm.stopBroadcast();

        return smartCalculator;
    }
}
