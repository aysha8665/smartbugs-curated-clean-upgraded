pragma solidity ^0.8.0;

contract DosAuction {
    address currentFrontrunner;
    uint currentBid;

    // --- patch: pending refunds ---
    mapping(address => uint) public pendingReturns;

    //=======================
    function bid() payable public {
        require(msg.value > currentBid);

        if (currentFrontrunner != address(0)) {
            // PATCHED: credit refund instead of pushing ETH inline.
            // This removes the external call from the hot path entirely,
            // eliminating the DoS vector.
            pendingReturns[currentFrontrunner] += currentBid;
        }

        currentFrontrunner = msg.sender;
        currentBid         = msg.value;
    }

    // New function: outbid users pull their refund themselves.
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "nothing to withdraw");

        // Zero before transfer — re-entrancy guard
        pendingReturns[msg.sender] = 0;
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");
    }
}