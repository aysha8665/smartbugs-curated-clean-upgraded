/*
 * @source: http://blockchain.unica.it/projects/ethereum-survey/attacks.html#simpledao
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract SimpleDAO {
  bool private _locked;
  mapping (address => uint) public credit;

  function donate(address to) payable public {
    credit[to] += msg.value;
  }

  function withdraw(uint amount) public {
    require(!_locked, "ReentrancyGuard: reentrant call");
    _locked = true;
    if (credit[msg.sender]>= amount) {
      credit[msg.sender]-=amount;
      (bool res, ) = msg.sender.call{value: amount}("");
    }
    _locked = false;
  }

  function queryCredit(address to) public returns(uint) {
    return credit[to];
  }
}
