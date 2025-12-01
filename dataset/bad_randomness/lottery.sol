/*
 * =======================
 * =======================
 * =======================
 * =======================
 */

 //added pragma version
  pragma solidity ^0.8.0;
  
 contract Lottery {
     event GetBet(uint betAmount, uint blockNumber, bool won);

     struct Bet {
         uint betAmount;
         uint blockNumber;
         bool won;
     }

     address private organizer;
     Bet[] private bets;

     // Create a new lottery with numOfBets supported bets.
     constructor() payable {
         organizer = msg.sender;
     }

     // Fallback function returns ether
     function() {
         revert();
     }

     // Make a bet
     function makeBet() public {
         // Won if block number is even
         
         
         bool won = (block.number % 2) == 0;

         // Record the bet with an event
         
         bets.push(Bet(msg.value, block.number, won));

         // Payout if the user won, otherwise take their money
         if(won) {
             if(!payable(msg.sender).send(msg.value)) {
                 // Return ether to sender
                 revert();
             }
         }
     }

     // Get all bets that have been made
     function getBets() public {
         if(msg.sender != organizer) { revert(); }

         for (uint i = 0; i < bets.length; i++) {
             emit GetBet(bets[i].betAmount, bets[i].blockNumber, bets[i].won);
         }
     }

     // Suicide :(
     function destroy() public {
         if(msg.sender != organizer) { revert(); }

         selfdestruct(payable(organizer));
     }
 }
