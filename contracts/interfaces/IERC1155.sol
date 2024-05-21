// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title ERC1155 Token Standard Interface
/// @notice Defines the standard functions for ERC1155 tokens
/// @dev This interface is used to interact with ERC1155 tokens, following the ERC1155 standard.
interface IERC1155 {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}
