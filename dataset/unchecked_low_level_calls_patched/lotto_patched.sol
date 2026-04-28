/*
 * @source: https://github.com/sigp/solidity-security-blog
 * @author: Suhabe Bugrara
 * =======================
 */

 pragma solidity ^0.8.0;
 
 contract Lotto {

     bool public payedOut = false;
     address public winner;
     uint public winAmount;

     // ... extra functionality here

     function sendToWinner() public {
         require(!payedOut);
         
         (bool success, ) = payable(winner).call{value: winAmount}("");
         require(success, "Transfer to winner failed");
         payedOut = true;
     }

     function withdrawLeftOver() public {
         require(payedOut);
         
         (bool success2, ) = payable(msg.sender).call{value: address(this).balance}("");
         require(success2, "Transfer failed");
     }
 }
