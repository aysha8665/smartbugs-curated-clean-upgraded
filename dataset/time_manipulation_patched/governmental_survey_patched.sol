/*
 * =======================
 * FULLY PATCHED GOVERNMENTAL
 * =======================
 */

pragma solidity ^0.8.0;

contract Governmental {
    address public owner;
    address public lastInvestor;
    uint public jackpot = 1 ether;
    uint public lastInvestmentTimestamp;
    uint public ONE_MINUTE = 1 minutes;

    // PATCH 1: Added mapping for Pull-over-Push architecture
    // This safely catches failed payouts without reverting the whole system
    mapping(address => uint) public pendingWithdrawals;

    constructor() payable {
        owner = msg.sender;
        require(msg.value >= 1 ether, "Requires at least 1 ether to seed the jackpot");
    }

    // Signature Preserved
    function invest() public payable {
        require(msg.value >= jackpot / 2, "Investment must be at least half the jackpot");
        lastInvestor = msg.sender;
        jackpot += msg.value / 2;
        
        lastInvestmentTimestamp = block.timestamp;
    }

    // Signature Preserved
    function resetInvestment() public {
        require(block.timestamp >= lastInvestmentTimestamp + ONE_MINUTE, "Game is still active");

        uint winnerPayout = jackpot;
        address winner = lastInvestor;

        // PATCH 2: Safe Owner Accounting
        // The owner receives whatever is left over after paying the winner AND reserving 
        // the 1 ETH required to seed the next round. This prevents underflow reverts.
        uint ownerPayout = 0;
        if (address(this).balance >= winnerPayout + 1 ether) {
            ownerPayout = address(this).balance - winnerPayout - 1 ether;
        }

        // PATCH 3: Checks-Effects-Interactions Pattern
        // We reset the game state completely BEFORE interacting with external addresses
        lastInvestor = address(0);
        jackpot = 1 ether;
        lastInvestmentTimestamp = 0;

        // PATCH 4: Pull-over-Push Execution
        // We use modern .call and isolate failures. If a transfer fails (due to gas limits
        // or intentional rejection), the funds are credited to pendingWithdrawals.
        if (winner != address(0)) {
            (bool winSuccess, ) = winner.call{value: winnerPayout}("");
            if (!winSuccess) {
                pendingWithdrawals[winner] += winnerPayout;
            }
        }

        if (ownerPayout > 0) {
            (bool ownerSuccess, ) = owner.call{value: ownerPayout}("");
            if (!ownerSuccess) {
                pendingWithdrawals[owner] += ownerPayout;
            }
        }
    }

    // PATCH 5: Required to complete the Pull-over-Push architecture.
    // Allows users to manually claim funds if their automated payout failed.
    function withdrawPending() public {
        uint amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawals");
        
        // Zero balance before transfer to prevent reentrancy
        pendingWithdrawals[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }
}