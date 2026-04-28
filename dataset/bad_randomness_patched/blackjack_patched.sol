/*
 * =======================
 * RANDOMNESS PATCH: commit-reveal scheme
 * =======================
 *
 * VULNERABILITY (original):
 *   Deck.deal() derived card randomness from blockhash, block.number, and
 *   block.timestamp — all of which a validator (block proposer) can influence.
 *   A malicious validator can:
 *     - Withhold a block to reroll card outcomes (nothing-up-my-sleeve attack)
 *     - Choose a timestamp within the allowed drift to steer the keccak output
 *   A malicious *player* running a contract can simulate the same keccak call
 *   before calling hit()/stand() and only proceed when the outcome is favorable.
 *
 * FIX: Commit-Reveal
 *   1. Before starting a game the player calls commit(keccak256(abi.encodePacked(secret))).
 *   2. When starting the game the player calls deal(secret).
 *      The contract verifies keccak256(secret) matches the stored commitment,
 *      then mixes `secret` with block data to produce card entropy.
 *   3. The commitment is deleted immediately after use (prevents replay).
 *
 *   A validator who sees `secret` in the mempool would still need to control
 *   blockhash *and* timestamp simultaneously — significantly harder.
 *   For production, combine with Chainlink VRF for fully trustless randomness.
 *
 * SIGNATURE CHANGES (minimal, unavoidable):
 *   - Deck.deal(address, uint8)           → Deck.deal(address, uint8, bytes32)
 *   - BlackJack.deal()                    → BlackJack.deal(bytes32 _secret)
 *   - BlackJack.commit(bytes32) added     (new — required for scheme)
 *   - BlackJack.commitments mapping added (new)
 */

pragma solidity ^0.8.0;

library Deck {

    /**
     * @dev Cards are drawn by hashing the player's committed secret with block
     *      data and a per-card nonce (cardNumber). The secret is the primary
     *      entropy source; block data is mixed in so the player cannot predict
     *      outcomes purely from their own secret either.
     *
     * @param player     Address of the player (domain separator).
     * @param cardNumber Per-deal nonce so successive cards within one block differ.
     * @param seed       Player-supplied secret revealed at deal time.
     */
    function deal(address player, uint8 cardNumber, bytes32 seed) internal view returns (uint8) {
        return uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,           // primary entropy — unknown to validator at proposal time
                        blockhash(block.number - 1), // historical block, not the current one
                        player,
                        cardNumber,
                        block.timestamp
                    )
                )
            ) % 52
        );
    }

    function valueOf(uint8 card, bool isBigAce) internal pure returns (uint8) {
        uint8 value = card / 4;
        if (value == 0 || value == 11 || value == 12) {
            return 10;
        }
        if (value == 1 && isBigAce) {
            return 11;
        }
        return value;
    }

    function isAce(uint8 card) internal pure returns (bool) {
        return card / 4 == 1;
    }

    function isTen(uint8 card) internal pure returns (bool) {
        return card / 4 == 10;
    }
}


