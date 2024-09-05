// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {ICCIPRateProvider} from "../../ccip/RateMsg/interface/ICCIPRateProvider.sol";

interface IXDeposit {
    // Custom errors for various failure scenarios
    error TransferFailed();
    error InvalidDomain();
    error InvalidAddress();
    error InvalidBpsParam();
    error ZeroAmountReceived();
    error NotEnoughBalance();
    error ETHWrappingFailed();
    error DeadlineExpired();
    error InvalidRate();
    error InvalidContract(string param);

    // Events for logging important contract actions
    event Deposit(address indexed user, uint256 amountIn, uint256 amountOut);
    event BridgeExecutorAddressUpdated(address bridgeExecutor, bool allowed);
    event BridgeExecuted(uint32 destinationDomain, address destinationTarget, address delegate, uint256 amount);
    event RateProviderUpdated(address newProvider, address oldProvider);
    event RouterFeeBpsUpdated(uint256 oldRouterFeeBps, uint256 newoldRouterFeeBps);
    event MintSubtractBpsUpdated(uint256 oldSubtractBps, uint256 newSubtractBps);
    event RelayFeeBpsUpdated(uint256 oldRelayFeeBps, uint256 newRelayFeeBps);

    function depositETH(uint256 deadline,uint256 slippage) external payable returns (uint256);

    function depositWETH(uint256 amount, uint256 deadline,uint256 slippage) external returns (uint256);

    function getRate() external view returns (uint256);

    function executeBridge(uint256 relayFee) external payable;

    function withdrawNative(address to) external;

    function withdrawERC20(address token, address to) external;

    function setBridgeExecutor(address bridgeExecutor, bool allowed) external;

    function setRateProvider(ICCIPRateProvider _rateProvider) external;

    function updateRouterFeeBps(uint256 _routerFeeBps) external;
}
