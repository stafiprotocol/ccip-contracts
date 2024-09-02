// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenId} from "../libraries/TokenId.sol";

interface IConnext {
    // ============ BRIDGE ==============
    function xcall(
        uint32 _destination,
        address _to,
        address _asset,
        address _delegate,
        uint256 _amount,
        uint256 _slippage,
        bytes calldata _callData
    ) external payable returns (bytes32);

    function getTokenId(address _candidate) external view returns (TokenId memory);

    function swapExact(
        bytes32 canonicalId,
        uint256 amountIn,
        address assetIn,
        address assetOut,
        uint256 minAmountOut,
        uint256 deadline
    ) external payable returns (uint256);
}
