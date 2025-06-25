// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {SaveMyName} from "../../src/Day_02/SaveMyName.sol";
import {DeploySaveMyName} from "../../script/Day_02/SaveMyName.s.sol";

contract SaveMyNameTest is Test {
    SaveMyName saveMyName;
    address user = makeAddr("user");
    address otherUser = makeAddr("otherUser");

    function setUp() public {
        DeploySaveMyName deployer = new DeploySaveMyName();
        saveMyName = deployer.run();
        vm.deal(user, 10 ether);
        vm.deal(otherUser, 10 ether);
    }

    function _createPerson(string memory name, string memory bio) internal pure returns (SaveMyName.Person memory) {
        return SaveMyName.Person({name: name, bio: bio});
    }

    function test_SetDetails() public {
        vm.startPrank(user);
        SaveMyName.Person memory person = _createPerson("John Doe", "Web3 Developer");
        saveMyName.setDetails(person);
        SaveMyName.Person memory savedPerson = saveMyName.getMyDetails();
        assertEq(savedPerson.name, "John Doe");
        assertEq(savedPerson.bio, "Web3 Developer");
        vm.stopPrank();
    }

    function test_UpdateBio() public {
        vm.startPrank(user);
        // First set initial details
        SaveMyName.Person memory person = _createPerson("John Doe", "Web3 Developer");
        saveMyName.setDetails(person);

        // Update bio
        saveMyName.updateBio("Senior Web3 Developer");
        SaveMyName.Person memory updatedPerson = saveMyName.getMyDetails();
        assertEq(updatedPerson.bio, "Senior Web3 Developer");
        assertEq(updatedPerson.name, "John Doe"); // Name should remain unchanged
        vm.stopPrank();
    }

    function test_UpdateName() public {
        vm.startPrank(user);
        // First set initial details
        SaveMyName.Person memory person = _createPerson("John Doe", "Web3 Developer");
        saveMyName.setDetails(person);

        // Update name
        saveMyName.updateName("John Smith");
        SaveMyName.Person memory updatedPerson = saveMyName.getMyDetails();
        assertEq(updatedPerson.name, "John Smith");
        assertEq(updatedPerson.bio, "Web3 Developer"); // Bio should remain unchanged
        vm.stopPrank();
    }

    function test_RevertWhen_UpdateNameWithoutDetails() public {
        vm.startPrank(user);
        vm.expectRevert(SaveMyName.SetDetailsFirst.selector);
        saveMyName.updateName("New Name");
        vm.stopPrank();
    }

    function test_GetPerson() public {
        vm.startPrank(user);
        SaveMyName.Person memory person = _createPerson("John Doe", "Web3 Developer");
        saveMyName.setDetails(person);
        vm.stopPrank();

        // Test getting person details from another address
        SaveMyName.Person memory retrievedPerson = saveMyName.getPerson(user);
        assertEq(retrievedPerson.name, "John Doe");
        assertEq(retrievedPerson.bio, "Web3 Developer");
    }

    function test_RevertWhen_UpdateBioWithoutDetails() public {
        vm.startPrank(user);
        vm.expectRevert(SaveMyName.SetDetailsFirst.selector);
        saveMyName.updateBio("New Bio");
        vm.stopPrank();
    }

    function test_RevertWhen_UpdateBioWithEmptyString() public {
        vm.startPrank(user);
        SaveMyName.Person memory person = _createPerson("John Doe", "Web3 Developer");
        saveMyName.setDetails(person);

        vm.expectRevert(SaveMyName.BioIsMissing.selector);
        saveMyName.updateBio("");
        vm.stopPrank();
    }

    function test_RevertWhen_UpdateNameWithEmptyString() public {
        vm.startPrank(user);
        SaveMyName.Person memory person = _createPerson("John Doe", "Web3 Developer");
        saveMyName.setDetails(person);

        vm.expectRevert(SaveMyName.NameIsMissing.selector);
        saveMyName.updateName("");
        vm.stopPrank();
    }
}
