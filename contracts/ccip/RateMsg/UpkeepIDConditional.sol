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

interface AutomationRegistrarInterface {
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

contract UpkeepIDConditional is Ownable {
    LinkTokenInterface public i_link;
    AutomationRegistrarInterface public i_registrar;

    event UpkeepRegistered(uint256 upkeepID, RegistrationParams params);
    event LinkUpdated(address newLink);
    event RegistrarUpdated(address newRegistrar);

    error InvalidLinkAddress();
    error InvalidRegistrarAddress();
    error InvalidAmount();
    error InvalidUpkeepContractAddress();
    error InvalidAdminAddress();
    error LinkTransferFailed();
    error LinkApprovalFailed();
    error UpkeepRegistrationFailed();
    error InvalidWithdrawAddress();
    error InvalidWithdrawAmount();

    constructor(LinkTokenInterface link, AutomationRegistrarInterface registrar) Ownable(msg.sender) {
        if (address(link) == address(0)) revert InvalidLinkAddress();
        if (address(registrar) == address(0)) revert InvalidRegistrarAddress();
        i_link = link;
        i_registrar = registrar;
    }

    function setLink(LinkTokenInterface _link) external onlyOwner {
        if (address(_link) == address(0)) revert InvalidLinkAddress();
        i_link = _link;
        emit LinkUpdated(address(_link));
    }

    function setRegistrar(AutomationRegistrarInterface _registrar) external onlyOwner {
        if (address(_registrar) == address(0)) revert InvalidRegistrarAddress();
        i_registrar = _registrar;
        emit RegistrarUpdated(address(_registrar));
    }

    function registerAndPredictID(RegistrationParams calldata params) external returns (uint256) {
        if (params.amount == 0) revert InvalidAmount();
        if (params.upkeepContract == address(0)) revert InvalidUpkeepContractAddress();
        if (params.adminAddress == address(0)) revert InvalidAdminAddress();

        if (!i_link.transferFrom(msg.sender, address(this), params.amount)) revert LinkTransferFailed();
        if (!i_link.approve(address(i_registrar), params.amount)) revert LinkApprovalFailed();

        uint256 upkeepID = i_registrar.registerUpkeep(params);
        if (upkeepID == 0) revert UpkeepRegistrationFailed();

        emit UpkeepRegistered(upkeepID, params);
        return upkeepID;
    }

    function withdrawLink(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidWithdrawAddress();
        if (amount == 0) revert InvalidWithdrawAmount();
        if (!i_link.transfer(to, amount)) revert LinkTransferFailed();
    }
}