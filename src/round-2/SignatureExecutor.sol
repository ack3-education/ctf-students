// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// I can use this anywhere
contract SignatureExecutor {
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 private constant OPERATION_TYPEHASH =
        keccak256("Operation(address target, uint256 value, bytes data, uint256 nonce)");

    bytes32 public immutable DOMAIN_SEPARATOR;
    address public immutable administrator;
    address public approver;
    uint256 public nonce;
    uint256 public executedCount;

    event ApproverUpdated(address indexed approver);
    event Executed(address indexed signer, address indexed target, uint256 value, uint256 nonce);

    constructor(address initialApprover) {
        require(initialApprover != address(0), "invalid approver");
        administrator = msg.sender;
        approver = initialApprover;
        DOMAIN_SEPARATOR =
            keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256("SignatureExecutor"), keccak256("1"), address(this)));
        emit ApproverUpdated(initialApprover);
    }

    function setApprover(address approver_) external {
        require(msg.sender == administrator, "not administrator");
        require(approver_ != address(0), "invalid approver");
        approver = approver_;
        emit ApproverUpdated(approver_);
    }

    /// @notice EIP-712 digest the approver signs for the next operation.
    function operationDigest(address target, uint256 value, bytes calldata data) external view returns (bytes32) {
        return _operationDigest(target, value, data, nonce);
    }

    function execute(address target, uint256 value, bytes calldata data, uint8 v, bytes32 r, bytes32 s)
        external
        returns (bytes memory result)
    {
        uint256 operationNonce = nonce;
        address signer = ecrecover(_operationDigest(target, value, data, operationNonce), v, r, s);
        require(signer != address(0) && signer == approver, "invalid approval");
        nonce = operationNonce + 1;
        ++executedCount;

        bool success;
        (success, result) = target.call{value: value}(data);
        require(success, "execution failed");
        emit Executed(signer, target, value, operationNonce);
    }

    function _operationDigest(address target, uint256 value, bytes calldata data, uint256 operationNonce)
        private
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(OPERATION_TYPEHASH, target, value, keccak256(data), operationNonce));
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    receive() external payable {}
}
