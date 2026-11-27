// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract WalletModule {
    address public owner;

    event Initialized(address indexed owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initialize(address owner_) external {
        require(owner == address(0), "already initialized");
        require(owner_ != address(0), "invalid owner");
        owner = owner_;
        emit Initialized(owner_);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function withdraw(address payable recipient, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        (bool success,) = recipient.call{value: amount}("");
        require(success, "withdrawal failed");
    }
}

contract ManagedProxy {
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation, address indexed caller);

    constructor(address implementation_) {
        _setAdmin(msg.sender);
        _setImplementation(implementation_);
    }

    function admin() public view returns (address admin_) {
        bytes32 slot = ADMIN_SLOT;
        assembly ("memory-safe") {
            admin_ := sload(slot)
        }
    }

    function implementation() public view returns (address implementation_) {
        return _implementation();
    }

    function setImplementation(address implementation_) external {
        _setImplementation(implementation_);
        emit Upgraded(implementation_, msg.sender);
    }

    fallback() external payable {
        address target = _implementation();
        assembly ("memory-safe") {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }

    receive() external payable {}

    function _implementation() private view returns (address implementation_) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly ("memory-safe") {
            implementation_ := sload(slot)
        }
    }

    function _setImplementation(address implementation_) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly ("memory-safe") {
            sstore(slot, implementation_)
        }
    }

    function _setAdmin(address admin_) private {
        bytes32 slot = ADMIN_SLOT;
        assembly ("memory-safe") {
            sstore(slot, admin_)
        }
    }
}
