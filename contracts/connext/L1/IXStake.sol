// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXStake {
    // Events for logging important contract actions
    event LrdMinted(bytes32 transferId, uint256 amount, uint32 origin, address originSender, uint256 lrdAmount);

    // Custom errors for various failure scenarios
    error InvalidAddress();
    error UnauthorizedSender();
    error ZeroAmountReceived();
    error InvalidAsset(address expected, address received);
    error InvalidContract(string param);
    error TransferFailed();
    error NotEnoughBalance();

    function withdrawNative(address to) external;

    function withdrawERC20(IERC20 token, address to) external;
}
