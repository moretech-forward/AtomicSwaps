// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Owned Contract
/// @notice Provides access control to contract functions
/// @dev This contract allows for ownership management and ensures only the owner or a designated other party can call certain functions.
abstract contract Owned {
    /// @notice The owner of the contract who initiates the swap.
    /// @dev The owner has exclusive access to functions marked with the `onlyOwner` modifier.
    address public owner;

    /// @notice The other party involved in the swap.
    /// @dev The other party has exclusive access to functions marked with the `onlyOtherParty` modifier.
    address public otherParty;

    /// @notice Ensures a function is called by the owner.
    /// @dev Reverts the transaction if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @notice Ensures a function is called by the otherParty.
    /// @dev Reverts the transaction if called by any account other than the otherParty.
    modifier onlyOtherParty() {
        require(msg.sender == otherParty, "UNAUTHORIZED");
        _;
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @dev Can only be called by the current owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
