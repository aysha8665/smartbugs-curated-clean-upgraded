/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract MONEY_BOX   
{
    struct Holder   
    {
        uint unlockTime;
        uint balance;
    }
    
    mapping (address => Holder) public Acc;
    
    uint public MinSum;
    
    Log LogFile;
    
    bool intitalized;
    
    function SetMinSum(uint _val)
    public
    {
        if(intitalized)revert();
        MinSum = _val;
    }
    
    function SetLogFile(address _log)
    public
    {
        if(intitalized)revert();
        LogFile = Log(_log);
    }
    
    function Initialized()
    public
    {
        intitalized = true;
    }
    
    function Put(uint _lockTime)
    public
    payable
    {
        Holder storage acc = Acc[msg.sender];
        acc.balance += msg.value;
        if(block.timestamp+_lockTime>acc.unlockTime)acc.unlockTime=block.timestamp+_lockTime;
        LogFile.AddMessage(msg.sender,msg.value,"Put");
    }
    
    function Collect(uint _am) public payable {
        Holder storage acc = Acc[msg.sender];
    
        // 1. Checks
        if( acc.balance>=MinSum && acc.balance>=_am && block.timestamp>acc.unlockTime) {
            
            // 2. Effects
            acc.balance -= _am;
            
            // 3. Interactions
            (bool success, ) = msg.sender.call{value: _am}(""); 
            
            // 4. Validation (Crucial addition)
            require(success, "Transfer failed."); 
            
            // 5. Logging (Only reachable if the transfer succeeded)
            LogFile.AddMessage(msg.sender, _am, "Collect");
        }
    }
    
    receive() external payable {
        Put(0);
    }
    
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
