/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;
contract EtherBank{
    mapping (address => uint) userBalances;
    bool private _locked;
    function getBalance(address user) view public returns(uint) {  
		return userBalances[user];
	}

	function addToBalance() public payable {
		userBalances[msg.sender] += msg.value;
	}

	function withdrawBalance() public {  
		require(!_locked, "ReentrancyGuard: reentrant call");
		_locked = true;
		uint amountToWithdraw = userBalances[msg.sender];
		userBalances[msg.sender] = 0;
		(bool success, ) = msg.sender.call{value: amountToWithdraw}(""); if (!success) { revert(); }
		_locked = false;
	}    
}