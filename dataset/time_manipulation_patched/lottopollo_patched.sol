/*
 * =======================
 * FULLY PATCHED LOTTIPOLLO
 * =======================
 */

pragma solidity ^0.8.0;

contract lottopollo {
  address public leader;
  uint public timestamp;

  // PATCH 1: Added mapping for Pull-over-Push architecture to prevent DoS via Revert
  mapping(address => uint) public pendingWithdrawals;

  function payOut(uint rand) internal {
    
    // PATCH 2: Logic Flaw Fix
    // We MUST check against the stored state variable 'timestamp' instead of 'rand'
    // to determine if 24 hours have actually passed since the leader joined.
    if (timestamp > 0 && block.timestamp - timestamp > 24 hours) {
      
      uint callerRefund = msg.value;
      uint leaderPrize = address(this).balance - callerRefund;
      address winner = leader;

      // PATCH 3: Checks-Effects-Interactions
      // Reset the game state BEFORE allocating payouts to prevent reentrancy
      leader = address(0);
      timestamp = 0;

      // PATCH 4: Pull-over-Push Payouts
      // We safely allocate funds to pending withdrawals instead of using 
      // vulnerable .send() calls.
      if (callerRefund > 0) {
          pendingWithdrawals[msg.sender] += callerRefund;
      }
      
      if (leaderPrize > 0) {
          pendingWithdrawals[winner] += leaderPrize;
      }
    }
    else if (msg.value >= 1 ether) {
      // New leader takes over
      leader = msg.sender;
      timestamp = rand; // rand evaluates to block.timestamp, which is correct here
    } else {
        // PATCH 5: Safely refund invalid attempts to prevent trapped ETH
        if (msg.value > 0) {
            pendingWithdrawals[msg.sender] += msg.value;
        }
    }
  }

  function randomGen() view public returns(uint randomNumber) {
      return block.timestamp;   
  }

  // PATCH 6: Added the 'payable' modifier
  // The signature draw(uint256) remains identical, but the state mutability 
  // is updated so the contract no longer reverts when users send ETH to play.
  function draw(uint seed) public payable {
    uint randomNumber = randomGen(); 
    payOut(randomNumber);
  }

  // PATCH 7: Added to complete the Pull-over-Push architecture.
  // Allows users to safely claim their winnings or refunds.
  function withdrawPending() public {
      uint amount = pendingWithdrawals[msg.sender];
      require(amount > 0, "No pending withdrawals");
      
      // Zero balance before transfer to prevent reentrancy
      pendingWithdrawals[msg.sender] = 0;

      (bool success, ) = msg.sender.call{value: amount}("");
      require(success, "Withdrawal failed");
  }
}