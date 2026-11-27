// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRandomOracle {
    function requestRandomness() external returns (bytes32 requestId);
}

/// @notice Single-round casino whose winner is selected from trusted oracle randomness.
contract OracleCasino {
    uint256 public constant TICKET_PRICE = 0.01 ether;
    uint256 public constant MAX_TICKETS_PER_PURCHASE = 100;

    IRandomOracle public immutable oracle;
    uint256 public immutable closesAt;
    address[] private _tickets;

    bytes32 public requestId;
    uint256 public randomWord;
    bytes32 public entryDigest;
    address public winner;
    uint256 public prize;
    bool public betsClosed;
    bool public randomnessReady;
    bool public settled;
    bool public prizeClaimed;

    event BetPlaced(address indexed account, uint256 ticketCount);
    event RandomnessRequested(bytes32 indexed requestId);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 randomWord);
    event Settled(address indexed winner, uint256 prize, bytes32 entryDigest);
    event PrizeClaimed(address indexed winner, uint256 prize);

    constructor(IRandomOracle oracle_, uint256 duration) {
        require(address(oracle_) != address(0), "invalid oracle");
        require(duration != 0, "invalid duration");
        oracle = oracle_;
        closesAt = block.timestamp + duration;
    }

    function enter(uint256 count) external payable {
        require(!settled, "round settled");
        require(count != 0 && count <= MAX_TICKETS_PER_PURCHASE, "invalid count");
        require(msg.value == count * TICKET_PRICE, "incorrect payment");

        for (uint256 i; i < count; ++i) {
            _tickets.push(msg.sender);
        }
        emit BetPlaced(msg.sender, count);
    }

    function ticketCount() external view returns (uint256) {
        return _tickets.length;
    }

    function ticketAt(uint256 index) external view returns (address) {
        return _tickets[index];
    }

    function requestRandomness() external {
        require(block.timestamp >= closesAt, "betting open");
        require(_tickets.length != 0, "no tickets");
        require(!betsClosed, "bets closed");

        betsClosed = true;
        requestId = oracle.requestRandomness();
        emit RandomnessRequested(requestId);
    }

    function fulfillRandomness(bytes32 requestId_, uint256 randomWord_) external {
        require(msg.sender == address(oracle), "not oracle");
        require(betsClosed && requestId_ == requestId, "invalid request");
        require(!randomnessReady, "already fulfilled");

        randomWord = randomWord_;
        randomnessReady = true;
        emit RandomnessFulfilled(requestId_, randomWord_);
    }

    function settle() external {
        require(randomnessReady, "randomness pending");
        require(!settled, "already settled");

        bytes32 digest;
        for (uint256 i; i < _tickets.length; ++i) {
            digest = keccak256(abi.encodePacked(digest, _tickets[i]));
        }
        entryDigest = digest;
        winner = _tickets[randomWord % _tickets.length];
        prize = address(this).balance;
        settled = true;
        emit Settled(winner, prize, digest);
    }

    function claimPrize() external {
        require(settled, "not settled");
        require(msg.sender == winner, "not winner");
        require(!prizeClaimed, "already claimed");

        prizeClaimed = true;
        (bool success,) = payable(msg.sender).call{value: prize}("");
        require(success, "claim failed");
        emit PrizeClaimed(msg.sender, prize);
    }
}
