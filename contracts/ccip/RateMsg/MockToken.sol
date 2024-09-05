// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITokenRate} from "./interface/ITokenRate.sol";

contract MockToken is ITokenRate, Ownable {
    uint256 private rate;

    event RateUpdated(uint256 newRate);

    constructor(uint256 _initialRate) Ownable(msg.sender) {
        rate = _initialRate;
    }

    function getRate() external view override returns (uint256) {
        return rate;
    }

    function setRate(uint256 _newRate) external onlyOwner {
        rate = _newRate;
        emit RateUpdated(_newRate);
    }
}