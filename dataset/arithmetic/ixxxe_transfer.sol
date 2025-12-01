/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract xxAdd {
    mapping (address => uint256) public balanceOf;

    // INSECURE
    function transfer(address _to, uint256 _value) public{
        /* Check if sender has balance */
        require(balanceOf[msg.sender] >= _value);
        unchecked { balanceOf[msg.sender] -= _value; }
        
        unchecked { balanceOf[_to] += _value; }
}

}
