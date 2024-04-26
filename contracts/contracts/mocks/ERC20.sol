// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockTokenERC20
/// @notice This contract creates a mock ERC20 token for testing and demonstration purposes.
/// @dev This contract extends the OpenZeppelin ERC20 implementation and mints an initial supply upon deployment.
contract MockTokenERC20 is ERC20 {
    /// @dev Initializes the token by setting its name and symbol, and minting an initial supply to the deployer's address.
    /// The initial supply minted is `10 * 10^decimals()`, adjusting for the token's decimals.
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 10 * 10 ** decimals());
    }
}
