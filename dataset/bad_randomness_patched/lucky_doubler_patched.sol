/*
 * =======================
 * FULLY PATCHED LUCKY DOUBLER
 * =======================
 */

pragma solidity ^0.8.0;

contract LuckyDoubler {
    address private owner;

    // Stored variables
    uint private balance = 0;
    uint private fee = 5;
    uint private multiplier = 125;

    mapping (address => User) private users;
    Entry[] private entries;
    uint[] private unpaidEntries;

    // PATCH 1: Added mapping for Pull-over-Push architecture
    // This safely catches failed payouts without reverting the whole system
    mapping(address => uint) public pendingWithdrawals;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyowner { require(msg.sender == owner, "Not owner"); _; }

    struct User {
        address id;
        uint deposits;
        uint payoutsReceived;
    }

    struct Entry {
        address entryAddress;
        uint deposit;
        uint payout;
        bool paid;
    }

    receive() external payable {
        init();
    }

    function init() private {
        // PATCH 2: Use require() instead of an unchecked send() for underpayments. 
        // This cleanly reverts the transaction, saving the user gas and preventing trapped funds.
        require(msg.value >= 1 ether, "Minimum 1 ETHER required");
        join();
    }

    function join() private {
        uint deposit = msg.value;

        // Limit deposits to 1 ETH
        if (deposit > 1 ether) {
            uint refundAmount = msg.value - 1 ether;
            deposit = 1 ether;
            
            // PATCH 3: Explicitly require the refund to succeed.
            // If the user's wallet cannot accept the refund, the deposit is safely rolled back.
            (bool refundSuccess, ) = msg.sender.call{value: refundAmount}("");
            require(refundSuccess, "Refund failed");
        }

        // Add user if new
        if (users[msg.sender].id == address(0)) {
            users[msg.sender] = User(msg.sender, 0, 0);
        }
        users[msg.sender].deposits += deposit;

        // Add entry
        uint expectedPayout = (deposit * multiplier) / 100;
        entries.push(Entry(msg.sender, deposit, expectedPayout, false));
        unpaidEntries.push(entries.length - 1);

        // Calculate and process fee
        uint feeAmount = (deposit * fee) / 100;
        
        // PATCH 4: Handle fee payout safely. 
        // If the owner contract is temporarily unable to receive ETH, 
        // the fee is credited to their withdrawal balance instead of failing silently.
        (bool feeSuccess, ) = owner.call{value: feeAmount}("");
        if (!feeSuccess) {
            pendingWithdrawals[owner] += feeAmount;
        }

        balance += (deposit - feeAmount);
        payout();
    }

    function payout() private {
        if (unpaidEntries.length == 0) return;

        // Randomness evaluation
        uint seed = unpaidEntries.length + block.timestamp + block.number;
        uint random = uint(keccak256(abi.encodePacked(seed))) % unpaidEntries.length;
        uint payoutIndex = unpaidEntries[random];

        uint payoutAmount = entries[payoutIndex].payout;
        if (balance < payoutAmount) {
            return;
        }

        address winner = entries[payoutIndex].entryAddress;

        // PATCH 5: Implement Pull-over-Push to prevent DoS via Revert.
        // We do NOT use require() here. If the winner's wallet rejects the ETH,
        // we isolate the failure by pushing the funds into their pending balance.
        // This ensures the internal `balance` decreases and the queue keeps moving.
        (bool paySuccess, ) = winner.call{value: payoutAmount}("");
        if (!paySuccess) {
            pendingWithdrawals[winner] += payoutAmount;
        }

        balance -= payoutAmount;
        entries[payoutIndex].paid = true;
        users[winner].payoutsReceived += 1;

        // Remove from unpaid array
        unpaidEntries[random] = unpaidEntries[unpaidEntries.length - 1];
        unpaidEntries.pop();
    }

    // PATCH 6: Added to complete the Pull-over-Push architecture, allowing 
    // users to manually claim funds if their automated payout failed.
    function withdrawPending() public {
        uint amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawals");
        
        // Checks-Effects-Interactions: Zero balance before transfer
        pendingWithdrawals[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // =====================================
    // Original Getter & Admin Functions
    // =====================================
    function changeMultiplier(uint newMultiplier) onlyowner public {
        if (newMultiplier > 150 || newMultiplier < 110) revert("Out of bounds");
        multiplier = newMultiplier;
    }

    function changeFee(uint newFee) onlyowner public {
        if (fee > 5) revert("Fee too high");
        fee = newFee;
    }

    function multiplierFactor() view public returns(uint factor, string memory info) {
        factor = multiplier;
        info = 'The current multiplier applied to all deposits. Min 110%, max 150%.';
    }

    function currentFee() view public returns(uint feePercentage, string memory info) {
        feePercentage = fee;
        info = 'The fee percentage applied to all deposits. It can change to speed payouts (max 5%).';
    }

    function totalEntries() view public returns(uint count, string memory info) {
        count = entries.length;
        info = 'The number of deposits.';
    }

    function userStats(address user) view public returns(uint deposits, uint payouts, string memory info) {
        if (users[user].id != address(0)) {
            deposits = users[user].deposits;
            payouts = users[user].payoutsReceived;
            info = 'Users stats: total deposits, payouts received.';
        }
    }

    function entryDetails(uint index) view public returns(address user, uint payout, bool paid, string memory info) {
        if (index < entries.length) {
            user = entries[index].entryAddress;
            payout = entries[index].payout / 1000000000000000;
            paid = entries[index].paid;
            info = 'Entry info: user address, expected payout in Finneys, payout status.';
        }
    }
}