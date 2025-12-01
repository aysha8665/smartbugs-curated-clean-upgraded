/*
 * @source: https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-104#unchecked-return-valuesol
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract ReturnValue {

  function callchecked(address callee) public {
    require(callee.call(""));
  }

  function callnotchecked(address callee) public {
     
    callee.call("");
  }
}
