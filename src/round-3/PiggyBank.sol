// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Savers deposit ETH and keep a history of every deposit.
contract PiggyBank {
    mapping(address saver => uint256[] amounts) private _deposits;
    mapping(address saver => uint256 total) public totalDeposited;

    event Deposited(address indexed saver, uint256 indexed index, uint256 amount);
    event Withdrawn(address indexed saver, uint256 amount);

    function deposit() external payable {
        require(msg.value != 0, "empty deposit");
        _deposits[msg.sender].push(msg.value);
        totalDeposited[msg.sender] += msg.value;
        emit Deposited(msg.sender, _deposits[msg.sender].length, msg.value);
    }

    function depositCount(address saver) external view returns (uint256) {
        return _deposits[saver].length;
    }

    function depositAt(address saver, uint256 index) external view returns (uint256) {
        return _deposits[saver][index];
    }

    function lastDeposit(address saver) external view returns (uint256) {
        uint256 lastIndex = _deposits[saver].length - 1;
        return _deposits[saver][lastIndex];
    }
}
