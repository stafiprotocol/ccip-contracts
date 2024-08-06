// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

// https://docs.chain.link/chainlink-automation/guides/register-upkeep-in-contract
/**
 * string name = "test upkeep";
 * bytes encryptedEmail = 0x;
 * address upkeepContract = 0x...;
 * uint32 gasLimit = 500000;
 * address adminAddress = 0x....;
 * uint8 triggerType = 0;
 * bytes checkData = 0x;
 * bytes triggerConfig = 0x;
 * bytes offchainConfig = 0x;
 * uint96 amount = 1000000000000000000;
 */

interface AutomationRegistrarInterface {
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

contract UpkeepIDConditional is Ownable {
    LinkTokenInterface public i_link;
    AutomationRegistrarInterface public i_registrar;

    event UpkeepRegistered(uint256 upkeepID, RegistrationParams params);
    event LinkUpdated(address newLink);
    event RegistrarUpdated(address newRegistrar);

    constructor(LinkTokenInterface link, AutomationRegistrarInterface registrar) Ownable(msg.sender) {
        require(address(link) != address(0), "Invalid LINK address");
        require(address(registrar) != address(0), "Invalid registrar address");
        i_link = link;
        i_registrar = registrar;
    }

    function setLink(LinkTokenInterface _link) external onlyOwner {
        require(address(_link) != address(0), "Invalid LINK address");
        i_link = _link;
        emit LinkUpdated(address(_link));
    }

    function setRegistrar(AutomationRegistrarInterface _registrar) external onlyOwner {
        require(address(_registrar) != address(0), "Invalid registrar address");
        i_registrar = _registrar;
        emit RegistrarUpdated(address(_registrar));
    }

    function registerAndPredictID(RegistrationParams calldata params) external returns (uint256) {
        require(params.amount > 0, "Amount must be greater than 0");
        require(params.upkeepContract != address(0), "Invalid upkeep contract address");
        require(params.adminAddress != address(0), "Invalid admin address");

        require(i_link.transferFrom(msg.sender, address(this), params.amount), "LINK transfer failed");
        require(i_link.approve(address(i_registrar), params.amount), "LINK approval failed");

        uint256 upkeepID = i_registrar.registerUpkeep(params);
        require(upkeepID != 0, "Upkeep registration failed");

        emit UpkeepRegistered(upkeepID, params);
        return upkeepID;
    }

    function withdrawLink(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(i_link.transfer(to, amount), "LINK transfer failed");
    }
}
