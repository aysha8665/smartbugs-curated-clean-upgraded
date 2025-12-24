/*
 * ======================
 * ======================
 */

 pragma solidity ^0.8.0;

 contract Wallet {
     uint[] private bonusCodes;
     address private owner;

     constructor() {
         bonusCodes = new uint[](0);
         owner = msg.sender;
     }

     receive() external payable {
     }

     function PushBonusCode(uint c) public {
         bonusCodes.push(c);
     }

     function PopBonusCode() public {
         
         require(0 <= bonusCodes.length); 
         assembly {
            let len := sload(bonusCodes.slot)
            sstore(bonusCodes.slot, sub(len, 1))
        }
     }

     function UpdateBonusCodeAt(uint idx, uint c) public {
         require(idx < bonusCodes.length);
         bonusCodes[idx] = c;
     }

     function Destroy() public {
         require(msg.sender == owner);
         payable(msg.sender).transfer(address(this).balance);
     }
 }
