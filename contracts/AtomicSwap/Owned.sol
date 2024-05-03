// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Provides access control to contract functions
abstract contract Owned {
    /// @notice The owner of the contract who initiates the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable owner;

    /// @notice The other party involved in the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable otherParty;

    /// @notice Ensures a function is called by the owner.
    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @notice Ensures a function is called by the otherParty.
    modifier onlyOtherParty() virtual {
        require(msg.sender == otherParty, "UNAUTHORIZED");
        _;
    }
}
