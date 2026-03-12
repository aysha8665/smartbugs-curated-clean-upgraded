/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

//=======================
contract DosAuction {
  address currentFrontrunner;
  uint currentBid;
  mapping(address => uint) public pendingReturns;

  //=======================
  function bid() payable public {
    require(msg.value > currentBid);

    //=======================
    
    if (currentFrontrunner != address(0)) {
      pendingReturns[currentFrontrunner] += currentBid;
    }

    currentFrontrunner = msg.sender;
    currentBid         = msg.value;
  }

  function withdraw() public {
    uint amount = pendingReturns[msg.sender];
    require(amount > 0);
    pendingReturns[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success);
  }
}
