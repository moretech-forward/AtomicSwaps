// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeMint(address to) external;
}
