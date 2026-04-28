/*
 * =======================
 * =======================
 * =======================
 * =======================
 */

 pragma solidity ^0.8.0;

contract Ethraffle_v4b {
    struct Contestant {
        address addr;
        uint raffleId;
    }

    event RaffleResult(
        uint raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
    );

    event TicketPurchase(
        uint raffleId,
        address contestant,
        uint number
    );

    event TicketRefund(
        uint raffleId,
        address contestant,
        uint number
    );

    // Constants
    uint public constant prize = 2.5 ether;
    uint public constant fee = 0.03 ether;
    uint public constant totalTickets = 50;
    uint public constant pricePerTicket = (prize + fee) / totalTickets; // Make sure this divides evenly
    address feeAddress;

    // Other internal variables
    bool public paused = false;
    uint public raffleId = 1;
    
    uint public blockNumber = block.number;
    uint nextTicket = 0;
    mapping (uint => Contestant) contestants;
    uint[] gaps;

    // Initialization
    constructor() payable {
        feeAddress = msg.sender;
    }

    // Call buyTickets() when receiving Ether outside a function
    receive() external payable {
        buyTickets();
    }

    function buyTickets() payable public {
        if (paused) {
            payable(msg.sender).transfer(msg.value);
            return;
        }

        uint value = msg.value;
        if (value == 0) {
            return;
        }

        value = (value / pricePerTicket) * pricePerTicket;

        if (value < msg.value) {
             // PATCH: Use transfer() instead of send() to ensure transaction reverts 
             // if the refund fails, preventing the contract from trapping the user's change.
             payable(msg.sender).transfer(msg.value-value);
        }

        uint tickets = value / pricePerTicket;
        for (uint i = 0; i < tickets; i++) {
            if (nextTicket >= totalTickets) {
                // Refund the rest of the money
                uint refund = (tickets - i) * pricePerTicket;
                payable(msg.sender).transfer(refund);
                return;
            }

            // If there are gaps in the raffle, fill them first
            if (gaps.length > 0) {
                uint gap = gaps[gaps.length - 1];
                gaps.pop();
                contestants[gap] = Contestant(msg.sender, raffleId);
                emit TicketPurchase(raffleId, msg.sender, gap);
            } else {
                contestants[nextTicket] = Contestant(msg.sender, raffleId);
                emit TicketPurchase(raffleId, msg.sender, nextTicket);
                nextTicket++;
            }
        }
    }

    // Choose the winner
    function chooseWinner() public {
        if (nextTicket >= totalTickets) {
            uint winningNumber = getWinningNumber(blockNumber, contestants[0].addr, contestants[nextTicket - 1].addr, uint160(contestants[nextTicket / 2].addr));
            address winningAddress = contestants[winningNumber].addr;

            emit RaffleResult(raffleId, winningNumber, winningAddress, contestants[0].addr, contestants[nextTicket - 1].addr, uint160(contestants[nextTicket / 2].addr), keccak256(abi.encodePacked(blockNumber, contestants[0].addr, contestants[nextTicket - 1].addr, contestants[nextTicket / 2].addr)));

            payable(winningAddress).transfer(prize);
            payable(feeAddress).transfer(fee);

            raffleId++;
            nextTicket = 0;
            
            blockNumber = block.number;
            delete gaps;
        }
    }

    // Gets the winning number based on the block number and the seeds
    function getWinningNumber(uint _blockNumber, address _seed1, address _seed2, uint _seed3) pure internal returns (uint) {
        bytes32 randHash = keccak256(abi.encodePacked(_blockNumber, _seed1, _seed2, _seed3));
        return uint(randHash) % totalTickets;
    }

    // A refund can be requested if the raffle has not been completed after 1 week occurs
    function getRefund() public {
        uint refund = 0;
        for (uint i = 0; i < totalTickets; i++) {
            if (msg.sender == contestants[i].addr && raffleId == contestants[i].raffleId) {
                refund += pricePerTicket;
                contestants[i] = Contestant(address(0), 0);
                gaps.push(i);
                emit TicketRefund(raffleId, msg.sender, i);
            }
        }

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    // Refund everyone's money, start a new raffle, then pause it
    function endRaffle() public {
        if (msg.sender == feeAddress) {
            paused = true;

            for (uint i = 0; i < totalTickets; i++) {
                if (raffleId == contestants[i].raffleId) {
                    emit TicketRefund(raffleId, contestants[i].addr, i);
                    payable(contestants[i].addr).transfer(pricePerTicket);
                }
            }

            emit RaffleResult(raffleId, totalTickets, address(0), address(0), address(0), 0, 0);
            raffleId++;
            nextTicket = 0;
            
            blockNumber = block.number;
            delete gaps;
        }
    }

    function togglePause() public {
        if (msg.sender == feeAddress) {
            paused = !paused;
        }
    }

    function kill() public {
        if (msg.sender == feeAddress) {
            selfdestruct(payable(feeAddress));
        }
    }
}