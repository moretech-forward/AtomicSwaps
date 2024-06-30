// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "./interfaces/IERC20.sol";
import {AtomicSwap} from "./AtomicSwap/AtomicSwap.sol";

/// @title AtomicERC20Swap
/// @notice This contract facilitates atomic swaps of ERC20 tokens using a secret key for completion.
/// @dev The contract leverages the ERC20 `transferFrom` method for deposits, allowing token swaps based on a hash key and a deadline.
contract AtomicERC20Swap is AtomicSwap {
    /// @notice The ERC20 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC20 type.
    IERC20 public token;

    /// @notice Amount of tokens for swap.
    /// @dev Used when calling the deposit function.
    uint256 public amount;

    /// @notice Creates a new atomic swap with the specified parameters.
    /// @dev Initializes the swap with the token, other party, amount, hash key, and deadline.
    /// @param _token The address of the ERC20 token contract.
    /// @param _otherParty The address of the other party involved in the swap.
    /// @param _amount The amount of tokens to be swapped.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the owner can withdraw the tokens if the swap hasn't been completed.
    /// @param _flag Determines who the swap initiator is and sets the deadline accordingly.
    function createSwap(
        address _token,
        address _otherParty,
        uint256 _amount,
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external onlyOwner isSwap {
        require(
            block.timestamp < _deadline,
            "The deadline is earlier than the current time"
        );

        token = IERC20(_token);
        otherParty = _otherParty;
        amount = _amount;
        hashKey = _hashKey;
        // The user who initiates the swap sends flag = 1 and his funds will be locked for 24 hours longer,
        // done to protect the swap receiver (see documentation)
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
        require(
            token.transferFrom(owner, address(this), _amount),
            "Transfer failed"
        );
    }

    /// @notice Confirms the swap and transfers the ERC20 tokens to the other party if the provided key matches the hash key.
    /// @dev Requires that the key provided hashes to the stored hash key and transfers the token balance from this contract to the other party.
    /// @dev Only callable by the otherParty.
    /// @param _key The secret key to unlock the swap.
    function confirmSwap(
        string calldata _key
    ) external override onlyOtherParty {
        // Key verification
        require(keccak256(abi.encodePacked(_key)) == hashKey, "Invalid key");
        require(block.timestamp <= deadline, "Deadline has passed");
        // Publishing the key
        key = _key;
        // Balance transfer of ERC20 token to the caller (otherParty)
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
        delete deadline;
        delete hashKey;
        delete otherParty;
        delete key;
    }

    /// @notice Allows the owner to withdraw the tokens if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    /// @dev Only callable by the owner.
    function withdrawal() external override onlyOwner isSwap {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
        delete deadline;
    }
}
