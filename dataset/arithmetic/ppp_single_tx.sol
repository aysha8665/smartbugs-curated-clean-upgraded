/*
 * =======================
 * =======================
 * =======================
 */

//=======================
//=======================

pragma solidity ^0.8.0;

contract pppSingleTransaction {
    uint public count = 1;

    
    function waddtostate(uint256 input) public {
        
        unchecked { count += input; }
    }

    
    function wmultostate(uint256 input) public {
        
        unchecked { count *= input; }
    }

    
    function wtostate(uint256 input) public {
        
        unchecked { count -= input; }
    }

    
    function owlocalonly(uint256 input) public {
        uint res;
        unchecked { res = count + input; }
    }

    
    function wmulocalonly(uint256 input) public {
        uint res;
        unchecked { res = count * input; }
    }

    
    function uwlocalonly(uint256 input) public {
        uint res;
       	unchecked { res = count - input; }
    }

}
