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

  //=======================
  function bid() payable public {
    require(msg.value > currentBid);

    //=======================
    
    if (currentFrontrunner != address(0)) {
      
      
      require(payable(currentFrontrunner).send(currentBid));
    }

    currentFrontrunner = msg.sender;
    currentBid         = msg.value;
  }
}
