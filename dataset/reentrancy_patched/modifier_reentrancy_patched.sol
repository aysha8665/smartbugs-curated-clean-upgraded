
pragma solidity ^0.8.0;

contract ModifierEntrancy {
  mapping (address => uint) public tokenBalance;
  string constant name = "Nu Token";
  
  // 1. State variable for the mutex lock
  bool private _locked;

  // 2. The Reentrancy Guard logic isolated into its own modifier
  modifier nonReentrant() {
      require(!_locked, "ReentrancyGuard: reentrant call");
      _locked = true;
      _;
      _locked = false;
  }

  // 3. nonReentrant MUST be the first modifier in the signature
  function airDrop() nonReentrant hasNoBalance supportsToken public {
    tokenBalance[msg.sender] += 20;
  }

  // Checks that the contract responds the way we want
  // (This contains the dangerous external call)
  modifier supportsToken() {
    require(keccak256(abi.encodePacked("Nu Token")) == Bank(msg.sender).supportsToken(), "Unsupported token");
    _;
  }
  
  // Checks that the caller has a zero balance
  modifier hasNoBalance {
      require(tokenBalance[msg.sender] == 0, "Caller has a non-zero balance");
      _;
  }
}

contract Bank {
    function supportsToken() external pure returns(bytes32) {
        return(keccak256(abi.encodePacked("Nu Token")));
    }
}

contract attack { // An example of a contract that breaks the unpatched contract above.
    bool hasBeenCalled;
    
    function supportsToken() external returns(bytes32) {
        if(!hasBeenCalled) {
            hasBeenCalled = true;
            // This reentrant call will now fail because _locked is true
            ModifierEntrancy(msg.sender).airDrop();
        }
        return(keccak256(abi.encodePacked("Nu Token")));
    }
    
    function call(address token) public {
        ModifierEntrancy(token).airDrop();
    }
}