/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract Caller {
    function callAddress(address a) public {
        
        a.call("");
    }
}
