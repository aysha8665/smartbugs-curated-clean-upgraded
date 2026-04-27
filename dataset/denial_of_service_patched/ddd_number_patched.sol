/*
 *=======================
 * =======================
 * =======================
 */

pragma solidity ^0.8.0;

contract DNumber {

    uint numElements = 0;
    uint[] array;

    function insertNnumbers(uint value,uint numbers) public {
        for(uint i=0;i<numbers;i++) {
            if(numElements == array.length) {
                array.push();
            }
            array[numElements++] = value;
        }
    }

    function clear() public {
        require(numElements>1500);
        numElements = 0;
    }

    // Gas DOS clear — PATCHED
    function clearDOS() public {
        require(numElements>1500);
        // PATCH: `delete array` zeroes the length slot in a single SSTORE (O(1))
        // instead of `new uint[](0)` which iterates every storage slot (O(n))
        // and exceeds the block gas limit when numElements > ~1500.
        delete array;
        numElements = 0;
    }

    function getLengthArray() public view returns(uint) {
        return numElements;
    }

    function getRealLengthArray() public view returns(uint) {
        return array.length;
    }
}
