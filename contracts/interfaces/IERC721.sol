// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title ERC721 Token Standard Interface
/// @notice Defines the standard functions for ERC721 tokens
/// @dev This interface is used to interact with ERC721 tokens, following the ERC721 standard.
interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeMint(address to) external;
}
