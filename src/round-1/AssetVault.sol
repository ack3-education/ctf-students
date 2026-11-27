// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Share vault for a configured conventional ERC-20 whose transfers preserve amounts.
contract AssetVault {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address account => uint256 shares) public sharesOf;

    event Deposited(address indexed source, address indexed beneficiary, uint256 assets, uint256 shares);
    event Withdrawn(address indexed account, uint256 shares, uint256 assets);

    constructor(IERC20 asset_) {
        require(address(asset_) != address(0), "invalid asset");
        asset = asset_;
    }

    function totalAssets() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets) external returns (uint256 shares) {
        return depositFor(msg.sender, msg.sender, assets);
    }

    function depositFor(address source, address beneficiary, uint256 assets) public returns (uint256 shares) {
        require(beneficiary != address(0), "invalid beneficiary");
        require(assets > 0, "zero assets");
        asset.safeTransferFrom(source, address(this), assets);
        shares = assets;
        sharesOf[beneficiary] = shares;
        totalShares += shares;
        emit Deposited(source, beneficiary, assets, shares);
    }

    function withdraw(uint256 shares, address recipient) external returns (uint256 assets) {
        require(shares > 0, "zero shares");
        require(sharesOf[msg.sender] >= shares, "insufficient shares");
        assets = shares;
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        asset.safeTransfer(recipient, assets);
        emit Withdrawn(msg.sender, shares, assets);
    }
}
