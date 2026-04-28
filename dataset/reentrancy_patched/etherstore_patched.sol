/*
 * =======================
 * =======================
 * =======================
 */

//added pragma version
pragma solidity ^0.8.0;

contract EtherStore {

    bool private _locked;
    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;

    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds (uint256 _weiToWithdraw) public {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        require(balances[msg.sender] >= _weiToWithdraw);
        
        require(_weiToWithdraw <= withdrawalLimit, "Withdrawal amount exceeds the limit");
        
        require(block.timestamp >= lastWithdrawTime[msg.sender] + 1 weeks);
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = block.timestamp;
        (bool success, ) = msg.sender.call{value: _weiToWithdraw}(""); 
        require(success, "Failed to withdraw funds");
        _locked = false;
    }
 }
