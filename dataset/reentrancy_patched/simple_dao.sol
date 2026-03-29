pragma solidity ^0.8.0;

contract SimpleDAO {
  bool private _locked;
  mapping (address => uint) public credit;

  function donate(address to) payable public {
    credit[to] += msg.value;
  }

  function withdraw(uint amount) public {
    // 1. Guard Check
    require(!_locked, "ReentrancyGuard: reentrant call");
    _locked = true;
    
    // 2. Balance Check
    require(credit[msg.sender] >= amount, "Insufficient balance");

    // 3. Effect
    credit[msg.sender] -= amount;

    // 4. Interaction
    (bool success, ) = msg.sender.call{value: amount}("");
    
    // 5. CRITICAL: Handle Failure
    require(success, "Transfer failed"); 

    // 6. Release Guard
    _locked = false;
  }

  function queryCredit(address to) public view returns(uint) {
    return credit[to];
  }
}