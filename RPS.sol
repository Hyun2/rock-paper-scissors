//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor() payable {}

    enum Hand {
        rock,
        paper,
        scissors
    }

    enum PlayerStatus {
        WIN,
        LOSE,
        TIE,
        PENDING
    }

    enum GameStatus {
        NOT_STARTED,
        STARTED,
        COMPLETE,
        ERROR
    }

    struct Player {
        address payable addr;
        uint256 betAmount;
        Hand hand;
        PlayerStatus status;
    }

    struct Game {
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus status;
    }

    mapping(uint256 => Game) rooms;
    uint256 roomLen = 0;

    modifier isValidHand(Hand _hand) {
        require(
            (_hand == Hand.rock) ||
                (_hand == Hand.paper) ||
                (_hand == Hand.scissors)
        );
        _;
    }

    function createRoom(Hand _hand)
        public
        payable
        isValidHand(_hand)
        returns (uint256 roomNum)
    {
        rooms[roomLen] = Game({
            originator: Player({
                addr: payable(msg.sender),
                betAmount: msg.value,
                hand: _hand,
                status: PlayerStatus.PENDING
            }),
            taker: Player({
                addr: payable(msg.sender),
                betAmount: 0,
                hand: Hand.rock,
                status: PlayerStatus.PENDING
            }),
            betAmount: msg.value,
            status: GameStatus.NOT_STARTED
        });
        roomNum = roomLen;
        roomLen = roomLen + 1;
    }

    function joinRoom(uint256 roomNum, Hand _hand)
        public
        payable
        isValidHand(_hand)
    {
        rooms[roomNum].taker = Player({
            addr: payable(msg.sender),
            betAmount: msg.value,
            hand: _hand,
            status: PlayerStatus.PENDING
        });

        rooms[roomNum].betAmount =
            rooms[roomNum].originator.betAmount +
            msg.value;

        compareHands(roomNum);
    }

    function compareHands(uint256 roomNum) private {
        uint8 originatorHand = uint8(rooms[roomNum].originator.hand);
        uint8 takerHand = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].status = GameStatus.STARTED;

        if (originatorHand == takerHand) {
            rooms[roomNum].originator.status = PlayerStatus.TIE;
            rooms[roomNum].taker.status = PlayerStatus.TIE;
        } else if ((takerHand + 1) % 3 == originatorHand) {
            // 방장 승리
            rooms[roomNum].originator.status = PlayerStatus.WIN;
            rooms[roomNum].taker.status = PlayerStatus.LOSE;
        } else if ((originatorHand + 1) % 3 == takerHand) {
            // 참가자 승리
            rooms[roomNum].originator.status = PlayerStatus.LOSE;
            rooms[roomNum].taker.status = PlayerStatus.WIN;
        } else {
            rooms[roomNum].status = GameStatus.ERROR;
        }
    }

    modifier isPlayer(uint256 roomNum, address sender) {
        require(
            sender == rooms[roomNum].originator.addr ||
                sender == rooms[roomNum].taker.addr
        );
        _;
    }

    function payout(uint256 roomNum)
        public
        payable
        isPlayer(roomNum, msg.sender)
    {
        if (
            rooms[roomNum].originator.status == PlayerStatus.TIE &&
            rooms[roomNum].taker.status == PlayerStatus.TIE
        ) {
            rooms[roomNum].originator.addr.transfer(
                rooms[roomNum].originator.betAmount
            );
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.betAmount);
        } else {
            if (
                rooms[roomNum].originator.status == PlayerStatus.WIN
            ) {} else if (
                rooms[roomNum].taker.status == PlayerStatus.WIN
            ) {} else {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].originator.betAmount
                );
                rooms[roomNum].taker.addr.transfer(
                    rooms[roomNum].taker.betAmount
                );
            }
        }
        rooms[roomNum].status = GameStatus.COMPLETE;
    }
}
