/*
 * @source: https://github.com/sigp/solidity-security-blog
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract Roulette {
    uint public pastBlockTime; // Forces one bet per block

    constructor() payable {} // initially fund contract

    // fallback function used to make a bet
    receive() external payable {
        require(msg.value == 10 ether); // must send 10 ether to play
        
        require(block.timestamp != pastBlockTime); // only 1 transaction per block
        
        pastBlockTime = block.timestamp;
        if(block.timestamp % 15 == 0) { // winner
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}
