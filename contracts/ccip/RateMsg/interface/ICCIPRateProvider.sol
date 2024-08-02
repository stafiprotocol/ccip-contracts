// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ICCIPRateProvider {
    error TransferNotAllow();

    function setRate(uint256 _rate) external;

    function getRate() external view returns (uint256);
}
