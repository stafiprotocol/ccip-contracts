// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct DestinationInfo {
    address receiver;
    address dstRateProvider;
}

struct RateMsg {
    address dstRateProvider;
    uint256 rate;
}
