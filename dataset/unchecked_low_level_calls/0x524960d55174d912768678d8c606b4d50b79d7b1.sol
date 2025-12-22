/*
 * @source: etherscan.io 
 * @author: -
 *=======================
 */

pragma solidity ^0.8.0;

contract Centra4 {

	function transfer() public returns(bool) {	
		address contract_address;
		contract_address = 0x96A65609a7B84E8842732DEB08f56C3E21aC6f8a;
		address c1;		
		address c2;
		uint256 k;
		k = 1;
		
		c2 = 0xAa27f8C1160886aacba64B2319D8d5469ef2Af79;	
			
		contract_address.call(abi.encodeWithSignature("register(string)", "CentraToken"));
		(bool success, ) = contract_address.call(abi.encodeWithSignature("transfer(address,uint256)", c2, k)); if(!success) return false;

		return true;
	}

}