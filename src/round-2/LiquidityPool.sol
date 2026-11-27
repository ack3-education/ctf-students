// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

/// @notice Two-asset exchange that executes trades against a Uniswap V3 pool.
contract LiquidityPool is IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;

    /// @notice Trades must return at least 90% of the quoted output.
    uint256 public constant MIN_OUTPUT_BPS = 9_000;
    uint256 private constant BPS = 10_000;
    uint256 private constant Q96 = 1 << 96;

    IUniswapV3Pool public immutable pool;
    IERC20 public immutable asset0;
    IERC20 public immutable asset1;

    event Trade(address indexed trader, bool asset0ForAsset1, uint256 amountIn, uint256 amountOut);

    constructor(IUniswapV3Pool pool_) {
        pool = pool_;
        asset0 = IERC20(pool_.token0());
        asset1 = IERC20(pool_.token1());
    }

    /// @notice Quotes `amountIn` at the pool's current price, before fees and price impact.
    function previewTrade(bool asset0ForAsset1, uint256 amountIn) public view returns (uint256 amountOut) {
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        if (asset0ForAsset1) {
            amountOut = Math.mulDiv(Math.mulDiv(amountIn, sqrtPriceX96, Q96), sqrtPriceX96, Q96);
        } else {
            amountOut = Math.mulDiv(Math.mulDiv(amountIn, Q96, sqrtPriceX96), Q96, sqrtPriceX96);
        }
    }

    /// @notice Smallest output `trade` accepts for `amountIn`.
    function minimumOutput(bool asset0ForAsset1, uint256 amountIn) public view returns (uint256) {
        return previewTrade(asset0ForAsset1, amountIn) * MIN_OUTPUT_BPS / BPS;
    }

    function trade(bool asset0ForAsset1, uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn != 0 && amountIn <= uint256(type(int256).max), "invalid amount");
        uint256 minAmountOut = minimumOutput(asset0ForAsset1, amountIn);
        (int256 amount0, int256 amount1) = pool.swap(
            msg.sender,
            asset0ForAsset1,
            int256(amountIn),
            asset0ForAsset1 ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(msg.sender)
        );
        uint256 amountInUsed = uint256(asset0ForAsset1 ? amount0 : amount1);
        amountOut = uint256(-(asset0ForAsset1 ? amount1 : amount0));
        require(amountOut >= minAmountOut, "slippage");
        emit Trade(msg.sender, asset0ForAsset1, amountInUsed, amountOut);
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        require(msg.sender == address(pool), "unauthorized callback");
        address payer = abi.decode(data, (address));
        if (amount0Delta > 0) asset0.safeTransferFrom(payer, msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) asset1.safeTransferFrom(payer, msg.sender, uint256(amount1Delta));
    }
}
