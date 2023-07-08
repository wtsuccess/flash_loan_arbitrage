// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "../interfaces/IV3SwapRouter.sol";
import "./Arbitrage.sol";

/**
 * @title Flash loan arbitrage
 * @author Abinash Burman
 * @notice What we are doing here is, we borrow _asset from pool by calling flashLoanSimple() ==> then we swap that _asset for a token from Dex-A ==> if Dex-B which gives good price of
 * that token in the _asset form, then we swap the token for the _asset ==> the asset will come to our contract ==> The Aave Pool will deduct its _amount + premium from our contract ==>
 * rest of _asset is our profit.
 */

contract Flash is FlashLoanSimpleReceiverBase, Arbitrage {
    ISwapRouter immutable swapRouter1;
    IV3SwapRouter immutable swapRouter2;

    constructor(
        address _address,
        ISwapRouter _swapRouter1,
        IV3SwapRouter _swapRouter2
    ) FlashLoanSimpleReceiverBase(_address) {
        swapRouter1 = _swapRouter1;
        swapRouter2 = _swapRouter2;
    }

    function createFlashLoan(address _asset, uint256 _amount) public {
        address receiverAddress = address(this);
        bytes calldata params = "";
        uint16 refferalCode = 0;
        POOL.flashLoanSimple( // my contract borrows _asset from pool by calling flashLoanSimple()
            receiverAddress,
            _asset,
            _amount,
            params,
            refferalCode
        );
    }

    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _premium,
        address _initiator,
        bytes calldata _params
    ) external returns (bool) {
        /**
         * PERFORM ARBITRAGE OR DO WHATEVER YOU WANT
         * What we will do here?
         * We swap the _asset with some token in Dex-A ==> then again swap that token with the _asset in Dex-B
         * What we need ?
         * We need 2 dex's router address, and a token address.
         */
        uint256 initialBalance = getAssetBalance(_asset);
        swap(_asset, token2, swapRouter1); // got token2 by swapping in Uniswap
        swap(token2, _asset, swapRouter2);
        uint256 finalBalance = getAssetBalance(_asset);
        require(initialBalance < finalBalance, "Arbitrage reverted due to loss!");

        uint256 totalAmount = _amount + _premium;
        IERC20(_asset).approve(address(POOL), totalAmount);
        return true;
    }

    function getAssetBalance(address _asset) internal returns(uint256){
        return IERC20(_asset).balanceOf(address(this));
    }
}