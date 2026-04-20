/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract ETH_VAULT
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
        require(msg.value > MinDeposit, "Deposit must be greater than minimum"); // 1. Check
        balances[msg.sender]+=msg.value;
        TransferLog.AddMessage(msg.sender,msg.value,"Deposit");

    }

    function CashOut(uint _am) public payable {
        require(_am <= balances[msg.sender], "Not enough balance"); // 1. Check
        // 1. Effect: Update state first
        balances[msg.sender] -= _am;
        
        // 2. Interaction: Perform the external call
        (bool success, ) = msg.sender.call{value: _am}("");
        
        // 3. Validation: Revert the entire transaction if the call fails
        require(success, "Transfer failed."); 
        
        // 4. Log: Only executes if the require statement passes
        TransferLog.AddMessage(msg.sender, _am, "CashOut");

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
