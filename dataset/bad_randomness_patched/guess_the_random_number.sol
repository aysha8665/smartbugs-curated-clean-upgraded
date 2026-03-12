/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract GuessTheRandomNumberChallenge {
    bytes32 private answerHash;
    address private owner;

    constructor(bytes32 _answerHash)  payable  {
        require(msg.value == 1 ether);
        owner = msg.sender;
        answerHash = _answerHash;
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);

        if (keccak256(abi.encodePacked(n)) == answerHash) {
            payable(msg.sender).transfer(2 ether);
        }
    }
}
