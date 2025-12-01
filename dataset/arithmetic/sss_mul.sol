/*
 * =======================
 * =======================
 * =======================
 */

//=======================
//=======================

pragma solidity ^0.8.0;

contract sssMul {
    uint public count = 2;

    function run(uint256 input) public {
        
        unchecked { count *= input; }
    }
}
