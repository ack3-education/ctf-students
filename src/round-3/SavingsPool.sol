// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SavingsPool {
    uint256 public totalShares;
    mapping(address account => uint256 shares) public sharesOf;

    event Contributed(address indexed account, uint256 assets, uint256 shares);
    event Redeemed(address indexed account, uint256 shares, uint256 assets);
    event YieldAdded(address indexed donor, uint256 amount);

    function totalAssets() public view returns (uint256) {
        return address(this).balance;
    }

    function sharePrice() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return address(this).balance * 1e18 / totalShares;
    }


    function shareCost(uint256 shares) external view returns (uint256) {
        return _shareCost(shares, address(this).balance);
    }

    function contribute() external payable returns (uint256 shares) {
        uint256 assetsBefore = address(this).balance - msg.value;
        if (totalShares == 0) {
            shares = msg.value;
        } else {
            shares = msg.value * totalShares / assetsBefore;
        }

        totalShares += shares;
        sharesOf[msg.sender] += shares;
        emit Contributed(msg.sender, msg.value, shares);
    }


    function contributeShares(uint256 shares) external payable {
        require(shares != 0, "zero shares");
        require(msg.value == _shareCost(shares, address(this).balance - msg.value), "incorrect payment");

        totalShares += shares;
        sharesOf[msg.sender] += shares;
        emit Contributed(msg.sender, msg.value, shares);
    }

    function addYield() external payable {
        emit YieldAdded(msg.sender, msg.value);
    }

    function redeem(uint256 shares) external {
        require(sharesOf[msg.sender] >= shares, "insufficient shares");
        uint256 assets = shares * address(this).balance / totalShares;
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        payable(msg.sender).transfer(assets);
        emit Redeemed(msg.sender, assets, shares);
    }

    function _shareCost(uint256 shares, uint256 assets) private view returns (uint256) {
        if (totalShares == 0) return shares;
        return (shares * assets + totalShares - 1) / totalShares;
    }
}
