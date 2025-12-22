/*
 * =======================
 * =======================
* =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract Refunder {
    
address[] private refundAddresses;
mapping (address => uint) public refunds;

    constructor() {
        refundAddresses.push(0x79B483371E87d664cd39491b5F06250165e4b184);
        refundAddresses.push(0x79B483371E87d664cd39491b5f06250165e4b185);
    }

    // bad
    function refundAll() public {
        for(uint x; x < refundAddresses.length; x++) { 
        
            require(payable(refundAddresses[x]).send(refunds[refundAddresses[x]])); 
        }
    }

}
