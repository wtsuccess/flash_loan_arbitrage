// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "v3-periphery/libraries/TransferHelper.sol";

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IV3SwapRouter.sol";

contract Arbitrage {
    uint24 public constant poolFee = 3000;
    address public token2;
    address public owner;

    constructor() {
        require(msg.sender != address(0));
        owner = msg.sender;
    }

    function setToken2(address _token2) public onlyOwner {
        token2 = _token2;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        address swapRouter
    ) external {
        TransferHelper.safeTransferFrom(
            _tokenIn,
            msg.sender,
            address(this),
            IERC20(_tokenIn).balanceOf(msg.sender)
        );
        TransferHelper.safeApprove(
            _tokenIn,
            address(swapRouter),
            IERC20(_tokenIn).balanceOf(msg.sender)
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: IERC20(_tokenIn).balanceOf(msg.sender),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swapRouter.exactInputSingle(params);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner!");
    }
}
