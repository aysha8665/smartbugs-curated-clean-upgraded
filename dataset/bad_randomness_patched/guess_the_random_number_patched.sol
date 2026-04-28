/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract GuessTheRandomNumberChallenge {
    // We remove the stored 'answer' state variable to prevent off-chain reads.

    constructor() payable {
        // Signature preserved
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        // Signature preserved
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        // Signature preserved
        require(msg.value == 1 ether);

        // Dynamically compute the answer at the exact moment of execution
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));

        if (n == answer) {
            payable(msg.sender).transfer(2 ether);
        }
    }
}