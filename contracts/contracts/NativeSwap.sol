// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Owned} from "./Owned.sol";

/// @title AtomicNativeSwap
/// @notice This contract implements an atomic swap using native Ether transactions.
/// It allows two parties to participate in a trustless exchange of Ether based on the fulfillment of a cryptographic condition.
/// @dev The contract uses a hashlock mechanism for the swap to ensure that only the participant with the correct secret can claim the Ether.
contract AtomicNativeSwap is Owned {
    /// @notice One day in timestamp
    /// @dev Used to protect side B
    uint256 constant DAY = 86400;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp.
    uint256 public immutable amount;

    /// @notice The keccak256 hash of the secret key required to confirm the swap.
    /// @dev This hash secures the swap by preventing unauthorized access to the funds.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp.
    uint256 public deadline;

    /// @notice Emitted when the swap is confirmed successfully with the correct key.
    /// @param key The secret key used to unlock the swap.
    event Swap(string indexed key);

    /// @param _otherParty The address of the other party in the swap.
    /// @param _amount How much the user will deposit
    constructor(address _otherParty, uint256 _amount) payable {
        owner = msg.sender;
        otherParty = _otherParty;
        amount = _amount;
    }

    /// @notice Transfer of funds to the contract account
    /// @dev It is necessary to send a value. Only callable by the owner.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the swap can be cancelled.
    /// @param _flag Determines who the swap initiator is.
    function deposit(
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external payable onlyOwner {
        require(msg.value == amount, "Incorrect deposit amount");
        hashKey = _hashKey;
        // The user who initiates the swap sends flag = 1 and his funds will be locked for 24 hours longer,
        // done to protect the swap receiver (see documentation)
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
    }

    /// @notice Confirms the swap and sends the Ether to the other party if the provided key matches the hash key.
    /// @dev The function requires that the caller provides a key that hashes to the pre-stored hash key.
    /// If the condition is met, the contract emits the `Swap` event and transfers all the Ether to the other party.
    /// Only callable by the otherParty.
    /// @param _key The secret key that unlocks the swap.
    function confirmSwap(string calldata _key) external onlyOtherParty {
        require(
            hashKey == keccak256(abi.encodePacked(_key)),
            "The key does not match the hash"
        );

        emit Swap(_key);
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Allows the owner to withdraw the Ether if the swap is not completed by the deadline.
    /// @dev This function checks if the current timestamp is past the deadline, and if so, it allows the owner to withdraw the Ether.
    /// Only callable by the owner.
    function withdrawal() external onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        payable(owner).transfer(address(this).balance);
    }
}
