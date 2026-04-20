/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract PERSONAL_BANK
{
    mapping (address=>uint256) public balances;   
   
    uint public MinSum = 1 ether;
    
    LogFile Log = LogFile(0x0486cF65A2F2F3A392CBEa398AFB7F5f0B72FF46);
    
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
        Log = LogFile(_log);
    }
    
    function Initialized()
    public
    {
        intitalized = true;
    }
    
    function Deposit()
    public
    payable
    {
        balances[msg.sender]+= msg.value;
        Log.AddMessage(msg.sender,msg.value,"Put");
    }
    
    function Collect(uint _am) public payable {
        require(balances[msg.sender]>=MinSum && balances[msg.sender]>=_am, "Not enough balance or too soon to withdraw");

        // 1. EFFECT
        balances[msg.sender]-=_am;

        // 2. INTERACTION
        (bool success, ) = msg.sender.call{value: _am}(""); 
        
        // 3. DEFENSE (Revert state if transfer fails)
        require(success, "Transfer failed");
        
        // 4. LOGGING
        Log.AddMessage(msg.sender,_am,"Collect");

    }
    
    
    receive() external payable {
        Deposit();
    }
    
}



contract LogFile
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
