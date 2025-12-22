/*
 * ======================
 * ======================
 * ======================
 */

pragma solidity ^0.8.0;

/**
 * @title MultiOwnable
 */
contract MultiOwnable {
  address public root;
  mapping (address => address) public owners; // owner => parent of owner

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() {
    root = msg.sender;
    owners[root] = root;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(owners[msg.sender] != address(0));
    _;
  }

  /**
  * @dev Adding new owners
  * ======================
  */
  
  function newOwner(address _owner) external returns (bool) {
    require(_owner !=  address(0));
    owners[_owner] = msg.sender;
    return true;
  }

  /**
    * @dev Deleting owners
    */
  function deleteOwner(address _owner) onlyOwner external returns (bool) {
    require(owners[_owner] == msg.sender || (owners[_owner] !=  address(0) && msg.sender == root));
    owners[_owner] = address(0);
    return true;
  }
}

contract TestContract is MultiOwnable {

  function withdrawAll() onlyOwner public {
    payable(msg.sender).transfer(address(this).balance);
  }

  receive() external payable {
  }

}
