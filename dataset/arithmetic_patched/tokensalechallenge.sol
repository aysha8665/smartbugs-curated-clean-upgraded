/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract TokenSaleChallenge {
    mapping(address => uint256) public balanceOf;
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    constructor(address _player)  payable  {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance < 1 ether;
    }

    function buy(uint256 numTokens) public payable {
        
        require(numTokens > 0, "Must buy at least one token");
        require(msg.value == numTokens * PRICE_PER_TOKEN);
       
        balanceOf[msg.sender] += numTokens;
    }

    function sell(uint256 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);

        balanceOf[msg.sender] -= numTokens;
        
        payable(msg.sender).transfer(numTokens * PRICE_PER_TOKEN);
    }
}
