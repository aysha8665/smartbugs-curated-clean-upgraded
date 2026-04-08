/*
 * @source: https://github.com/ConsenSys/evm-analyzer-benchmark-suite
 * @author: Suhabe Bugrara
 * =======================
 */

pragma solidity ^0.8.0;

contract ReentrancyDAO {
    bool private _locked;
    mapping (address => uint) credit;
    uint balance;

    function withdrawAll() public {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        uint oCredit = credit[msg.sender];
        if (oCredit > 0) {
            credit[msg.sender] = 0;
            balance -= oCredit;
            (bool callResult, ) = msg.sender.call{value: oCredit}("");
            require (callResult);
        }
        _locked = false;
    }

    function deposit() public payable {
        credit[msg.sender] += msg.value;
        balance += msg.value;
    }
}
