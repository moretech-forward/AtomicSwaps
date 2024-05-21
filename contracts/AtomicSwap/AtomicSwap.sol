// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "./Owned.sol";

/// @title A contract for atomic swapping of assets with access control.
/// @notice Provides mechanisms for atomic swap transactions with time-bound constraints and access control.
/// @dev Inherits from the Owned contract to leverage ownership-based access control.
abstract contract AtomicSwap is Owned {
    /// @notice The address of this contract instance.
    /// @dev Used as an auxiliary variable for frontend interaction.
    address public immutable myAddr;

    /// @notice The secret key used to unlock the swap.
    /// @dev This variable should be securely managed and not exposed publicly.
    string public key;

    /// @notice One day in seconds.
    /// @dev Used as a time unit to define deadlines, particularly to protect side B in transactions.
    uint256 constant DAY = 86400;

    /// @notice The keccak256 hash of the secret key required to confirm the swap.
    /// @dev Ensures the security of the swap by preventing unauthorized access to the funds.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp, used to enforce the time limitation on the swap.
    uint256 public deadline;

    /// @notice Modifier to check if the swap deadline has passed.
    /// @dev Reverts the transaction if the current block timestamp is less than the deadline.
    modifier isSwap() {
        require(block.timestamp > deadline, "Swap not yet expired");
        _;
    }

    /// @notice Initializes the contract setting the deployer as the owner and the contract address.
    /// @dev Sets the owner to the deployer and myAddr to the contract's address.
    constructor() payable {
        owner = msg.sender;
        myAddr = address(this);
    }

    /// @notice Confirms the swap using a secret key, releasing the funds to the other party.
    /// @dev This function can only be called by a designated party other than the owner.
    /// @param _key The secret key that, if correct, will unlock and transfer the assets.
    function confirmSwap(
        string calldata _key
    ) external virtual onlyOtherParty {}

    /// @notice Allows the owner to withdraw assets from the contract.
    /// @dev This function can only be called by the owner, typically used when the swap did not occur before the deadline.
    function withdrawal() external virtual onlyOwner {}

    /// @notice Fallback function to accept incoming ether.
    /// @dev Allows the contract to receive ether.
    receive() external payable {}
}
