/*
 * =======================
 * FULLY PATCHED ROULETTE (COMMIT-REVEAL)
 * =======================
 */

pragma solidity ^0.8.0;

contract Roulette {
    uint public constant BET_AMOUNT = 10 ether;

    struct Bet {
        uint256 commitBlock;
        bool active;
    }

    mapping(address => Bet) public bets;

    constructor() payable {} // initially fund contract

    // ==========================================
    // STEP 1: THE COMMIT PHASE
    // ==========================================
    function placeBet() external payable {
        require(msg.value == BET_AMOUNT, "Must send exactly 10 ether to play");
        require(!bets[msg.sender].active, "You already have an active bet");

        // Lock the bet to the current block. 
        // The randomness will be derived from the hash of this block, 
        // which cannot be known until the transaction is mined.
        bets[msg.sender] = Bet({
            commitBlock: block.number,
            active: true
        });
    }

    // ==========================================
    // STEP 2: THE REVEAL/RESOLVE PHASE
    // ==========================================
    function resolveBet() external {
        Bet storage myBet = bets[msg.sender];
        
        require(myBet.active, "No active bet found");
        require(block.number > myBet.commitBlock, "Cannot resolve bet in the same block");

        // Prevent the EVM 256-block hash expiration exploit.
        // If the user waits more than 256 blocks, blockhash() returns 0.
        // We enforce a timeout so an attacker cannot weaponize 0-hashes.
        require(block.number - myBet.commitBlock <= 256, "Bet expired. Blockhash pruned.");

        // Checks-Effects-Interactions (CEI) Pattern: 
        // We clear the user's state BEFORE making any external calls to prevent Reentrancy.
        uint256 commitBlock = myBet.commitBlock;
        myBet.active = false;
        myBet.commitBlock = 0;

        // Generate entropy using the hash of the block where the bet was placed.
        // We include msg.sender so multiple people in the same block get different outcomes.
        uint256 entropy = uint256(keccak256(abi.encodePacked(blockhash(commitBlock), msg.sender)));

        // 1 in 15 chance to win, mimicking the original block.timestamp % 15 == 0 logic
        if (entropy % 15 == 0) {
            uint256 prize = address(this).balance;

            // Use modern .call{value: ...}("") to safely forward ETH to smart-contract wallets
            (bool success, ) = msg.sender.call{value: prize}("");
            require(success, "Payout failed");
        }
    }
}