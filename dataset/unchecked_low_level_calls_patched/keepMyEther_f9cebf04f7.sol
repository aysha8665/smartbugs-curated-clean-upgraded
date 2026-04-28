/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

/*
=======================

=======================
=======================
*/

contract keepMyEther {
    mapping(address => uint256) public balances;
    
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        
        (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(success, "Failed to call sender contract");
        balances[msg.sender] = 0;
    }
}
