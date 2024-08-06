// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ContractChecker
/// @notice A library for checking if an address is a contract
/// @dev This library can be used by multiple contracts to avoid code duplication
library ContractChecker {
    /// @notice Check if an address is a contract
    /// @dev This function checks if the given address contains code
    /// @param addr The address to check
    /// @return bool Returns true if the address is a contract, false otherwise
    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }
}