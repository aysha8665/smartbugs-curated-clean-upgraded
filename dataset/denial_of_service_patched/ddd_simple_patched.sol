/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract DOneFunc {

    address[] listAddresses;

    function ifillArray() public returns (bool){
        if(listAddresses.length<1500) {
            for(uint i=0;i<350;i++) {
                listAddresses.push(msg.sender);
            }
            return true;

        } else {
            // PATCH: `delete listAddresses` resets the array length in a single
            // SSTORE (O(1)) instead of `new address[](0)` which must zero every
            // storage slot (O(n)) and exceeds the block gas limit at 1500+ entries,
            // permanently bricking this branch.
            delete listAddresses;
            return false;
        }
    }
}
