/*
 * =======================
 * =======================
 * =======================
 */

 pragma solidity ^0.8.0;

 contract yyyy {
     uint private sellerBalance=0;

     function add(uint value) public returns(bool) {
         
         unchecked { sellerBalance += value; } 

          
         
     }


 }