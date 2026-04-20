/*
 * @source: https://consensys.github.io/smart-contract-best-practices/known_attacks/
 * @author: consensys
 * =======================
 */

pragma solidity ^0.8.0;

contract Reentrancy_bonus{

    bool private _locked;
    mapping (address => uint) private userBalances;
    mapping (address => bool) private claimedBonus;
    mapping (address => uint) private rewardsForA;

    function withdrawReward(address recipient) public {
        uint amountToWithdraw = rewardsForA[recipient];
        rewardsForA[recipient] = 0;
        (bool success, ) = recipient.call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
    }

    function getFirstWithdrawalBonus(address recipient) public {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        require(!claimedBonus[recipient], "Bonus already claimed");

        rewardsForA[recipient] += 100;
        claimedBonus[recipient] = true;
        withdrawReward(recipient);
        _locked = false;
    }
}
