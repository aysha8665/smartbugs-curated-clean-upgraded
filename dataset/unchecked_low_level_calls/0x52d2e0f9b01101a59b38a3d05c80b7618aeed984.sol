/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;
contract Token {
    function transfer(address _to, uint _value) returns (bool success);
    function balanceOf(address _owner) view returns (uint balance);
}
contract EtherGet {
    address owner;
    constructor()  {
        owner = msg.sender;
    }
    function withdrawTokens(address tokenContract) public {
        Token tc = Token(tokenContract);
        payable(tc).transfer(owner, tc.balanceOf(this));
    }
    function withdrawEther() public {
        payable(owner).transfer(address(this).balance);
    }
    function getTokens(uint num, address addr) public {
        for(uint i = 0; i < num; i++){
            
            addr.call{value: 0 wei}("");
        }
    }
}