/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract RealOldFuckMaker {
    address fuck = 0xc63e7b1DEcE63A77eD7E4Aeef5efb3b05C81438D;
    
    // this can make OVER 9,000 OLD FUCKS
    // (just pass in 129)
    function makeOldFucks(uint32 number) public {
        uint32 i;
        for (i = 0; i < number; i++) {
           
            (bool success, ) = fuck.call(abi.encodeWithSignature("giveBlockReward()"));
        }
    }
}