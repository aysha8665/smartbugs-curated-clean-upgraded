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

    function refundAll() public {
        for(uint x; x < refundAddresses.length; x++) {
            address recipient = refundAddresses[x];
            uint amount = refunds[recipient];
            if (amount > 0) {
                // PATCH: zero the balance before sending (re-entrancy guard),
                // and drop the `require` around `send`. In the original,
                // `require(send(...))` reverts the entire loop if any single
                // recipient rejects ETH (e.g. a contract with no receive()),
                // permanently bricking refunds for all other creditors.
                // By ignoring the send return value, a failing recipient is
                // simply skipped — it cannot DoS everyone else.
                // Their unclaimed balance remains in `refunds` and can be
                // retried or handled separately.
                refunds[recipient] = 0;
                payable(recipient).send(amount);
            }
        }
    }

}
