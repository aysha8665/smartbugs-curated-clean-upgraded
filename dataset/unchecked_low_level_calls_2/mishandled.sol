/*
 * @source: https://github.com/seresistvanandras/EthBench/blob/master/Benchmark/Simple/mishandled.sol 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;
contract SendBack {
    mapping (address => uint) userBalances;
    function withdrawBalance() public {  
		uint amountToWithdraw = userBalances[msg.sender];
		userBalances[msg.sender] = 0;
        
		payable(msg.sender).send(amountToWithdraw);
	}
}