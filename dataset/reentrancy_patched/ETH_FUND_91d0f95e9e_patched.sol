/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract ETH_FUND
{
    mapping (address => uint) public balances;
    
    uint public MinDeposit = 1 ether;
    
    Log TransferLog;
    
    uint lastBlock;
    
    constructor(address _log) payable {
        TransferLog = Log(_log);
    }
    
    function Deposit()
    public
    payable
    {
        require(msg.value > MinDeposit, "Deposit must be greater than minimum"); // 1. Check

        balances[msg.sender]+=msg.value;
        TransferLog.AddMessage(msg.sender,msg.value,"Deposit");
        lastBlock = block.number;

    }
    
    function CashOut(uint _am) public payable {
        require(_am<=balances[msg.sender] && block.number>lastBlock ,"Not enough balance or too soon to withdraw"); // 1. Check
            
        // 1. Effect: Deduct balance first to prevent reentrancy
        balances[msg.sender]-=_am; 
        
        // 2. Interaction: Execute the external call
        (bool success, ) = msg.sender.call{value: _am}(""); 
        
        // 3. Validation: Revert the entire state if the transfer fails
        require(success, "Transfer failed"); 
        
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
