// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";

import {SmartCalculator} from "../../src/Day_09/SmartCalculator.sol";
import {DeploySmartCalculator} from "../../script/Day_09/SmartCalculator.s.sol";
import {DeployMathContract} from "../../script/Day_09/MathContract.s.sol";

contract SmartCalculatorTest is Test {
    SmartCalculator smartCalculator;
    address user = makeAddr("user");
    address owner;
    address deployerAddress;

    function setUp() public {
        // vm.stopPrank();
        DeploySmartCalculator deployer = new DeploySmartCalculator();
        smartCalculator = deployer.run();
        owner = smartCalculator.getOwner();
        deployerAddress = address(deployer);
    }

    function test_CalculatePowerLib() public view {
        uint256 result = smartCalculator.calculatePowerLib(2, 3);
        assertEq(result, 8); // 2^3 = 8
    }

    function test_CalculatePowerContract() public view {
        uint256 result = smartCalculator.calculatePowerContract(2, 3);
        assertEq(result, 8); // 2^3 = 8
    }

    function test_AddNumber() public view {
        uint256 result = smartCalculator.addNumber(5, 3);
        assertEq(result, 8); // 5 + 3 = 8
    }

    function test_AddNumberContract() public view {
        uint256 result = smartCalculator.addNumberContract(5, 3);
        assertEq(result, 8); // 5 + 3 = 8
    }

    function test_PerformCalculation_Add() public {
        uint256 result = smartCalculator.performCalculation("add", 5, 3);
        assertEq(result, 8); // 5 + 3 = 8
    }

    function test_PerformCalculation_Power() public {
        uint256 result = smartCalculator.performCalculation("power", 2, 3);
        assertEq(result, 8); // 2^3 = 8
    }

    function test_PerformCalculation_Mul() public {
        uint256 result = smartCalculator.performCalculation("mul", 4, 3);
        assertEq(result, 12); // 4 * 3 = 12
    }

    function test_PerformCalculation_Sub() public {
        uint256 result = smartCalculator.performCalculation("sub", 10, 3);
        assertEq(result, 7); // 10 - 3 = 7
    }

    function test_PerformCalculation_Div() public {
        uint256 result = smartCalculator.performCalculation("div", 15, 3);
        assertEq(result, 5); // 15 / 3 = 5
    }

    function test_RevertWhen_InvalidOperation() public {
        vm.expectRevert(SmartCalculator.SmartCalculator_InvalidOperation.selector);
        smartCalculator.performCalculation("invalid", 5, 3);
    }

    function test_UpdateMathContract() public {
        // Deploy a new math contract
        DeployMathContract newMathDeployer = new DeployMathContract();
        address newMathContract = address(newMathDeployer.run());

        // Update the contract as owner (default msg.sender in tests)
        vm.prank(owner);
        smartCalculator.updateMathContract(newMathContract);

        // Test that it still works
        uint256 result = smartCalculator.performCalculation("add", 5, 3);
        assertEq(result, 8);
    }

    function test_RevertWhen_UpdateMathContract_NotOwner() public {
        // Deploy a new math contract
        DeployMathContract newMathDeployer = new DeployMathContract();
        address newMathContract = address(newMathDeployer.run());

        // Try to update as non-owner (should revert)
        vm.prank(user); // Switch to non-owner
        vm.expectRevert(); // Expecting ownership revert
        smartCalculator.updateMathContract(newMathContract);
    }

    function test_WhoIsOwner() public view {
        address actualOwner = smartCalculator.getOwner();
        console.log("Actual owner:", actualOwner);
        console.log("Actual owner 2:", owner);
        console.log("Test contract:", address(this));
        console.log("Test contract 2:", deployerAddress);
    }

    function test_RevertWhen_UpdateMathContract_ZeroAddress() public {
        vm.prank(owner);
        // vm.expectRevert(SmartCalculator.SmartCalculator_UnAuthorized.selector); // Expecting the require statement revert
        vm.expectRevert();
        smartCalculator.updateMathContract(address(0));
    }
}
