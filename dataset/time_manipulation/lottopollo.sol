/*
 * @source: https://github.com/seresistvanandras/EthBench/blob/master/Benchmark/Simple/timestampdependent.sol
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;
contract lottopollo {
  address leader;
  uint    timestamp;
  function payOut(uint rand) internal {
    
    if ( rand> 0 && block.timestamp - rand > 24 hours ) {
      payable(msg.sender).send( msg.value );

      if ( address(this).balance > 0 ) {
        payable(leader).send( address(this).balance );
      }
    }
    else if ( msg.value >= 1 ether ) {
      leader = msg.sender;
      timestamp = rand;
    }
  }
  function randomGen() view public returns(uint randomNumber) {
      
      return block.timestamp;   
    }
  function draw(uint seed) public {
    uint randomNumber=randomGen(); 
    payOut(randomNumber);
  }
}