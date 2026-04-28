/*
 * =======================
 * FULLY PATCHED PREDICT THE BLOCK HASH
 * =======================
 */

pragma solidity ^0.8.0;

contract PredictTheBlockHashChallenge {

    struct guess {
      uint block;
      bytes32 guess;
    }

    mapping(address => guess) guesses;

    constructor() payable {
        require(msg.value == 1 ether, "Requires 1 ether to deploy");
    }

    function lockInGuess(bytes32 hash) public payable {
        // Prevent users from overwriting an active, unsettled guess
        require(guesses[msg.sender].block == 0, "You already have a guess locked in");
        require(msg.value == 1 ether, "Requires exactly 1 ether");

        guesses[msg.sender].guess = hash;
        guesses[msg.sender].block = block.number + 1;
    }

    function settle() public {
        uint targetBlock = guesses[msg.sender].block;
        
        // Ensure the user actually has a locked-in guess before proceeding
        require(targetBlock > 0, "No guess locked in");
        require(block.number > targetBlock, "Target block has not been mined yet");

        // PATCH 1: The 256-Block Window Limit
        // We strictly enforce that the settlement must happen before the EVM prunes the block hash.
        // If the user waits too long, they forfeit the bet because the outcome can no longer be cryptographically verified.
        require(block.number - targetBlock <= 256, "Block hash is no longer available. Bet forfeited.");
        
        bytes32 answer = blockhash(targetBlock);

        // PATCH 2: Checks-Effects-Interactions Pattern
        // We cache the guess in memory and wipe the storage BEFORE the external transfer.
        // This prevents Reentrancy attacks where a malicious fallback function calls settle() repeatedly.
        bytes32 userGuess = guesses[msg.sender].guess;
        
        guesses[msg.sender].block = 0;
        guesses[msg.sender].guess = bytes32(0);

        if (userGuess == answer) {
            // Because we zeroed out the state above, this transfer is now safe from reentrancy
            payable(msg.sender).transfer(2 ether);
        }
    }
}