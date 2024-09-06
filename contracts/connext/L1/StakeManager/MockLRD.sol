// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {ILrdToken} from "./interfaces/ILrdToken.sol";
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockLRD is ILrdToken, ERC20Burnable {
    address public minter;

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert CallerNotAllowed();
        }
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}


    function initMinter(address _minter) external override {
        if (minter != address(0)) {
            revert AlreadyInitialized();
        }

        minter = _minter;
    }

    // Mint lrdToken
    // Only accepts calls from minter
    function mint(address _to, uint256 _lrdTokenAmount) external override onlyMinter {
        // Check lrdToken amount
        if (_lrdTokenAmount == 0) {
            revert AmountZero();
        }
        // Update balance & supply
        _mint(_to, _lrdTokenAmount);
    }

    function updateMinter(address _newMinter) external override onlyMinter {
        if (_newMinter == address(0)) revert AddressNotAllowed();
        emit MinterChanged(minter, _newMinter);
        minter = _newMinter;
    }
}
