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

    // Pull-over-push pattern: let users withdraw individually
    function withdraw() public {
        uint amount = refunds[msg.sender];
        require(amount > 0, "No refund available");
        refunds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
    }

}
