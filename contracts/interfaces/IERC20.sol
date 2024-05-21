// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title ERC20 Token Standard Interface
/// @notice Defines the standard functions for ERC20 tokens
/// @dev This interface is used to interact with ERC20 tokens, following the ERC20 standard.
interface IERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256 balance);
}
