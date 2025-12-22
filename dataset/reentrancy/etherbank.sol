/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;
contract EtherBank{
    mapping (address => uint) userBalances;
    function getBalance(address user) view public returns(uint) {  
		return userBalances[user];
	}

	function addToBalance() public {  
		userBalances[msg.sender] += msg.value;
	}

	function withdrawBalance() public {  
		uint amountToWithdraw = userBalances[msg.sender];
        
		(bool success, ) = msg.sender.call{value: amountToWithdraw}(""); if (!success) { revert(); }
		userBalances[msg.sender] = 0;
	}    
}