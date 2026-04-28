/*
 * =======================
 * FULLY PATCHED (COMMIT-REVEAL ASYNCHRONOUS)
 * =======================
 */

pragma solidity ^0.8.0;

contract SecureRandomNumberGenerator {
    
    // Maps a user to the block number when they requested randomness
    mapping(address => uint256) public requestBlock;

    // STEP 1: The user commits to getting a random number.
    // They must call this in Transaction A.
    function requestRandomNumber() external {
        require(requestBlock[msg.sender] == 0, "Request already pending");
        requestBlock[msg.sender] = block.number;
    }

    // STEP 2: The user retrieves their random number in Transaction B.
    function getRandomNumber(uint256 max) external returns (uint256) {
        uint256 commitBlock = requestBlock[msg.sender];
        
        require(commitBlock > 0, "No pending randomness request");
        require(max > 0, "Max cannot be zero");
        require(block.number > commitBlock, "Must wait at least one block to resolve");
        
        // Ensure we do not fall victim to the 256-block EVM limit (which would result in a 0 hash)
        require(block.number - commitBlock <= 256, "Request expired. Blockhash pruned.");

        // Apply Checks-Effects-Interactions by clearing the request before generating the number
        requestBlock[msg.sender] = 0;

        // Generate entropy using the blockhash of the future block (relative to the request)
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            blockhash(commitBlock), 
            msg.sender
        )));

        return (entropy % max) + 1;
    }
}