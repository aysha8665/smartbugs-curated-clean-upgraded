/*
 * @source: https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-104#unchecked-return-valuesol
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract ReturnValue {

  function callchecked(address callee) public {
    (bool success, ) = callee.call(""); require(success);
  }

  function callnotchecked(address callee) public {
     
    (bool success, ) = callee.call("");
  }
}
