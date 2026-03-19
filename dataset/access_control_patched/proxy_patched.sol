/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract Proxy {

  address owner;

  constructor() {
    owner = msg.sender;
  }

  function forward(address callee, bytes memory _data) public {
    require(msg.sender == owner);
   
    (bool success, ) = callee.delegatecall(_data); require(success);
  }

}
