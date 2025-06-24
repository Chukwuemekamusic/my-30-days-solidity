// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {VaultManager} from "../../src/Day_14/VaultManager.sol";
import {BoxType, BoxTypeLib} from "../../src/Day_14/BoxTypes.sol";
import {IDepositBox} from "../../src/Day_14/IDepositBox.sol";

contract VaultManagerTest is Test {
    VaultManager public manager;
    address public owner;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        owner = address(this);
        manager = new VaultManager();
    }

    function test_CreateBasicBox() public {
        uint256 boxId = manager.createBasicBox();
        (,, address currentOwner,, bool isActive) = getBoxInfo(boxId);
        assertEq(currentOwner, owner);
        assertTrue(isActive);
    }

    function test_CreatePremiumBox() public {
        uint256 boxId = manager.createPremiumBox();
        (,, address currentOwner,, bool isActive) = getBoxInfo(boxId);
        assertEq(currentOwner, owner);
        assertTrue(isActive);
    }

    function test_CreateTimeLockedBox() public {
        uint256 boxId = manager.createTimeLockedBox(1 days);
        (,, address currentOwner,, bool isActive) = getBoxInfo(boxId);
        assertEq(currentOwner, owner);
        assertTrue(isActive);
    }

    function test_RevertWhen_CreateTimeLockedBox_ZeroDuration() public {
        vm.expectRevert(VaultManager.VaultManager_InvalidLockDuration.selector);
        manager.createTimeLockedBox(0);
    }

    function test_TransferOwnership() public {
        uint256 boxId = manager.createBasicBox();
        manager.transferOwnerShip(boxId, user1);
        (,, address currentOwner,,) = getBoxInfo(boxId);
        assertEq(currentOwner, user1);
    }

    function test_RevertWhen_TransferOwnership_NotOwner() public {
        uint256 boxId = manager.createBasicBox();
        vm.prank(user1);
        vm.expectRevert(VaultManager.VaultManager_NotBoxOwner.selector);
        manager.transferOwnerShip(boxId, user2);
    }

    function test_RevertWhen_TransferOwnership_ZeroAddress() public {
        uint256 boxId = manager.createBasicBox();
        vm.expectRevert(VaultManager.VaultManager_ZeroAddress.selector);
        manager.transferOwnerShip(boxId, address(0));
    }

    function test_DeactivateBox() public {
        uint256 boxId = manager.createBasicBox();
        manager.deactivateBox(boxId);
        (,,,, bool isActive) = getBoxInfo(boxId);
        assertFalse(isActive);
    }

    function test_RevertWhen_DeactivateBox_NotOwner() public {
        uint256 boxId = manager.createBasicBox();
        vm.prank(user1);
        vm.expectRevert(VaultManager.VaultManager_NotBoxOwner.selector);
        manager.deactivateBox(boxId);
    }

    function test_GetUserBoxes() public {
        uint256 boxId1 = manager.createBasicBox();
        uint256 boxId2 = manager.createPremiumBox();
        uint256[] memory boxes = manager.getUserBoxes(owner);
        assertEq(boxes.length, 2);
        assertEq(boxes[0], boxId1);
        assertEq(boxes[1], boxId2);
    }

    function test_GetUserActiveBoxes() public {
        uint256 boxId1 = manager.createBasicBox();
        uint256 boxId2 = manager.createPremiumBox();
        manager.deactivateBox(boxId1);
        uint256[] memory activeBoxes = manager.getUserActiveBoxes(owner);
        assertEq(activeBoxes.length, 1);
        assertEq(activeBoxes[0], boxId2);
    }

    function test_GetBoxesByType() public {
        uint256 boxId1 = manager.createBasicBox();
        uint256 boxId2 = manager.createPremiumBox();
        uint256[] memory basicBoxes = manager.getBoxesByType(BoxType.Basic);
        uint256[] memory premiumBoxes = manager.getBoxesByType(BoxType.Premium);
        assertEq(basicBoxes.length, 1);
        assertEq(basicBoxes[0], boxId1);
        assertEq(premiumBoxes.length, 1);
        assertEq(premiumBoxes[0], boxId2);
    }

    // function test_RevertWhen_GetBoxesByType_InvalidType() public {
    //     vm.expectRevert();
    //     manager.getBoxesByType(BoxType(uint8(3)));
    // }

    function test_IsBoxOwner() public {
        uint256 boxId = manager.createBasicBox();
        assertTrue(manager.isBoxOwner(boxId, owner));
        assertFalse(manager.isBoxOwner(boxId, user1));
    }

    function test_GetBoxContract() public {
        uint256 boxId = manager.createBasicBox();
        address boxContract = manager.getBoxContract(boxId);
        assertTrue(boxContract != address(0));
    }

    function test_RevertWhen_GetBoxContract_InvalidBox() public {
        vm.expectRevert(VaultManager.VaultManager_BoxNotFound.selector);
        manager.getBoxContract(999);
    }

    // Helper to unpack BoxRegistry struct
    function getBoxInfo(uint256 boxId) internal view returns (
        IDepositBox boxContract,
        BoxType boxType,
        address currentOwner,
        address originalOwner,
        bool isActive
    ) {
        VaultManager.BoxRegistry memory info = manager.getBoxInfo(boxId);
        return (info.boxContract, info.boxType, info.currentOwner, info.originalOwner, info.isActive);
    }
} 