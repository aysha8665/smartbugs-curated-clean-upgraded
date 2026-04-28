/*
 * =======================
 * FULLY PATCHED TIMED CROWDSALE
 * =======================
 */

pragma solidity ^0.8.0;

contract TimedCrowdsale {
  // PATCH: Replaced the raw UNIX timestamp with a Target Block Number.
  // Assuming a 12-15 second average block time, you calculate the block height
  // that roughly corresponds to January 1, 2019 (e.g., Block ~7,000,000).
  uint256 public constant TARGET_BLOCK = 7000000;

  // Signature Preserved perfectly
  function isSaleFinished() view public returns (bool) {
    // Evaluation now relies on the deterministic block height, 
    // removing all miner manipulation vectors.
    return block.number >= TARGET_BLOCK;
  }
}