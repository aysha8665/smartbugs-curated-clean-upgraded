/*
 * =======================
 * =======================
 * =======================
 */

//added prgma version
pragma solidity ^0.8.0;

contract SimpleSuicide {
  address private owner;
  constructor() { owner = msg.sender; }
  function sudicideAnyone() public {
    require(msg.sender == owner);
    selfdestruct(payable(msg.sender));
  }

}
