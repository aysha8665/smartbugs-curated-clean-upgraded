/*
 * =======================
 * =======================
 */
pragma solidity ^0.8.0;

// CryptoRoulette
//
// =======================
// =======================
// =======================
// To play, call the play() method with the guessed number (1-20).  Bet price: 0.1 ether

contract CryptoRoulette {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    uint256 public betPrice = 0.1 ether;
    address public ownerAddr;

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gamesPlayed;

    constructor() {
        ownerAddr = msg.sender;
        shuffle();
    }

    function shuffle() internal {
        // randomly set secretNumber with a value between 1 and 20
        secretNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number-1))))) % 20 + 1;
    }

    function play(uint256 number) payable public {
        require(msg.value >= betPrice && number <= 10);
        
        // Note: Original vulnerability was uninitialized storage pointer
        // In Solidity 0.8.x, must use memory - weak randomness vulnerability still present
        Game memory game; 
        game.player = msg.sender;
        game.number = number;
        gamesPlayed.push(game);

        if (number == secretNumber) {
            // win!
            payable(msg.sender).transfer(address(this).balance);
        }

        shuffle();
        lastPlayed = block.timestamp;
    }

    function kill() public {
        if (msg.sender == ownerAddr && block.timestamp > lastPlayed + 1 days) {
            selfdestruct(payable(msg.sender));
        }
    }

    receive() external payable { }
}
