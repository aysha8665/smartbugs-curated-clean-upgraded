/*
 * =======================
 * =======================
 * =======================
 */

//=======================
//=======================

pragma solidity ^0.8.0;

contract zzzAdd {
    uint public count = 1;

    function run(uint256 input) public {
        
        unchecked { count += input; }
    }
}
