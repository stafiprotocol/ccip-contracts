// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ContractChecker} from "../ContractChecker.sol";

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

struct Params {
    string name;
    string email;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint96 amount;
}

interface AutomationRegistrarInterface {
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

/// @title RegisterUpkeep - A production-ready contract for registering Chainlink Upkeeps
/// @notice This contract allows users to register Chainlink Upkeeps and manage LINK tokens
/// @dev This contract uses OpenZeppelin's v5 upgradeable contract patterns
contract RegisterUpkeep is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using ContractChecker for address;

    IERC20 public i_link;
    AutomationRegistrarInterface public i_registrar;

    event UpkeepRegistered(uint256 upkeepID, RegistrationParams params);
    event LinkUpdated(address newLink);
    event RegistrarUpdated(address newRegistrar);

    error InvalidLinkAddress();
    error InvalidRegistrarAddress();
    error InvalidAmount();
    error InvalidUpkeepContractAddress();
    error InvalidAdminAddress();
    error UpkeepRegistrationFailed();
    error InvalidWithdrawAddress();
    error InvalidWithdrawAmount();
    error InvalidContract(string param);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contract
    /// @dev This function replaces the constructor for upgradeable contracts
    /// @param link Address of the LINK token contract
    /// @param registrar Address of the AutomationRegistrar contract
    /// @param initialOwner Address of the initial owner
    function initialize(IERC20 link, AutomationRegistrarInterface registrar, address initialOwner) public initializer {
        if (address(link) == address(0)) revert InvalidLinkAddress();
        if (address(registrar) == address(0)) revert InvalidRegistrarAddress();
        if (initialOwner == address(0)) revert InvalidAdminAddress();

        if (!address(link).isContract()) revert InvalidContract("link");
        if (!address(registrar).isContract()) revert InvalidContract("registrar");

        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();

        i_link = link;
        i_registrar = registrar;
    }

    /// @notice Set a new LINK token contract address
    /// @dev Only the owner can call this function
    /// @param _link The new LINK token contract address
    function setLink(IERC20 _link) external onlyOwner {
        if (address(_link) == address(0)) revert InvalidLinkAddress();
        if (!address(_link).isContract()) revert InvalidContract("link");
        i_link = _link;
        emit LinkUpdated(address(_link));
    }

    /// @notice Set a new AutomationRegistrar contract address
    /// @dev Only the owner can call this function
    /// @param _registrar The new AutomationRegistrar contract address
    function setRegistrar(AutomationRegistrarInterface _registrar) external onlyOwner {
        if (address(_registrar) == address(0)) revert InvalidRegistrarAddress();
        if (!address(_registrar).isContract()) revert InvalidContract("registrar");
        i_registrar = _registrar;
        emit RegistrarUpdated(address(_registrar));
    }

    /// @notice Register a new Upkeep and predict its ID
    /// @dev This function is payable to accept LINK tokens
    /// @param params The parameters for the Upkeep registration
    /// @return upkeepID The ID of the registered Upkeep
    function registerAndPredictID(
        Params calldata params
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        if (params.amount == 0) revert InvalidAmount();
        if (params.upkeepContract == address(0)) revert InvalidUpkeepContractAddress();
        if (params.adminAddress == address(0)) revert InvalidAdminAddress();

        if (!(params.upkeepContract).isContract()) revert InvalidContract("upkeepContract");

        RegistrationParams memory registrationParams = RegistrationParams({
            name: params.name,
            encryptedEmail: abi.encode(params.email),
            upkeepContract: params.upkeepContract,
            gasLimit: params.gasLimit,
            adminAddress: params.adminAddress,
            triggerType: 0,
            checkData: "0x",
            triggerConfig: "0x",
            offchainConfig: "0x",
            amount: params.amount
        });

        i_link.safeTransferFrom(msg.sender, address(this), params.amount);
        i_link.safeIncreaseAllowance(address(i_registrar), params.amount);

        uint256 upkeepID = i_registrar.registerUpkeep(registrationParams);
        if (upkeepID == 0) revert UpkeepRegistrationFailed();

        emit UpkeepRegistered(upkeepID, registrationParams);
        return upkeepID;
    }

    /// @notice Withdraw LINK tokens from the contract
    /// @dev Only the owner can call this function
    /// @param to The address to send the LINK tokens to
    /// @param amount The amount of LINK tokens to withdraw
    function withdrawLink(address to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidWithdrawAddress();
        if (amount == 0) revert InvalidWithdrawAmount();
        i_link.safeTransfer(to, amount);
    }

    /// @notice Pause the contract
    /// @dev Only the owner can call this function
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only the owner can call this function
    function unpause() external onlyOwner {
        _unpause();
    }
}
