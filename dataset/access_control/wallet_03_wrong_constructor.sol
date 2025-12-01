/*
 * =======================
 * =======================
 * =======================
 */

 pragma solidity ^0.8.0;

 /* =======================
    =======================
 */

 contract Wallet {
     address creator;

     mapping(address => uint256) balances;
     
     
     function initWallet() public {
         creator = msg.sender;
     }

     function deposit() public payable {
         assert(balances[msg.sender] + msg.value > balances[msg.sender]);
         balances[msg.sender] += msg.value;
     }

     function withdraw(uint256 amount) public {
         require(amount <= balances[msg.sender]);
         payable(msg.sender).transfer(amount);
         balances[msg.sender] -= amount;
     }

     // In an emergency the owner can migrate  allfunds to a different address.

     function migrateTo(address to) public {
         require(creator == msg.sender);
         payable(to).transfer(address(this).balance);
     }

 }
