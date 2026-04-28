/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;


contract airPort{
    
    function transfer(address from,address caddress,address[] memory _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            (bool success, ) = caddress.call(abi.encodeWithSelector(id, msg.sender, _tos[i], v));
            require(success, "Failed to call transferFrom function");
        }
        return true;
    }
}
