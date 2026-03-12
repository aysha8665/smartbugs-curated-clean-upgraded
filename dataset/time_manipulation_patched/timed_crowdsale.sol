/*
 * @source: https://github.com/SmartContractSecurity/SWC-registry/blob/master/test_cases/timestamp_dependence/timed_crowdsale.sol
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract TimedCrowdsale {
  // Sale should finish exactly at January 1, 2019
  function isSaleFinished() view public returns (bool) {
    
    // Use block.number-based timing to reduce miner manipulation
    // 1546300800 = Jan 1 2019 ~= block 7000000 on mainnet
    return block.number >= 7000000;
  }
}
