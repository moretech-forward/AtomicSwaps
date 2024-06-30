// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AtomicSwap} from "./AtomicSwap/AtomicSwap.sol";

/// @title AtomicNativeSwap
/// @notice This contract implements an atomic swap using native Ether transactions.
/// It allows two parties to participate in a trustless exchange of Ether based on the fulfillment of a cryptographic condition.
/// @dev The contract uses a hashlock mechanism for the swap to ensure that only the participant with the correct secret can claim the Ether.
contract AtomicNativeSwap is AtomicSwap {
    /// @notice Amount of Ether to be swapped.
    /// @dev The contract holds this amount of Ether for the duration of the swap.
    uint256 public amount;

    /// @notice Creates a new atomic swap with the specified parameters.
    /// @dev Initializes the swap with the other party, amount, hash key, and deadline.
    /// @param _otherParty The address of the counterparty.
    /// @param _amount The amount of Ether to be swapped.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the owner can withdraw the Ether if the swap hasn't been completed.
    /// @param _flag Determines who the swap initiator is and sets the deadline accordingly.
    function createSwap(
        address _otherParty,
        uint256 _amount,
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external payable onlyOwner isSwap {
        require(
            block.timestamp < _deadline,
            "The deadline is earlier than the current time"
        );

        otherParty = _otherParty;
        amount = _amount;
        hashKey = _hashKey;
        // The user who initiates the swap sends flag = 1 and their funds will be locked for 24 hours longer,
        // done to protect the swap receiver (see documentation)
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
    }

    /// @notice Confirms the swap and sends the Ether to the other party if the provided key matches the hash key.
    /// @dev The function requires that the caller provides a key that hashes to the pre-stored hash key.
    /// @dev If the condition is met, the contract transfers all the Ether to the other party.
    /// @dev Only callable by the otherParty.
    /// @param _key The secret key that unlocks the swap.
    function confirmSwap(
        string calldata _key
    ) external override onlyOtherParty {
        // Key verification
        require(keccak256(abi.encodePacked(_key)) == hashKey, "Invalid key");
        require(block.timestamp <= deadline, "Deadline has passed");
        // Publishing the key
        key = _key;
        // Balance transfer to the caller (otherParty)
        payable(msg.sender).transfer(address(this).balance);
        // Early reset deadline
        delete deadline;
        delete hashKey;
        delete otherParty;
        delete key;
        delete amount;
    }

    /// @notice Allows the owner to withdraw the Ether if the swap is not completed by the deadline.
    /// @dev This function checks if the current timestamp is past the deadline, and if so, it allows the owner to withdraw the Ether.
    /// @dev Only callable by the owner.
    function withdrawal() external override onlyOwner isSwap {
        payable(owner).transfer(address(this).balance);
        // Early reset deadline
        delete deadline;
    }
}
