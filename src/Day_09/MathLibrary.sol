// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MathLibrary {
    error MathLib_DivideByZero();

    function add(uint256 x, uint256 y) public pure returns (uint256 z) {
        return x + y;
    }

    function sub(uint256 x, uint256 y) public pure returns (uint256 z) {
        return x - y;
    }

    function div(uint256 x, uint256 y) public pure returns (uint256 z) {
        if (y == 0) revert MathLib_DivideByZero();
        return x / y;
    }

    function mul(uint256 x, uint256 y) public pure returns (uint256 z) {
        if (x == 0 || y == 0) return 0;
        return x * y;
    }

    function power(uint256 x, uint256 y) public pure returns (uint256 z) {
        if (y == 0) return 1;
        return x ** y;
    }
}
