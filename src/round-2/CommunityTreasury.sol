// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Community funds managed by an owner and a day-to-day payment operator.
contract CommunityTreasury {
    address public immutable owner;
    address public operator;
    uint256 public accountedBalance;
    mapping(bytes32 paymentId => bool completed) public paid;

    event OperatorUpdated(address indexed operator);
    event Payment(bytes32 indexed paymentId, address indexed recipient, uint256 amount, bool success);
    event Withdrawn(address indexed recipient, uint256 amount);

    constructor(address operator_) payable {
        require(operator_ != address(0), "invalid operator");
        owner = msg.sender;
        operator = operator_;
        accountedBalance = msg.value;
    }

    function setOperator(address operator_) external {
        require(msg.sender == owner, "not owner");
        require(operator_ != address(0), "invalid operator");
        operator = operator_;
        emit OperatorUpdated(operator_);
    }

    function pay(bytes32 paymentId, address payable recipient, uint256 amount) external returns (bool success) {
        require(msg.sender == operator, "not operator");
        require(recipient != address(0), "invalid recipient");
        require(amount != 0 && amount <= accountedBalance, "invalid amount");
        require(!paid[paymentId], "payment completed");

        paid[paymentId] = true;
        accountedBalance -= amount;
        (success,) = recipient.call{value: amount}("");
        emit Payment(paymentId, recipient, amount, success);
    }

    function withdrawAll(address payable recipient) external {
        require(msg.sender == owner, "not owner");
        require(recipient != address(0), "invalid recipient");
        require(address(this).balance == accountedBalance, "unexpected balance");

        uint256 amount = accountedBalance;
        (bool success,) = recipient.call{value: amount}("");
        require(success, "withdrawal failed");
        accountedBalance -= amount;
        emit Withdrawn(recipient, amount);
    }

    receive() external payable {
        accountedBalance += msg.value;
    }
}
