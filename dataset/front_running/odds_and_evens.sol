/*
 * =======================
 * =======================
 *=======================
 */

pragma solidity ^0.8.0;

contract OddsAndEvens{

  struct Player {
    address addr;
    uint number;
  }

  Player[2] public players;       

  uint8 tot;
  address owner;

  constructor() payable {
    owner = msg.sender;
  }

  function play(uint number) payable{
    if (msg.value != 1 ether) revert();
 
    players[tot] = Player(msg.sender, number);
    tot++;

    if (tot==2) andTheWinnerIs();
  }

  function andTheWinnerIs() private {
    bool res ;
    uint n = players[0].number+players[1].number;
    if (n%2==0) {
      res = players[0].payable(addr).send(1800 finney);
    }
    else {
      res = players[1].payable(addr).send(1800 finney);
    }

    delete players;
    tot=0;
  }

  function getProfit() public {
    if(msg.sender!=owner) revert();
    bool res = payable(msg.sender).send(address(this).balance);
  }

}
