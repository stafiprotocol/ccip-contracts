// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ITokenRate {
    function getRate() external view returns (uint256);
}
