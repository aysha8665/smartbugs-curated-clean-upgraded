/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract FindThisHash {
    bytes32 constant public hash = 0xb5b5b97fafd9855eec9b41f74dfb6c38f5951141f9a3ecd7f44d5479b630ee0a;

    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public commitBlock;

    constructor() payable {} // load with ether

    function commit(bytes32 solutionHash) public {
        commitments[msg.sender] = solutionHash;
        commitBlock[msg.sender] = block.number;
    }

    function solve(string memory solution) public {
        // Must have committed in a previous block
        require(commitBlock[msg.sender] > 0 && commitBlock[msg.sender] < block.number, "Must commit first");
        require(commitments[msg.sender] == keccak256(abi.encodePacked(msg.sender, solution)), "Commitment mismatch");
        require(hash == keccak256(abi.encodePacked(solution)));
        payable(msg.sender).transfer(1000 ether);
    }
}
