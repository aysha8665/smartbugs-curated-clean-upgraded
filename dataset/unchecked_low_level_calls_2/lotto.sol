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
         
         payable(winner).send(winAmount);
         payedOut = true;
     }

     function withdrawLeftOver() public {
         require(payedOut);
         
         payable(msg.sender).send(address(this).balance);
     }
 }
