// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "./Owned.sol";

/// @title A contract for atomic swapping of assets with access control.
/// @notice Provides access control and time-bound mechanisms for atomic swap transactions.
/// @dev Inherits from the Owned contract to utilize ownership-based access control.
abstract contract AtomicSwap is Owned {
    /// @notice One day in timestamp
    /// @dev Used as a time unit for defining deadlines, specifically to protect side B in transactions.
    uint256 constant DAY = 86400;

    /// @notice The keccak256 hash of the secret key required to confirm the swap.
    /// @dev This hash secures the swap by preventing unauthorized access to the funds.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp, this is used to enforce the time limitation on the swap.
    uint256 public deadline;

    /// @notice Emitted when the swap is confirmed successfully with the correct key.
    /// @param key The secret key used to unlock the swap.
    event SwapConfirmed(string indexed key);

    /// @notice Allows the owner to deposit assets into the contract for swapping.
    /// @dev This function can only be called by the contract owner.
    /// @param _hashKey The keccak256 hash of the secret key required to release the funds.
    /// @param _deadline The Unix timestamp after which the swap offer is no longer valid.
    /// @param _flag Additional flag for extended functionality or future use.
    function deposit(
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external payable virtual onlyOwner {}

    /// @notice Confirms the swap using a secret key, releasing the funds to the other party.
    /// @dev This function can only be called by a designated party other than the owner.
    /// @param _key The secret key that, if correct, will unlock and transfer the assets.
    function confirmSwap(
        string calldata _key
    ) external virtual onlyOtherParty {}

    /// @notice Allows the owner to withdraw assets from the contract.
    /// @dev This function can only be called by the owner, typically used when the swap did not occur before the deadline.
    function withdrawal() external virtual onlyOwner {}
}
