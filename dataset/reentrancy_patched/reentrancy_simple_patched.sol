/*
 * @source: https://github.com/trailofbits/not-so-smart-contracts/blob/master/reentrancy/Reentrancy.sol
 * @author: -
 * =======================
 */

 pragma solidity ^0.8.0;

 contract Reentrance {
     bool private _locked;
     mapping (address => uint) userBalance;

     function getBalance(address u) view public returns(uint) {
         return userBalance[u];
     }

     function addToBalance() payable public {
         userBalance[msg.sender] += msg.value;
     }

     function withdrawBalance() public {
         require(!_locked, "ReentrancyGuard: reentrant call");
         _locked = true;
         uint amount = userBalance[msg.sender];
         userBalance[msg.sender] = 0;
         (bool success, ) = msg.sender.call{value: amount}(""); if (!success) {
            revert();
         }
         _locked = false;
     }
 }
