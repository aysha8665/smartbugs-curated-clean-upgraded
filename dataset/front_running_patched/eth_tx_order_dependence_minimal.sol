/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract EthTxOrderDependenceMinimal {
    address public owner;
    bool public claimed;
    uint public reward;

    constructor() payable {
        owner = msg.sender;
    }

    function setReward() public payable {
        require (!claimed);

        require(msg.sender == owner);
        
        payable(owner).transfer(reward);
        reward = msg.value;
    }

    function claimReward(uint256 submission) public {
        require (!claimed);
        require(submission < 10);
        
        payable(msg.sender).transfer(reward);
        claimed = true;
    }
}
