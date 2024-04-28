// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
abstract contract ERC721TokenReceiver {
    /// @notice Handles the receipt of an NFT.
    /// @return Returns the selector to confirm the interface and proper receipt.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
