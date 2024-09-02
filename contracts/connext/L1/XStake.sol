// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IXStake} from "./IXStake.sol";
import {IStakeManager} from "./StakeManager/interfaces/IStakeManager.sol";
import {IConnext} from "../Connext/core/IConnext.sol";
import {IXReceiver} from "../Connext/core/IXReceiver.sol";
import {IWeth} from "../Connext/core/IWeth.sol";
import {IXERC20} from "../xERC20/interfaces/IXERC20.sol";
import {IXERC20Lockbox} from "../xERC20/interfaces/IXERC20Lockbox.sol";
import {ContractChecker} from "../../libraries/ContractChecker.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title XStake
 * @dev A contract for handling cross-chain staking operations.
 * This contract receives WETH from another chain, stakes it to receive Lrd,
 * wraps Lrd into xLrd, and then burns the xLrd (as it was already minted on L2).
 * It implements IXReceiver for cross-chain functionality and various security features.
 */
contract XStake is IXReceiver, IXStake, Initializable,OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using ContractChecker for address;

    // Token contracts and related interfaces
    IERC20 public wETH;
    IERC20 public Lrd;
    IERC20 public xLrd;
    IXERC20Lockbox public xLrdLockbox;
    IStakeManager public stakeManager;
    IConnext public connext;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with necessary parameters and sets up initial roles
     * @param _wETH Address of the WETH token contract
     * @param _Lrd Address of the Lrd token contract
     * @param _xLrd Address of the xLrd token contract
     * @param _xLrdLockbox Address of the xLrd lockbox contract
     * @param _stakeManager Address of the stake manager contract
     * @param _connext Address of the Connext contract for cross-chain operations
     */
    function initialize(
        IERC20 _wETH,
        IERC20 _Lrd,
        IERC20 _xLrd,
        IXERC20Lockbox _xLrdLockbox,
        IStakeManager _stakeManager,
        IConnext _connext,
        address initialOwner
    ) public initializer {
        // Input validation
        if (!address(_wETH).isContract()) revert InvalidContract("_wETH");
        if (!address(_Lrd).isContract()) revert InvalidContract("_Lrd");
        if (!address(_xLrd).isContract()) revert InvalidContract("_xLrd");
        if (!address(_xLrdLockbox).isContract()) revert InvalidContract("_xLrdLockbox");
        if (!address(_stakeManager).isContract()) revert InvalidContract("_stakeManager");
        if (!address(_connext).isContract()) revert InvalidContract("_connext");

        if (initialOwner == address(0)){
            revert InvalidAddress();
        }

        // Initialize inherited contracts
        __Ownable_init(initialOwner);

        // Set contract addresses
        Lrd = _Lrd;
        xLrd = _xLrd;
        stakeManager = _stakeManager;
        wETH = _wETH;
        xLrdLockbox = _xLrdLockbox;
        connext = _connext;
    }

    /**
     * @dev Receives cross-chain transfers, stakes ETH, and mints xLrd
     * @param transferId Unique identifier for the cross-chain transfer
     * @param amount Amount of WETH received
     * @param asset Address of the asset received (should be WETH)
     * @param originSender Address of the sender on the origin chain
     * @param origin Domain ID of the origin chain
     * @return bytes Empty byte array indicating successful execution
     */
    function xReceive(
        bytes32 transferId,
        uint256 amount,
        address asset,
        address originSender,
        uint32 origin,
        bytes memory
    ) external nonReentrant returns (bytes memory) {
        if (msg.sender != address(connext)) {
            revert UnauthorizedSender();
        }

        // Ensure the received asset is WETH
        if (asset != address(wETH)) {
            revert InvalidAsset(address(wETH), asset);
        }

        // Ensure a non-zero amount was received
        if (amount == 0) {
            revert ZeroAmountReceived();
        }

        // Unwrap WETH to ETH
        uint256 ethBalanceBeforeWithdraw = address(this).balance;
        IWeth(address(wETH)).withdraw(amount);
        uint256 ethAmount = address(this).balance - ethBalanceBeforeWithdraw;

        // Stake ETH to receive Lrd
        uint256 lrdBalanceBeforeStake = Lrd.balanceOf(address(this));
        stakeManager.stakeEth{value: ethAmount}();
        uint256 lrdAmount = Lrd.balanceOf(address(this)) - lrdBalanceBeforeStake;

        // Approve Lrd to be locked in the xLrd lockbox
        Lrd.safeIncreaseAllowance(address(xLrdLockbox), lrdAmount);

        // Deposit Lrd to receive xLrd
        uint256 xLrdBalanceBeforeDeposit = xLrd.balanceOf(address(this));
        xLrdLockbox.deposit(lrdAmount);
        uint256 xLrdAmount = xLrd.balanceOf(address(this)) - xLrdBalanceBeforeDeposit;

        // Burn the xLrd (it was already minted on L2)
        IXERC20(address(xLrd)).burn(address(this), xLrdAmount);

        emit LrdMinted(transferId, amount, origin, originSender, lrdAmount);

        return new bytes(0);
    }

    /**
     * @dev Allows BRIDGE_ADMIN to withdraw native tokens from the contract
     * @param to Address to receive the withdrawn tokens
     */
    function withdrawNative(address to) external onlyOwner {
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
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert NotEnoughBalance();
        IERC20(token).safeTransfer(to, balance);
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {}
}