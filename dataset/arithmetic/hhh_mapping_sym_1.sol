/*
 * =======================
 * =======================
 * =======================
 */

//=======================

pragma solidity ^0.8.0;

contract hhhMappingSym1 {
    mapping(uint256 => uint256) map;

    function init(uint256 k, uint256 v) public {
        
        unchecked { map[k] -= v; }
    }
}
