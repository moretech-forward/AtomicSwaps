// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MockTokenERC721
/// @notice This contract creates a mock ERC721 token for testing and demonstration purposes.
contract MockTokenERC721 is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("MyToken", "MTK") Ownable(msg.sender) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
