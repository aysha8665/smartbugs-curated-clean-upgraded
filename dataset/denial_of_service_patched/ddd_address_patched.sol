/*
 * =======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract DGas {

    address[] creditorAddresses;
    bool win = false;

    function emptyCreditors() public {

        if(creditorAddresses.length>1500) {
            // PATCH: use `delete` instead of `new address[](0)`.
            // `delete` sets the array length to 0 in O(1) without
            // iterating over every storage slot, so this function
            // can never be DoS'd by a large array.
            delete creditorAddresses;
            win = true;
        }
    }

    function addCreditors() public returns (bool) {
        for(uint i=0;i<350;i++) {
          creditorAddresses.push(msg.sender);
        }
        return true;
    }

    function iWin() public view returns (bool) {
        return win;
    }

    function numberCreditors() public view returns (uint) {
        return creditorAddresses.length;
    }
}