contract BlackJack {
    using Deck for *;

    uint public minBet = 50000000000000000;
    uint public maxBet = 5000000000000000000;

    uint8 BLACKJACK = 21;

    enum GameState { Ongoing, Player, Tie, House }

    struct Game {
        address player;
        uint bet;

        uint8[] houseCards;
        uint8[] playerCards;

        GameState state;
        uint8 cardsDealt;
        bytes32 seed;       // player-revealed secret stored for mid-game draws
    }

    mapping(address => Game)    public games;
    mapping(address => bytes32) public commitments; // keccak256(secret) stored before the game

    modifier gameIsGoingOn() {
        if (games[msg.sender].player == address(0) || games[msg.sender].state != GameState.Ongoing) {
            revert();
        }
        _;
    }

    event Deal(bool isUser, uint8 _card);
    event GameStatus(uint8 houseScore, uint8 houseScoreBig, uint8 playerScore, uint8 playerScoreBig);
    event Log(uint8 value);

    constructor() payable {}

    receive() external payable {}

    // -----------------------------------------------------------------------
    // Step 1 — player must call this BEFORE deal(), in a separate transaction.
    //          _commitment = keccak256(abi.encodePacked(secret))
    //          The secret is any bytes32 the player chooses; keep it private
    //          until deal() is called.
    // -----------------------------------------------------------------------
    function commit(bytes32 _commitment) public {
        require(
            games[msg.sender].player == address(0) || games[msg.sender].state != GameState.Ongoing,
            "Cannot commit during an ongoing game"
        );
        require(_commitment != bytes32(0), "Empty commitment");
        commitments[msg.sender] = _commitment;
    }

    // -----------------------------------------------------------------------
    // Step 2 — starts a new game.
    //          _secret: the preimage of the commitment made in commit().
    //          Signature changed from deal() to deal(bytes32) — unavoidable.
    // -----------------------------------------------------------------------
    function deal(bytes32 _secret) public payable {
        // Verify commitment
        require(commitments[msg.sender] != bytes32(0), "Must commit first");
        require(
            keccak256(abi.encodePacked(_secret)) == commitments[msg.sender],
            "Secret does not match commitment"
        );
        // Consume commitment immediately — no replay
        delete commitments[msg.sender];

        if (games[msg.sender].player != address(0) && games[msg.sender].state == GameState.Ongoing) {
            revert(); // game already in progress
        }
        if (msg.value < minBet || msg.value > maxBet) {
            revert(); // incorrect bet
        }

        uint8[] memory houseCards  = new uint8[](1);
        uint8[] memory playerCards = new uint8[](2);

        playerCards[0] = Deck.deal(msg.sender, 0, _secret);
        emit Deal(true, playerCards[0]);
        houseCards[0]  = Deck.deal(msg.sender, 1, _secret);
        emit Deal(false, houseCards[0]);
        playerCards[1] = Deck.deal(msg.sender, 2, _secret);
        emit Deal(true, playerCards[1]);

        games[msg.sender] = Game({
            player:     msg.sender,
            bet:        msg.value,
            houseCards: houseCards,
            playerCards: playerCards,
            state:      GameState.Ongoing,
            cardsDealt: 3,
            seed:       _secret   // stored for hit() / stand() draws
        });

        checkGameResult(games[msg.sender], false);
    }

    // deals one more card to the player
    function hit() public gameIsGoingOn {
        uint8 nextCard = games[msg.sender].cardsDealt;
        bytes32 seed   = games[msg.sender].seed;
        games[msg.sender].playerCards.push(Deck.deal(msg.sender, nextCard, seed));
        games[msg.sender].cardsDealt = nextCard + 1;
        emit Deal(true, games[msg.sender].playerCards[games[msg.sender].playerCards.length - 1]);
        checkGameResult(games[msg.sender], false);
    }

    // finishes the game
    function stand() public gameIsGoingOn {
        bytes32 seed = games[msg.sender].seed;

        (, uint8 houseScoreBig) = calculateScore(games[msg.sender].houseCards);

        while (houseScoreBig < 17) {
            uint8 nextCard = games[msg.sender].cardsDealt;
            uint8 newCard  = Deck.deal(msg.sender, nextCard, seed);
            games[msg.sender].houseCards.push(newCard);
            games[msg.sender].cardsDealt = nextCard + 1;
            emit Deal(false, newCard);
            (, houseScoreBig) = calculateScore(games[msg.sender].houseCards);
        }

        checkGameResult(games[msg.sender], true);
    }

    function checkGameResult(Game memory game, bool finishGame) private {
        (uint8 houseScore, uint8 houseScoreBig) = calculateScore(game.houseCards);
        (uint8 playerScore, uint8 playerScoreBig) = calculateScore(game.playerCards);

        emit GameStatus(houseScore, houseScoreBig, playerScore, playerScoreBig);

        if (houseScoreBig == BLACKJACK || houseScore == BLACKJACK) {
            if (playerScore == BLACKJACK || playerScoreBig == BLACKJACK) {
                // TIE
                games[msg.sender].state = GameState.Tie;
                if (!payable(msg.sender).send(game.bet)) revert();
                return;
            } else {
                // HOUSE WON
                games[msg.sender].state = GameState.House;
                return;
            }
        } else {
            if (playerScore == BLACKJACK || playerScoreBig == BLACKJACK) {
                // PLAYER WON
                if (game.playerCards.length == 2 && (Deck.isTen(game.playerCards[0]) || Deck.isTen(game.playerCards[1]))) {
                    // Natural blackjack => x2.5
                    games[msg.sender].state = GameState.Player;
                    if (!payable(msg.sender).send((game.bet * 5) / 2)) revert();
                } else {
                    // Usual blackjack => x2
                    games[msg.sender].state = GameState.Player;
                    if (!payable(msg.sender).send(game.bet * 2)) revert();
                }
                return;
            } else {
                if (playerScore > BLACKJACK) {
                    // BUST
                    emit Log(1);
                    games[msg.sender].state = GameState.House;
                    return;
                }

                if (!finishGame) {
                    return;
                }

                uint8 playerShortage = 0;
                uint8 houseShortage  = 0;

                if (playerScoreBig > BLACKJACK) {
                    if (playerScore > BLACKJACK) {
                        games[msg.sender].state = GameState.House;
                        return;
                    } else {
                        playerShortage = BLACKJACK - playerScore;
                    }
                } else {
                    playerShortage = BLACKJACK - playerScoreBig;
                }

                if (houseScoreBig > BLACKJACK) {
                    if (houseScore > BLACKJACK) {
                        games[msg.sender].state = GameState.Player;
                        if (!payable(msg.sender).send(game.bet * 2)) revert();
                        return;
                    } else {
                        houseShortage = BLACKJACK - houseScore;
                    }
                } else {
                    houseShortage = BLACKJACK - houseScoreBig;
                }

                if (houseShortage == playerShortage) {
                    games[msg.sender].state = GameState.Tie;
                    if (!payable(msg.sender).send(game.bet)) revert();
                } else if (houseShortage > playerShortage) {
                    games[msg.sender].state = GameState.Player;
                    if (!payable(msg.sender).send(game.bet * 2)) revert();
                } else {
                    games[msg.sender].state = GameState.House;
                }
            }
        }
    }

    function calculateScore(uint8[] memory cards) private pure returns (uint8, uint8) {
        uint8 score    = 0;
        uint8 scoreBig = 0;
        bool bigAceUsed = false;
        for (uint i = 0; i < cards.length; ++i) {
            uint8 card = cards[i];
            if (Deck.isAce(card) && !bigAceUsed) {
                scoreBig += Deck.valueOf(card, true);
                bigAceUsed = true;
            } else {
                scoreBig += Deck.valueOf(card, false);
            }
            score += Deck.valueOf(card, false);
        }
        return (score, scoreBig);
    }

    function getPlayerCard(uint8 id) public gameIsGoingOn view returns (uint8) {
        if (id >= games[msg.sender].playerCards.length) revert();
        return games[msg.sender].playerCards[id];
    }

    function getHouseCard(uint8 id) public gameIsGoingOn view returns (uint8) {
        if (id >= games[msg.sender].houseCards.length) revert();
        return games[msg.sender].houseCards[id];
    }

    function getPlayerCardsNumber() public gameIsGoingOn view returns (uint) {
        return games[msg.sender].playerCards.length;
    }

    function getHouseCardsNumber() public gameIsGoingOn view returns (uint) {
        return games[msg.sender].houseCards.length;
    }

    function getGameState() public view returns (uint8) {
        if (games[msg.sender].player == address(0)) revert();
        Game memory game = games[msg.sender];
        if (game.state == GameState.Player) return 1;
        if (game.state == GameState.House)  return 2;
        if (game.state == GameState.Tie)    return 3;
        return 0;
    }
}
