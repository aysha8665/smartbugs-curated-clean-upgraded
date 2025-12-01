/*
 * =======================
 * =======================
 * =======================
 */

//=======================
//=======================

pragma solidity ^0.8.0;

contract jjjMultiTxOneFuncFeasible {
    uint256 private initialized = 0;
    uint256 public count = 1;

    function run(uint256 input) public {
        if (initialized == 0) {
            initialized = 1;
            return;
        }
        
        unchecked { count -= input; }
    }
}
