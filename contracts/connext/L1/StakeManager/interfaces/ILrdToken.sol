// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILrdToken is IERC20 {
    error CallerNotAllowed();
    error AmountZero();
    error AlreadyInitialized();
    error AddressNotAllowed();

    event MinterChanged(address oldMinter, address newMinter);

    function initMinter(address) external;

    function mint(address, uint256) external;

    function updateMinter(address _newMinter) external;
}
