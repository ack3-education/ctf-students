// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GovernanceScheduler {
    struct Operation {
        address target;
        uint256 value;
        bytes data;
        uint256 executeAfter;
        bool processed;
        bool succeeded;
    }

    uint256 public constant MIN_DELAY = 1 days;
    address public immutable governance;
    uint256 public operationCount;
    mapping(uint256 operationId => Operation operation) private _operations;

    event Scheduled(uint256 indexed operationId, address indexed target, uint256 value, uint256 executeAfter);
    event Processed(uint256 indexed operationId, bool success);
    event Cancelled(uint256 indexed operationId);

    constructor() {
        governance = msg.sender;
    }

    function schedule(address target, uint256 value, bytes calldata data) external returns (uint256 operationId) {
        require(msg.sender == governance, "not governance");
        require(target != address(0), "invalid target");
        operationId = operationCount++;
        uint256 executeAfter = block.timestamp + MIN_DELAY;
        _operations[operationId] = Operation(target, value, data, executeAfter, false, false);
        emit Scheduled(operationId, target, value, executeAfter);
    }

    function cancel(uint256 operationId) external {
        require(msg.sender == governance, "not governance");
        Operation storage operation = _operations[operationId];
        require(operation.target != address(0), "unknown operation");
        require(!operation.processed, "already processed");
        operation.processed = true;
        operation.succeeded = false;
        emit Cancelled(operationId);
    }

    function process(uint256 operationId, uint256 callGas) external {
        Operation storage operation = _operations[operationId];
        require(operation.target != address(0), "unknown operation");
        require(!operation.processed, "already processed");
        operation.processed = true;

        try this.dispatch{gas: callGas}(operation.target, operation.value, operation.data) returns (bytes memory) {
            operation.succeeded = true;
        } catch {
            operation.succeeded = false;
        }
        emit Processed(operationId, operation.succeeded);
    }

    function dispatch(address target, uint256 value, bytes calldata data) external returns (bytes memory result) {
        require(msg.sender == address(this), "scheduler only");
        bool success;
        (success, result) = target.call{value: value}(data);
        require(success, "operation failed");
    }

    function operationStatus(uint256 operationId) external view returns (bool processed, bool succeeded) {
        Operation storage operation = _operations[operationId];
        return (operation.processed, operation.succeeded);
    }

    function operationAt(uint256 operationId)
        external
        view
        returns (address target, uint256 value, bytes memory data, uint256 executeAfter, bool processed, bool succeeded)
    {
        Operation storage operation = _operations[operationId];
        return (
            operation.target,
            operation.value,
            operation.data,
            operation.executeAfter,
            operation.processed,
            operation.succeeded
        );
    }

    receive() external payable {}
}
