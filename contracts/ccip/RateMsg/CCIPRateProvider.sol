// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interface/ICCIPRateProvider.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";


contract CCIPRateProvider is ICCIPRateProvider, OwnerIsCreator {
    address public receiver;

    uint256 rate;

    modifier onlyReceiver() {
        if (receiver != msg.sender) {
            revert TransferNotAllow();
        }
        _;
    }

    constructor(uint256 _rate, address _receiver) {
        rate = _rate;
        receiver = _receiver;
    }

    function setReceiver(address _receiver) external onlyOwner {
        receiver = _receiver;
    }

    function setRate(uint256 _rate) external onlyReceiver {
        rate = _rate;
    }

    function getRate() external view returns (uint256) {
        return rate;
    }
}