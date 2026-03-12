/*
 * ======================
 * ======================
 * ======================
 * ======================
 */

pragma solidity ^0.8.0;

contract MyContract {

    address owner;

    constructor()   {
        owner = msg.sender;
    }

    function sendTo(address receiver, uint amount) public {
        
        require(msg.sender == owner);
        payable(receiver).transfer(amount);
    }

}
