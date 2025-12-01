/*
 * =======================
 * =======================
 * =======================
 */

//added prgma version
pragma solidity ^0.8.0;

contract SimpleSuicide {
 
  function sudicideAnyone() public {
    selfdestruct(payable(msg.sender));
  }

}
