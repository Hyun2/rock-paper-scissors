![](https://blog.kakaocdn.net/dn/ewMek2/btrnN1bDi2g/ydcRiFzkUgoKT3kkjUwRjK/img.gif)

Ropsten 테스트넷 스마트 컨트랙트 주소: 0x0a9F1e470A03ed1Da19332b4Cf45ab03BDED6718

두 명의 사람이 가위 바위 보를 하고 이긴 사람에게 베팅한 금액만큼이 전송되도록 하는 코드를 구현하였다. 한 사람이 먼저 가위 바위 보 중 하나를 선택하고 나중에 다른 사람이 가위 바위 보 중 하나를 선택하는 방식으로 진행된다. 문제는 블록체인 상의 모든 행위는 기록으로 남는데 있다. 아래와 같이 먼저 선택한 사람이 가위 바위 보 중 무엇을 냈는지 알 수 있다는 의미이다.

![](https://imgur.com/6pYzrC9.jpg)

Data에 2라는 숫자가 보이는데, 이는 코드 상에서 가위를 냈다는 의미이다.

이 문제를 해결하기 위해서 두 사람이 처음 가위 바위 보를 중 하나를 선택할 때 패스워드를 함께 입력받아서 암호화하는 방식으로 진행하였다.

1\. 참가자 A가 가위 바위 보 중 하나를 선택하고, 패스워드를 함께 스마트컨트랙트에 전송

2\. 참가자 A가 가위 바위 보 중 선택한 것과 패스워드를 암호화한 값을 저장한다.

3\. 참가자 B가 가위 바위 보 중 하나를 선택하고, 패스워드를 함께 스마트컨트랙트에 전송

4\. 마찬가지로 참가자 B가 가위 바위 보중 선택한 것과 패스워드를 암호화한 값을 저장한다.

이렇게 진행하면 참가자 B가 가위 바위 보를 내는 시점에 참가자 A가 무엇을 냈는 지 노출되는 것을 방지할 수 있다.

공정한 승부를 내기 위해 위 방식으로 진행하면 번거로운 점이 있다. 스마트 컨트랙트 상에서 가위 바위 보 게임 결과를 판단하기 위해서 참가자들이 가위 바위 보 중 무엇을 선택했는 지와 패스워드를 다시 한 번 입력으로 받아야 한다.

아래 코드는 2단계에서 암호화 해놓은 값과 다시 손 모양과 패스워드를 입력받아 값을 비교하고 값이 동일하면 그 때 손 모양을 확정하는 코드이다.

```js
function revealOriginator(
        uint256 roomNum,
        Hand _hand,
        string memory password
    ) public {
        if (
            sha256(abi.encodePacked(_hand, password)) ==
            rooms[roomNum].originator.encHand
        ) {
            rooms[roomNum].originator.hand = _hand;
        }

        if (
            rooms[roomNum].originator.hand != Hand.none &&
            rooms[roomNum].taker.hand != Hand.none
        ) {
            compareHands(roomNum);
        }
    }
```

가위 바위 보 게임 테스트를 위해 truffle console 에서 진행한 명령어는 아래와 같다.

```js
let instance = await RPS.deployed()
let accounts = await web3.eth.getAccounts()
let p1 = accounts[0]
let p2 = accounts[1]

# 참가자 1이 가위 바위 보 중 하나를 선택하고 패스워드를 입력해서 전송하면 게임을 위한 방이 생성되고 방 번호가 출력된다.
let res = await instance.createRoom(0, '1234', {from: p1, value: web3.utils.toWei("1", "ether")})

# 참가자 2는 방 번호, 가위 바위 보 중 하나 선택한 값, 패스워드를 입력해서 전송한다.
res = await instance.joinRoom(0, 1, '5678', {from: p2, value: web3.utils.toWei("1", "ether")})

# 승부를 확인하기 위해 참가자 1과 참가자 2는 다시 한 번 가위 바위 보 중 선택한 값과 패스워드를 입력으로 보낸다. 

# 참가자 1 가위 바위 보와 패스워드 다시 입력
res = await instance.revealOriginator(0, 0, '1234')

# 참가자 2 가위 바위 보와 패스워드 다시 입력
res = await instance.revealTaker(0, 1, '5678')
```

## 회고

모든 행위가 공개된다는 블록체인의 특징이 가위 바위 보나 퀴즈 문제를 맞추는 등의 활동을 구현하는데에서는 어려움으로 작용할 수 있다는 것을 느꼈다.

아직 스마트 컨트랙트를 효율적으로 개발하는 방법을 모르겠다. 뭔가 안될 때는 일단 다 이벤트로 찍어본다. 그것 때문에 시간도 오래걸리고(코드 수정하고 다시 마이그레이트 해야하니까) 코드도 길어진다. 빨리 스마트 컨트랙트 개발에 익숙해지고 싶다.

추후에는 이 가위 바위 보 게임 스마트 컨트랙트를 이용한 프론트 화면을 만들어 보고 그 과정에서 발생하는 문제점을 개선해봐야 겠다.
