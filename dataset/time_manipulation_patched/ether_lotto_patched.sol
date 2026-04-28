/*
 * =======================
 * FULLY PATCHED ETHER LOTTO (COMMIT-REVEAL)
 * =======================
 */

pragma solidity ^0.8.0;

contract EtherLotto {

    uint constant TICKET_AMOUNT = 10;
    uint constant FEE_AMOUNT = 1;

    address public bank;
    uint public pot;

    // Mapping to track when a player bought their ticket
    mapping(address => uint256) public ticketBlock;

    event TicketPurchased(address indexed player, uint blockNumber);
    event LotteryResolved(address indexed player, bool won, uint payout);

    constructor() payable {
        bank = msg.sender;
    }

    // ==========================================
    // STEP 1: THE COMMIT PHASE (Buy Ticket)
    // ==========================================
    function play() payable public {
        require(msg.value == TICKET_AMOUNT, "Ticket costs exactly 10 wei");
        require(ticketBlock[msg.sender] == 0, "You already have an unresolved ticket");

        pot += msg.value;
        
        // Lock the bet to the current block. 
        // The randomness will be derived from a FUTURE block.
        ticketBlock[msg.sender] = block.number;

        emit TicketPurchased(msg.sender, block.number);
    }

    // ==========================================
    // STEP 2: THE REVEAL PHASE (Resolve Ticket)
    // ==========================================
    function resolve() public {
        uint256 commitBlock = ticketBlock[msg.sender];
        
        require(commitBlock > 0, "No ticket found");
        require(block.number > commitBlock, "Cannot resolve in the same block as purchase");

        // The EVM only stores the last 256 block hashes.
        // If the user waits too long, the hash becomes 0x0. They forfeit to prevent exploits.
        require(block.number - commitBlock <= 256, "Ticket expired. Blockhash pruned.");

        // Checks-Effects-Interactions: Clear the ticket state BEFORE evaluating payouts
        // This prevents Reentrancy attacks
        ticketBlock[msg.sender] = 0;

        // Generate entropy using the hash of the block where the ticket was purchased
        // combined with the player's address to prevent identical results for all players in that block
        uint256 entropy = uint256(keccak256(abi.encodePacked(blockhash(commitBlock), msg.sender)));
        
        uint random = entropy % 2;

        if (random == 0) {
            // Calculate payout
            uint payout = pot - FEE_AMOUNT;
            pot = 0; // Restart jackpot

            // Use modern .call instead of .transfer to prevent DoS via Revert
            (bool feeSuccess, ) = bank.call{value: FEE_AMOUNT}("");
            require(feeSuccess, "Bank fee transfer failed");

            (bool winSuccess, ) = msg.sender.call{value: payout}("");
            require(winSuccess, "Winner payout failed");

            emit LotteryResolved(msg.sender, true, payout);
        } else {
            emit LotteryResolved(msg.sender, false, 0);
        }
    }
}