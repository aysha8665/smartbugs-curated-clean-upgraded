/*
 * ======================
 * ======================
 * ======================
 */

 pragma solidity ^0.8.0;

 

 contract Map {
     address public owner;
     uint256[] map;

     function set(uint256 key, uint256 value) public {
         if (map.length <= key) {
             while (map.length <= key) { map.push(); }
         }
        
         map[key] = value;
     }

     function get(uint256 key) public view returns (uint256) {
         return map[key];
     }
     function withdraw() public{
       require(msg.sender == owner);
       payable(msg.sender).transfer(address(this).balance);
     }
 }
