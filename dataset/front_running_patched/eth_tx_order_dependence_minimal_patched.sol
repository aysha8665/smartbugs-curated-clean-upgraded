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

        require(msg.value >= reward, "Cannot decrease the reward");
        
        uint oldReward = reward;
        reward = msg.value;
        
        payable(owner).transfer(oldReward);

    }

    function claimReward(uint256 submission) public {
        require (!claimed);
        require(submission < 10);
        claimed = true;
        payable(msg.sender).transfer(reward);
        
    }
}
