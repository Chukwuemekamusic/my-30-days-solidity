// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title BoxType Enum
 * @dev Defines all available deposit box types
 */
enum BoxType {
    Basic,      // 0
    Premium,    // 1
    TimeLocked  // 2
}

/**
 * @title BoxTypeLib
 * @dev Library for BoxType enum utilities
 */
library BoxTypeLib {
    bytes32 constant HASH_BASIC = keccak256(abi.encodePacked("Basic"));
    bytes32 constant HASH_PREMIUM = keccak256(abi.encodePacked("Premium"));
    bytes32 constant HASH_TIMELOCKED = keccak256(abi.encodePacked("TimeLocked"));

    /**
     * @dev Convert BoxType enum to string
     * @param boxType The enum value
     * @return String representation
     */
    function toString(BoxType boxType) internal pure returns (string memory) {
        if (boxType == BoxType.Basic) return "Basic";
        if (boxType == BoxType.Premium) return "Premium";
        if (boxType == BoxType.TimeLocked) return "TimeLocked";
        revert("Invalid BoxType");
    }
    
    /**
     * @dev Convert string to BoxType enum
     * @param boxTypeString The string representation
     * @return BoxType enum value
     */
    function fromString(string memory boxTypeString) internal pure returns (BoxType) {
        bytes32 hash = keccak256(abi.encodePacked(boxTypeString));
        
        if (hash == HASH_BASIC) return BoxType.Basic;
        if (hash == HASH_PREMIUM) return BoxType.Premium;
        if (hash == HASH_TIMELOCKED) return BoxType.TimeLocked;
        
        revert("Invalid BoxType string");
    }
    
    /**
     * @dev Check if a BoxType is valid
     * @param boxType The enum value to validate
     * @return True if valid
     */
    function isValid(BoxType boxType) internal pure returns (bool) {
        return uint8(boxType) <= uint8(BoxType.TimeLocked);
    }
    
    /**
     * @dev Get all available box types
     * @return Array of all BoxType values
     */
    function getAllTypes() internal pure returns (BoxType[] memory) {
        BoxType[] memory types = new BoxType[](3);
        types[0] = BoxType.Basic;
        types[1] = BoxType.Premium;
        types[2] = BoxType.TimeLocked;
        return types;
    }
}