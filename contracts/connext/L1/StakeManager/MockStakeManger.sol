// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {IStakeManager} from "./interfaces/IStakeManager.sol";
import {ILrdToken} from "./interfaces/ILrdToken.sol";

contract MockStakeManager is IStakeManager {

    address public lrdToken;

    function stakeEth() external payable override {
        require(msg.value>0,"Zero amount");
        ILrdToken(lrdToken).mint(msg.sender, msg.value);
    }

    function setLrdToken(address _lrdToken) external  {
        require(lrdToken==address(0),"Already set");
        lrdToken = _lrdToken;
    }

}
