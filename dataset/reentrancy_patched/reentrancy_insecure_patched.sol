/*
 * @source: https://consensys.github.io/smart-contract-best-practices/known_attacks/
 * @author: consensys
 * =======================
 */

pragma solidity ^0.8.0;

contract Reentrancy_insecure {

    bool private _locked;
    mapping (address => uint) private userBalances;

    function deposit() public payable {
        require(msg.value > 0, "Deposit value must be > 0");
        userBalances[msg.sender] += msg.value;
    }

    function withdrawBalance() public {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        uint amountToWithdraw = userBalances[msg.sender];
        userBalances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
        _locked = false;
    }
}
