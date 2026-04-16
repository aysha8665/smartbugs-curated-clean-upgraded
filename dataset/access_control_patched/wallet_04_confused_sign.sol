/*
 * =======================
 * =======================
 * =======================
 */

 pragma solidity ^0.8.0;

 /* =======================
    =======================
    =======================
 */

 contract Wallet {
     address creator;

     mapping(address => uint256) balances;

     constructor() payable {
         creator = msg.sender;
     }

     function deposit() public payable {
            assert(balances[msg.sender] + msg.value > balances[msg.sender]);
            balances[msg.sender] += msg.value;
     }

     function withdraw(uint256 amount) public {
         
         // 1. Checks: amount must be LESS THAN or EQUAL TO the user's balance
        require(amount <= balances[msg.sender], "Insufficient balance");
        
        // 2. Effects: update state before the external call
        balances[msg.sender] -= amount;
        
        // 3. Interactions: transfer the funds safely
        payable(msg.sender).transfer(amount);
     }

     // In an emergency the owner can migrate  allfunds to a different address.

     function migrateTo(address to) public {
         require(creator == msg.sender);
         payable(to).transfer(address(this).balance);
     }

 }
