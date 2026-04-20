/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract Private_Bank
{
    mapping (address => uint) public balances;
    
    uint public MinDeposit = 1 ether;
    
    Log TransferLog;
    
    constructor(address _log) payable {
        TransferLog = Log(_log);
    }
    
    function Deposit()
    public
    payable
    {
        require(msg.value > MinDeposit, "Deposit must be greater than minimum");
        balances[msg.sender]+=msg.value;
        TransferLog.AddMessage(msg.sender,msg.value,"Deposit");
    }
    
    function CashOut(uint _am) public payable {
        require(_am<=balances[msg.sender], "Not enough balance");
            
        // 1. EFFECT
        balances[msg.sender]-=_am;
        
        // 2. INTERACTION
        (bool success, ) = msg.sender.call{value: _am}(""); 
        
        // 3. DEFENSE (Revert state if transfer fails)
        require(success, "Transfer failed");
        
        // 4. LOGGING
        TransferLog.AddMessage(msg.sender,_am,"CashOut");
    }
    
    receive() external payable {}    
    
}

contract Log 
{
   
    struct Message
    {
        address Sender;
        string  Data;
        uint Val;
        uint  Time;
    }
    
    Message[] public History;
    
    Message LastMsg;
    
    function AddMessage(address _adr,uint _val, string memory _data)
    public
    {
        LastMsg.Sender = _adr;
        LastMsg.Time = block.timestamp;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}
