// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AtomicSwap} from "./AtomicSwap/AtomicSwap.sol";

/// @title AtomicNativeSwap
/// @notice This contract implements an atomic swap using native Ether transactions.
/// It allows two parties to participate in a trustless exchange of Ether based on the fulfillment of a cryptographic condition.
/// @dev The contract uses a hashlock mechanism for the swap to ensure that only the participant with the correct secret can claim the Ether.
contract AtomicNativeSwap is AtomicSwap {
    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp.
    uint256 public immutable amount;

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
    ) external payable override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
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
    function confirmSwap(
        string calldata _key
    ) external override onlyOtherParty {
        // Key verification
        require(keccak256(abi.encodePacked(_key)) == hashKey, "Invalid key");
        require(block.timestamp <= deadline, "Deadline has passed");
        // Publishing a key
        key = _key;
        // Balance transfer to the caller (otherParty)
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Allows the owner to withdraw the Ether if the swap is not completed by the deadline.
    /// @dev This function checks if the current timestamp is past the deadline, and if so, it allows the owner to withdraw the Ether.
    /// Only callable by the owner.
    function withdrawal() external override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        payable(owner).transfer(address(this).balance);
    }
}
