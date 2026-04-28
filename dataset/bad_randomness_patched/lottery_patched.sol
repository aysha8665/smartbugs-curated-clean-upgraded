/*
 * =======================
 * FULLY PATCHED LOTTERY
 * =======================
 */

pragma solidity ^0.8.0;

contract Lottery {
    event GetBet(uint betAmount, uint blockNumber, bool won);
    event BetPlaced(address indexed player, uint blockNumber);
    event BetResolved(address indexed player, uint payout, bool won);

    struct Bet {
        uint betAmount;
        uint blockNumber;
        bool resolved;
        bool won;
        address player;
    }

    address private organizer;
    Bet[] private bets;
    
    // Mapping to track a player's active bet to prevent multiple unresolved bets
    mapping(address => uint) public pendingBetId;
    mapping(address => bool) public hasPendingBet;

    constructor() payable {
        organizer = msg.sender;
    }

    receive() external payable {
        revert("Use makeBet() to play");
    }

    // ==========================================
    // STEP 1: THE COMMIT PHASE
    // ==========================================
    function makeBet() public payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(!hasPendingBet[msg.sender], "You must resolve your pending bet first");

        // Record the bet and the current block number
        bets.push(Bet({
            betAmount: msg.value,
            blockNumber: block.number,
            resolved: false,
            won: false,
            player: msg.sender
        }));

        pendingBetId[msg.sender] = bets.length - 1;
        hasPendingBet[msg.sender] = true;

        emit BetPlaced(msg.sender, block.number);
    }

    // ==========================================
    // STEP 2: THE REVEAL/RESOLVE PHASE
    // ==========================================
    function resolveBet() public {
        require(hasPendingBet[msg.sender], "No pending bet found");
        
        uint betIndex = pendingBetId[msg.sender];
        Bet storage myBet = bets[betIndex];

        // REQUIRED: The bet must be resolved in a FUTURE block. 
        // This makes atomic smart contract simulation impossible.
        require(block.number > myBet.blockNumber, "Cannot resolve bet in the same block");

        // Apply Checks-Effects-Interactions pattern: Update state BEFORE paying out
        myBet.resolved = true;
        hasPendingBet[msg.sender] = false;

        // Security Check: The EVM only stores the last 256 block hashes.
        // If the user waits too long, they forfeit the bet to prevent exploiting 0-hashes.
        if (block.number - myBet.blockNumber > 256) {
            myBet.won = false;
            emit BetResolved(msg.sender, 0, false);
            return; 
        }

        // Generate entropy using the hash of the block where the bet was locked in
        uint256 entropy = uint256(keccak256(abi.encodePacked(blockhash(myBet.blockNumber), msg.sender)));
        bool won = (entropy % 2) == 0;
        myBet.won = won;

        // Handle Payout
        if (won) {
            uint payout = myBet.betAmount; // Original logic: refunds the bet value
            
            // Safely transfer ETH using .call to prevent 2300 gas limit failures
            (bool success, ) = msg.sender.call{value: payout}("");
            require(success, "Payout failed");
            
            emit BetResolved(msg.sender, payout, true);
        } else {
            emit BetResolved(msg.sender, 0, false);
        }
    }

    // ==========================================
    // UTILITY FUNCTIONS
    // ==========================================
    function getBets() public {
        require(msg.sender == organizer, "Only organizer can view bets");

        for (uint i = 0; i < bets.length; i++) {
            // Only emit resolved bets to match original return structure safely
            if (bets[i].resolved) {
                emit GetBet(bets[i].betAmount, bets[i].blockNumber, bets[i].won);
            }
        }
    }

    function destroy() public {
        require(msg.sender == organizer, "Only organizer can destroy");
        selfdestruct(payable(organizer));
    }
}