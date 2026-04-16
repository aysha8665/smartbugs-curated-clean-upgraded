/*
 * SECURED VERSION
 * Fixes: Information Exposure (Front-Running) & Push Payment DoS
 */

pragma solidity ^0.8.0;

contract OddsAndEvens {
    struct Player {
        address addr;
        bytes32 commitment;
        uint number;
        bool hasRevealed;
    }

    Player[2] public players;
    uint8 public tot;
    address public owner;

    // Secure accounting pattern
    mapping(address => uint256) public pendingWithdrawals;

    constructor() {
        owner = msg.sender;
    }

    // PHASE 1: Commit
    // Players submit a hash of their number and a secret salt.
    // e.g., keccak256(abi.encodePacked(msg.sender, number, "my_secret_password"))
    function play(bytes32 commitment) payable public {
        require(msg.value == 1 ether, "Must send exactly 1 ether");
        require(tot < 2, "Game is full, waiting for reveals");

        players[tot] = Player({
            addr: msg.sender,
            commitment: commitment,
            number: 0,
            hasRevealed: false
        });
        tot++;
    }

    // PHASE 2: Reveal
    // Players expose their plaintext numbers and salts.
    function reveal(uint number, string memory salt) public {
        require(tot == 2, "Waiting for both players to commit");
        
        uint8 playerIndex = 2;
        if (players[0].addr == msg.sender) playerIndex = 0;
        else if (players[1].addr == msg.sender) playerIndex = 1;
        else revert("Not an active player");

        require(!players[playerIndex].hasRevealed, "Already revealed");
        
        // Verify the provided number and salt match the original commitment
        bytes32 expectedCommitment = keccak256(abi.encodePacked(msg.sender, number, salt));
        require(players[playerIndex].commitment == expectedCommitment, "Invalid reveal");

        players[playerIndex].number = number;
        players[playerIndex].hasRevealed = true;

        // If both have safely revealed, resolve the game
        if (players[0].hasRevealed && players[1].hasRevealed) {
            _calculateWinner();
        }
    }

    function _calculateWinner() private {
        uint n = players[0].number + players[1].number;
        
        // Update balances in state FIRST (Checks-Effects-Interactions)
        if (n % 2 == 0) {
            pendingWithdrawals[players[0].addr] += 1.8 ether;
        } else {
            pendingWithdrawals[players[1].addr] += 1.8 ether;
        }
        
        // Owner's cut
        pendingWithdrawals[owner] += 0.2 ether;

        // Reset game for the next round
        delete players;
        tot = 0;
    }

    // PHASE 3: Pull over Push
    // Players securely pull their own funds, eliminating DoS risks.
    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingWithdrawals[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}