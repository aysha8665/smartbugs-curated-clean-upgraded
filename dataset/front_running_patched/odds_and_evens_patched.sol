/*
 * SECURED VERSION v2
 * Fixes: Front-Running, Push Payment DoS, AND Commit-Reveal Deadlock
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
    mapping(address => uint256) public pendingWithdrawals;
    
    // NEW: Private state variable. Does not alter public ABI.
    uint256 private revealDeadline;

    constructor() {
        owner = msg.sender;
    }

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
        
        // NEW: Start the timeout clock when the second player commits
        if (tot == 2) {
            revealDeadline = block.timestamp + 24 hours;
        }
    }

    function reveal(uint number, string memory salt) public {
        require(tot == 2, "Waiting for both players to commit");
        
        // NEW: Prevent reveals after the deadline
        require(block.timestamp <= revealDeadline, "Reveal phase expired");

        uint8 playerIndex = 2;
        if (players[0].addr == msg.sender) playerIndex = 0;
        else if (players[1].addr == msg.sender) playerIndex = 1;
        else revert("Not an active player");

        require(!players[playerIndex].hasRevealed, "Already revealed");
        
        bytes32 expectedCommitment = keccak256(abi.encodePacked(msg.sender, number, salt));
        require(players[playerIndex].commitment == expectedCommitment, "Invalid reveal");

        players[playerIndex].number = number;
        players[playerIndex].hasRevealed = true;

        if (players[0].hasRevealed && players[1].hasRevealed) {
            _calculateWinner();
        }
    }

    function _calculateWinner() private {
        uint n = players[0].number + players[1].number;
        if (n % 2 == 0) {
            pendingWithdrawals[players[0].addr] += 1.8 ether;
        } else {
            pendingWithdrawals[players[1].addr] += 1.8 ether;
        }
        
        pendingWithdrawals[owner] += 0.2 ether;
        
        delete players;
        tot = 0;
    }

    // NEW: Internal deadlock resolver
    function _resolveDeadlock() private {
        bool p0Revealed = players[0].hasRevealed;
        bool p1Revealed = players[1].hasRevealed;

        if (p0Revealed && !p1Revealed) {
            // Player 0 revealed, Player 1 griefed. Player 0 wins by default.
            pendingWithdrawals[players[0].addr] += 1.8 ether;
            pendingWithdrawals[owner] += 0.2 ether;
        } else if (!p0Revealed && p1Revealed) {
            // Player 1 revealed, Player 0 griefed. Player 1 wins by default.
            pendingWithdrawals[players[1].addr] += 1.8 ether;
            pendingWithdrawals[owner] += 0.2 ether;
        } else {
            // Both failed to reveal. Refund both to prevent permanently locked ether.
            // Note: The owner gets no cut here, but logic could be adjusted.
            pendingWithdrawals[players[0].addr] += 1 ether;
            pendingWithdrawals[players[1].addr] += 1 ether;
        }
        
        // Reset game
        delete players;
        tot = 0;
    }

    function withdraw() public {
        // NEW: Implicit state resolution if the game timed out
        if (tot == 2 && block.timestamp > revealDeadline) {
            _resolveDeadlock();
        }

        uint amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingWithdrawals[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}