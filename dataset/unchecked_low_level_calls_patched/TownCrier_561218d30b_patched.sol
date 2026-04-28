/*
 * @source: etherscan.io 
 * @author: -
 * =======================
 */

pragma solidity ^0.8.0;

contract TownCrier {
    struct Request {
        address requester;
        uint fee;
        address callbackAddr;
        bytes4 callbackFID;
        bytes32 paramsHash;
    }
   
    event Upgrade(address newAddr);
    event Reset(uint gas_price, uint min_fee, uint cancellation_fee); 
    event RequestInfo(uint64 id, uint8 requestType, address requester, uint fee, address callbackAddr, bytes32 paramsHash, uint timestamp, bytes32[] requestData);
    event DeliverInfo(uint64 requestId, uint fee, uint gasPrice, uint gasLeft, uint callbackGas, bytes32 paramsHash, uint64 error, bytes32 respData);
    event Cancel(uint64 requestId, address canceller, address requester, uint fee, int flag);

    address public constant SGX_ADDRESS = 0x18513702cCd928F2A3eb63d900aDf03c9cc81593;

    uint public GAS_PRICE = 5 * 10**10;
    uint public MIN_FEE = 30000 * GAS_PRICE;
    uint public CANCELLATION_FEE = 25000 * GAS_PRICE;

    uint public constant CANCELLED_FEE_FLAG = 1;
    uint public constant DELIVERED_FEE_FLAG = 0;
    int public constant FAIL_FLAG = -2 ** 250;
    int public constant SUCCESS_FLAG = 1;
    
    bool public killswitch;
    bool public externalCallFlag;

    uint64 public requestCnt;
    uint64 public unrespondedCnt;
    Request[2**64] public requests;

    int public newVersion = 0;

    receive() external payable {}

    constructor() payable {
        requestCnt = 1;
        requests[0].requester = msg.sender;
        killswitch = false;
        unrespondedCnt = 0;
        externalCallFlag = false;
    }

    function upgrade(address newAddr) public {
        if (msg.sender == requests[0].requester && unrespondedCnt == 0) {
            newVersion = -int256(uint256(uint160(newAddr)));
            killswitch = true;
            emit Upgrade(newAddr);
        }
    }

    function reset(uint price, uint minGas, uint cancellationGas) public {
        if (msg.sender == requests[0].requester && unrespondedCnt == 0) {
            GAS_PRICE = price;
            MIN_FEE = price * minGas;
            CANCELLATION_FEE = price * cancellationGas;
            emit Reset(GAS_PRICE, MIN_FEE, CANCELLATION_FEE);
        }
    }

    function suspend() public {
        if (msg.sender == requests[0].requester) {
            killswitch = true;
        }
    }

    function restart() public {
        if (msg.sender == requests[0].requester && newVersion == 0) {
            killswitch = false;
        }
    }

    function withdraw() public {
        if (msg.sender == requests[0].requester && unrespondedCnt == 0) {
            (bool success, ) = requests[0].requester.call{value: address(this).balance}("");
            require(success, "Failed to withdraw Ether");
        }
    }

    function request(uint8 requestType, address callbackAddr, bytes4 callbackFID, uint timestamp, bytes32[] memory requestData) public payable returns (int) {
        if (externalCallFlag) {
            revert("External call in progress");
        }

        if (killswitch) {
            externalCallFlag = true;
            (bool success, ) = msg.sender.call{value: msg.value}(""); 
            require(success, "Refund failed during killswitch");
            externalCallFlag = false;
            return newVersion;
        }

        if (msg.value < MIN_FEE) {
            externalCallFlag = true;
            (bool success, ) = msg.sender.call{value: msg.value}(""); 
            require(success, "Refund failed due to insufficient fee");
            externalCallFlag = false;
            return FAIL_FLAG;
        } else {
            uint64 requestId = requestCnt;
            requestCnt++;
            unrespondedCnt++;

            bytes32 paramsHash = keccak256(abi.encodePacked(requestType, requestData));
            requests[requestId].requester = msg.sender;
            requests[requestId].fee = msg.value;
            requests[requestId].callbackAddr = callbackAddr;
            requests[requestId].callbackFID = callbackFID;
            requests[requestId].paramsHash = paramsHash;

            emit RequestInfo(requestId, requestType, msg.sender, msg.value, callbackAddr, paramsHash, timestamp, requestData);
            return int256(uint256(requestId));
        }
    }

    function deliver(uint64 requestId, bytes32 paramsHash, uint64 error, bytes32 respData) public {
        if (msg.sender != SGX_ADDRESS ||
                requestId <= 0 ||
                requests[requestId].requester == address(0) ||
                requests[requestId].fee == DELIVERED_FEE_FLAG) {
            return;
        }

        uint fee = requests[requestId].fee;
        
        if (requests[requestId].paramsHash != paramsHash) {
            return;
        } else if (fee == CANCELLED_FEE_FLAG) {
            // Checked: SGX is a trusted entity, so transferring to it is safe to require.
            (bool sgxSuccess, ) = SGX_ADDRESS.call{value: CANCELLATION_FEE}("");
            require(sgxSuccess, "Failed to send cancellation fee to SGX");
            requests[requestId].fee = DELIVERED_FEE_FLAG;
            unrespondedCnt--;
            return;
        }

        requests[requestId].fee = DELIVERED_FEE_FLAG;
        unrespondedCnt--;
        
        if (error < 2) {
            // Checked: SGX is a trusted entity.
            (bool sgxSuccess, ) = SGX_ADDRESS.call{value: fee}("");
            require(sgxSuccess, "Failed to send fee to SGX");
        } else {
            externalCallFlag = true;
            // UNCHECKED INTENTIONALLY: If the untrusted requester contract reverts the refund, 
            // they forfeit the ether. Reverting here would DoS the oracle.
            requests[requestId].requester.call{gas: 2300, value: fee}("");
            externalCallFlag = false;
        }

        uint callbackGas = (fee - MIN_FEE) / tx.gasprice;
        emit DeliverInfo(requestId, fee, tx.gasprice, gasleft(), callbackGas, paramsHash, error, respData);
        
        if (callbackGas > gasleft() - 5000) {
            callbackGas = gasleft() - 5000;
        }
        
        externalCallFlag = true;
        // UNCHECKED INTENTIONALLY: The requester's callback may intentionally revert. 
        // Reverting the entire transaction here would strip the Oracle of gas fees for work completed.
        requests[requestId].callbackAddr.call{gas: callbackGas}(abi.encodeWithSelector(requests[requestId].callbackFID, requestId, error, respData)); 
        externalCallFlag = false;
    }

    function cancel(uint64 requestId) public returns (int) {
        if (externalCallFlag) {
            revert("External call in progress");
        }

        if (killswitch) {
            return 0;
        }

        uint fee = requests[requestId].fee;
        if (requests[requestId].requester == msg.sender && fee >= CANCELLATION_FEE) {
            requests[requestId].fee = CANCELLED_FEE_FLAG;
            externalCallFlag = true;
            (bool success, ) = msg.sender.call{value: fee - CANCELLATION_FEE}("");
            require(success, "Cancellation refund failed");
            externalCallFlag = false;
            
            emit Cancel(requestId, msg.sender, requests[requestId].requester, requests[requestId].fee, 1);
            return SUCCESS_FLAG;
        } else {
            emit Cancel(requestId, msg.sender, requests[requestId].requester, fee, -1);
            return FAIL_FLAG;
        }
    }
}