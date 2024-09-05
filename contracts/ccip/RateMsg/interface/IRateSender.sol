// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IRateSender {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error TransferNotAllow();
    error SelectorExist();
    error SelectorNotExist();
    error GasLimitTooLow();
    error InvalidContract(string param);
    error InvalidAddress(string param);

    event TokenInfoAdded(string tokenName, address rateSource);
    event TokenInfoUpdated(string tokenName, address rateSource);
    event MessageSent(
        bytes32 messageId,
        uint64 destinationChainSelector,
        address sender,
        address receiver,
        bytes data,
        address feeToken,
        uint256 fees
    );
    event TokenInfoRemoved(string indexed tokenName);
    event TokenDstInfoAdded(string tokenName, address receiver, address rateProvider, uint64 selector);
    event TokenDstRemoved(string indexed tokenName, uint64 indexed selector);
    event TokenDstInfoUpdated(
        string indexed tokenName,
        address receiver,
        address dstRateProvider,
        uint64 indexed selector
    );
}
