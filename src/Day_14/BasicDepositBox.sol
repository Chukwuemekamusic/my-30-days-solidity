// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseDepositBox} from "./BaseDepositBox.sol";
import {BoxType} from "./BoxTypes.sol";

contract BasicDepositBox is BaseDepositBox {
    function getBoxType() external pure override returns (BoxType) {
        return BoxType.Basic;
    }
} 