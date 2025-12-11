/*
 * =======================
 * =======================
 * =======================
 */

//=======================
//=======================

pragma solidity ^0.8.0;

contract vvvBenign1 {
    uint public count = 1;

    function run(uint256 input) public {
        uint res;
        unchecked { res = count - input; }
    }
}
