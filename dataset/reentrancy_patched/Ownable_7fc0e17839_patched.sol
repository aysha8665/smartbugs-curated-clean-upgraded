/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract Ownable
{
    address newOwner;
    address owner = msg.sender;
    
    function changeOwner(address addr)
    public
    onlyOwner
    {
        newOwner = addr;
    }
    
    function confirmOwner() 
    public
    {
        require(msg.sender==newOwner);
        owner=newOwner;

    }
    
    modifier onlyOwner
    {
        if(owner == msg.sender)_;
    }
}

contract Token is Ownable
{
    function WithdrawToken(address token, uint256 amount,address to)
    public 
    onlyOwner
    {
        (bool success, ) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount)); require(success);
    }
}

contract TokenBank is Token
{
    uint public MinDeposit;
    mapping (address => uint) public Holders;
    
    // 1. Properly secure the initialization
    constructor() {
        owner = msg.sender;
        MinDeposit = 1 ether;
    }
    
    receive() external payable {
        Deposit();
    }
   
    function Deposit() 
    payable
    public {
        require(msg.value>MinDeposit);
        Holders[msg.sender]+=msg.value;
    }
    
    function WitdrawTokenToHolder(address _to,address _token,uint _amount)
    public
    onlyOwner
    {
        require(Holders[_to]>0);

        Holders[_to]=0;
        WithdrawToken(_token,_amount,_to);     

    }
   
    function WithdrawToHolder(address _addr, uint _wei) 
    public
    onlyOwner
    payable
    {
        require(Holders[_addr]>0);
        Holders[_addr]-=_wei;
        (bool success, ) = _addr.call{value: _wei}(""); if(!success)
        {
            Holders[_addr]+=_wei;
        }
    }
}
