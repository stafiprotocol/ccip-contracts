// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IXDeposit} from "./IXDeposit.sol";
import {IWeth} from "../Connext/core/IWeth.sol";
import {IConnext} from "../Connext/core/IConnext.sol";
import {TokenId} from "../Connext/libraries/TokenId.sol";
import {IXERC20} from "../xERC20/interfaces/IXERC20.sol";
import {ICCIPRateProvider} from "../../ccip/RateMsg/interface/ICCIPRateProvider.sol";
import {ContractChecker} from "../../libraries/ContractChecker.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title XDeposit
 * @dev A contract for handling deposits of ETH/WETH, minting xLrd tokens, and bridging assets across chains.
 * This contract uses Connext for cross-chain operations and implements various security and administrative features.
 */
contract XDeposit is
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IXDeposit
{
    using SafeERC20 for IERC20;
    using ContractChecker for address;

    // contracts
    IERC20 public xLrd;
    IERC20 public wETH;
    IERC20 public nextWETH;
    IConnext public connext;
    ICCIPRateProvider public rateProvider;

    // Bridge-related parameters
    uint256 public routerFeeBps;
    uint256 public relayFeeBps;
    uint256 public mintSubtractBps;
    uint256 public remUnwarpRelayFee;
    uint32 public destinationDomain; // https://docs.connext.network/resources/deployments
    address public recipient;

    // Constants
    uint32 public constant BPS_BASIS = 10000; // 30 basis points = 0.3%
    uint32 public constant MAX_BPS = 1000; // 1000 basis points = 10%
    uint256 public constant EIGHTEEN_DECIMALS = 1e18;

    // Access control roles
    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with necessary parameters and sets up initial roles
     * @param _xLrd Address of the xLrd token contract
     * @param _wETH Address of the WETH token contract
     * @param _nextWETH Address of the nextWETH token contract used for cross-chain operations
     * @param _connext Address of the Connext contract for cross-chain operations
     * @param _rateProvider Address of the rate provider contract
     * @param _destinationDomain Domain ID of the destination chain for bridging
     * @param _recipient Target address on the destination chain for bridging
     * @param bridgeAdmin Address to be granted bridge admin roles
     * @param admin Address of the initial admin
     */
    function initialize(
        IERC20 _xLrd,
        IERC20 _wETH,
        IERC20 _nextWETH,
        IConnext _connext,
        ICCIPRateProvider _rateProvider,
        uint32 _destinationDomain,
        address _recipient,
        address bridgeAdmin,
        address admin
    ) public initializer {
        // Input validation
        if (!address(_xLrd).isContract()) revert InvalidContract("_xLrd");
        if (!address(_wETH).isContract()) revert InvalidContract("_wETH");
        if (!address(_rateProvider).isContract()) revert InvalidContract("_rateProvider");
        if (!address(_nextWETH).isContract()) revert InvalidContract("_nextWETH");
        if (!address(_connext).isContract()) revert InvalidContract("_connext");

        if (_destinationDomain == 0) {
            revert InvalidDomain();
        }

        if (_recipient == address(0)) {
            revert InvalidAddress();
        }

        // Initialize inherited contracts
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BRIDGE_ADMIN_ROLE, bridgeAdmin);

        // Set contract addresses
        xLrd = _xLrd;
        wETH = _wETH;
        nextWETH = _nextWETH;
        connext = _connext;
        rateProvider = _rateProvider;

        // Set bridge parameters
        destinationDomain = _destinationDomain;
        recipient = _recipient;
        routerFeeBps = 5; // Connext router fee is 5 basis points (0.05%)
    }

    /// @notice Pause the contract
    /// @notice Only callable by accounts with DEFAULT_ADMIN_ROLE
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    /// @notice Only callable by accounts with DEFAULT_ADMIN_ROLE
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows users to deposit ETH, which is then wrapped to WETH and processed
     * @param deadline Timestamp by which the transaction must be included to be valid
     * @param slippage Maximum acceptable slippage for the swap, in basis points (e.g., 100 = 1%)
     * @return Amount of xLrd tokens minted
     */
    function depositETH(
        uint256 deadline,
        uint256 slippage
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.value == 0) {
            revert ZeroAmountReceived();
        }

        uint256 wethBalanceBefore = wETH.balanceOf(address(this));

        // Wrap the deposited ETH to WETH
        IWeth(address(wETH)).deposit{value: msg.value}();
        uint256 newlyWrappedWETH = wETH.balanceOf(address(this)) - wethBalanceBefore;
        if (newlyWrappedWETH == 0) {
            revert ETHWrappingFailed();
        }

        return _deposit(newlyWrappedWETH, deadline, slippage);
    }

    /**
     * @dev Allows users to deposit WETH directly
     * @param amount Amount of WETH to deposit
     * @param deadline Timestamp by which the transaction must be included to be valid
     * @param slippage Maximum acceptable slippage for the swap, in basis points (e.g., 100 = 1%)
     * @return Amount of xLrd tokens minted
     */
    function depositWETH(
        uint256 amount,
        uint256 deadline,
        uint256 slippage
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (amount == 0) {
            revert ZeroAmountReceived();
        }

        wETH.safeTransferFrom(msg.sender, address(this), amount);

        return _deposit(amount, deadline, slippage);
    }

    /**
     * @dev Internal function to process deposits, swap WETH for nextWETH, and mint xLrd tokens
     * @param amountIn Amount of WETH to process
     * @param deadline Timestamp by which the transaction must be included to be valid
     * @param slippage Maximum acceptable slippage for the swap, in basis points (e.g., 100 = 1%)
     * @return Amount of xLrd tokens minted
     */
    function _deposit(uint256 amountIn, uint256 deadline, uint256 slippage) internal returns (uint256) {
        if (block.timestamp > deadline) revert DeadlineExpired();

        uint256 relayFee = (amountIn * relayFeeBps) / BPS_BASIS;
        amountIn -= relayFee;
        remUnwarpRelayFee += relayFee;

        // Approve the deposit asset to the connext contract
        wETH.safeIncreaseAllowance(address(connext), amountIn);

        // Swap WETH for nextWETH using Connext
        TokenId memory tokenId = connext.getTokenId(address(wETH));
        uint32 domain = tokenId.domain;
        bytes32 id = tokenId.id;

        uint256 minNextWETH = 0;
        if (slippage > 0) {
            minNextWETH = (amountIn * (BPS_BASIS - slippage)) / BPS_BASIS;
        }
        uint256 amountNextWETH = connext.swapExact(
            keccak256(abi.encode(id, domain)),
            amountIn,
            address(wETH),
            address(nextWETH),
            minNextWETH,
            deadline
        );

        // Subtract the bridge router fee
        if (routerFeeBps > 0) {
            uint256 fee = (amountNextWETH * routerFeeBps) / BPS_BASIS;
            amountNextWETH -= fee;
        }

        if (amountNextWETH == 0) {
            revert ZeroAmountReceived();
        }

        // Calculate the amount of xLrd to mint
        uint256 xLrdAmount = (EIGHTEEN_DECIMALS * amountNextWETH) / getRate();
        // Reduce the number of xLrdAmount mint by mintSubtractBps
        if (mintSubtractBps > 0) {
            xLrdAmount = (xLrdAmount * (BPS_BASIS - mintSubtractBps)) / BPS_BASIS;
        }

        // Mint xLrd to the user
        IXERC20(address(xLrd)).mint(msg.sender, xLrdAmount);

        emit Deposit(msg.sender, amountIn, xLrdAmount);
        return xLrdAmount;
    }

    /**
     * @dev Executes the bridge operation, transferring nextWETH to the L1 contract
     * This function should only be callable by accounts with BRIDGE_ADMIN_ROLE
     * @param relayFee The fee required for relaying the transaction across chains
     * @notice The required relay fee needs to be estimated based on the current chain conditions
     */
    function executeBridge(uint256 relayFee) external payable whenNotPaused nonReentrant onlyRole(BRIDGE_ADMIN_ROLE) {
        uint256 balance = nextWETH.balanceOf(address(this));
        if (balance == 0) {
            revert NotEnoughBalance();
        }

        // Check if the remaining relay fee + current ETH balance is sufficient to pay the relayFee, return an error if insufficient
        if (remUnwarpRelayFee + address(this).balance < relayFee) {
            revert NotEnoughBalance();
        }

        // If the contract's native ETH balance can cover the relayFee, pay directly;
        // otherwise, withdraw the corresponding amount of WETH to ETH from remUnwarpRelayFee
        if (address(this).balance < relayFee) {
            // Withdraw remUnwarpRelayFee worth of WETH to pay the relay fee
            uint256 amountToWithdraw = remUnwarpRelayFee;
            IWeth(address(wETH)).withdraw(amountToWithdraw);
            remUnwarpRelayFee = 0; // Reset remaining relay fee after withdrawal
        }

        // Approve nextWETH to the connext contract
        nextWETH.safeIncreaseAllowance(address(connext), balance);

        // Execute the cross-chain transfer
        connext.xcall{value: relayFee}(
            destinationDomain,
            recipient,
            address(nextWETH),
            msg.sender,
            balance,
            0,
            abi.encode(balance)
        );

        emit BridgeExecuted(destinationDomain, recipient, msg.sender, balance);
    }

    /**
     * @dev Allows BRIDGE_ADMIN to withdraw native tokens from the contract
     * @param to Address to receive the withdrawn tokens
     */
    function withdrawNative(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NotEnoughBalance();

        (bool success, ) = payable(to).call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Allows BRIDGE_ADMIN to withdraw ERC20 tokens from the contract
     * @param token Address of the ERC20 token to withdraw
     * @param to Address to receive the withdrawn tokens
     */
    function withdrawERC20(address token, address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert NotEnoughBalance();
        IERC20(token).safeTransfer(to, balance);
    }

    /**
     * @dev Grants or revokes the BRIDGE_ADMIN_ROLE for a given address
     * @param bridgeExecutor Address to grant or revoke the BRIDGE_ADMIN_ROLE
     * @param allowed If true, grants the role; if false, revokes the role
     * @notice Only callable by accounts with DEFAULT_ADMIN_ROLE
     */
    function setBridgeExecutor(address bridgeExecutor, bool allowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (allowed) {
            _grantRole(BRIDGE_ADMIN_ROLE, bridgeExecutor);
        } else {
            _revokeRole(BRIDGE_ADMIN_ROLE, bridgeExecutor);
        }
        emit BridgeExecutorAddressUpdated(bridgeExecutor, allowed);
    }

    /**
     * @dev Updates the rate provider address
     * @param _rateProvider New rate provider address
     */
    function setRateProvider(ICCIPRateProvider _rateProvider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldProvider = address(rateProvider);
        rateProvider = _rateProvider;
        emit RateProviderUpdated(oldProvider, address(_rateProvider));
    }

    /**
     * @dev Updates the bridge router fee in basis points
     * @param _routerFeeBps New bridge router fee in basis points (e.g., 30 = 0.3%)
     * @notice The value should be within a reasonable range (e.g., 0-1000) to avoid excessive fees
     */
    function updateRouterFeeBps(uint256 _routerFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_routerFeeBps > MAX_BPS) {
            revert InvalidBpsParam();
        }
        emit RouterFeeBpsUpdated(routerFeeBps, _routerFeeBps);
        routerFeeBps = _routerFeeBps;
    }

    /**
     * @dev Updates the mint subtract basis points
     * @param _mintSubtractBps New mint subtract value in basis points
     * @notice This value is used to reduce the amount of xLrd minted during deposits
     * @notice The value is in basis points, where 10000 = 100%. For example, 100 = 1%
     * @notice Only callable by accounts with DEFAULT_ADMIN_ROLE
     */
    function updateMintSubtractBps(uint256 _mintSubtractBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_mintSubtractBps > MAX_BPS) {
            revert InvalidBpsParam();
        }
        emit MintSubtractBpsUpdated(mintSubtractBps, _mintSubtractBps);
        mintSubtractBps = _mintSubtractBps;
    }

    /**
     * @dev Updates the relay fee basis points
     * @param _relayFeeBps New relay fee value in basis points
     * @notice This fee is deducted from the deposit amount to cover relay costs
     * @notice The value is in basis points, where 10000 = 100%. For example, 30 = 0.3%
     * @notice Only callable by accounts with DEFAULT_ADMIN_ROLE
     */
    function updateRelayFeeBps(uint256 _relayFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_relayFeeBps > MAX_BPS) {
            revert InvalidBpsParam();
        }
        emit RelayFeeBpsUpdated(relayFeeBps, _relayFeeBps);
        relayFeeBps = _relayFeeBps;
    }

    /**
     * @dev Retrieves the current exchange rate from the rate provider
     * @return Current exchange rate
     */
    function getRate() public view returns (uint256) {
        uint256 rate = ICCIPRateProvider(rateProvider).getRate();
        if (rate < 1 * EIGHTEEN_DECIMALS) {
            revert InvalidRate();
        }
        return rate;
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {}
}
