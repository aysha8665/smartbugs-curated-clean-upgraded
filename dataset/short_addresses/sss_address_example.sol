/*
 * @source: https://ericrafaloff.com/analyzing-the-erc20-short-address-attack/
 * @author: -
 * =======================
 */

 pragma solidity ^0.8.0;

 contract MyToken {
     mapping (address => uint) balances;

     event Transfer(address indexed _from, address indexed _to, uint256 _value);

     constructor()  {
         balances[tx.origin] = 10000;
     }
     
     function sendCoin(address to, uint amount) public returns(bool sufficient) {
         if (balances[msg.sender] < amount) return false;
         balances[msg.sender] -= amount;
         balances[to] += amount;
         emit Transfer(msg.sender, to, amount);
         return true;
     }

     function getBalance(address addr) view public returns(uint) {
         return balances[addr];
     }
 }
