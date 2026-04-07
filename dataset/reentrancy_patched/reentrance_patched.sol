/*
 * @source: https://ethernaut.zeppelin.solutions/level/0xf70706db003e94cfe4b5e27ffd891d5c81b39488
 * @author: Alejandro Santander
 * =======================
 */

pragma solidity ^0.8.0;

contract Reentrance {

  bool private _locked;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] += msg.value;
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    require(!_locked, "ReentrancyGuard: reentrant call");
    _locked = true;

    if(balances[msg.sender] >= _amount) {
      
      // 1. EFFECT (State updated first)
      balances[msg.sender] -= _amount;
      
      // 2. INTERACTION (External call)
      (bool success, ) = msg.sender.call{value: _amount}("");
      
      // 3. DEFENSE (Revert the entire state if the transfer fails)
      require(success, "Transfer failed"); 
    }
    
    _locked = false;
  }

  receive() external payable {}
}
