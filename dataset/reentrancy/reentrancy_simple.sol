/*
 * @source: https://github.com/trailofbits/not-so-smart-contracts/blob/master/reentrancy/Reentrancy.sol
 * @author: -
 * =======================
 */

 pragma solidity ^0.8.0;

 contract Reentrance {
     mapping (address => uint) userBalance;

     function getBalance(address u) view public returns(uint) {
         return userBalance[u];
     }

     function addToBalance() payable public {
         userBalance[msg.sender] += msg.value;
     }

     function withdrawBalance() public {
         
         
         
        (bool success, ) = msg.sender.call{value: userBalance[msg.sender]}(""); if (!success) {
            revert();
        }
        userBalance[msg.sender] = 0;
     }
 }
