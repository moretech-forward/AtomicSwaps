// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721} from "./interfaces/IERC721.sol";
import {ERC721TokenReceiver} from "./TokenReceivers/ERC721TokenReceiver.sol";
import {AtomicSwap} from "./AtomicSwap/AtomicSwap.sol";

/// @title AtomicERC721Swap
/// @notice A contract for a cross-chain atomic swap that stores a token identifier that can be exchanged for any other asset
contract AtomicERC721Swap is AtomicSwap, ERC721TokenReceiver {
    /// @notice The ERC721 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC721 type.
    IERC721 public immutable token;

    /// @notice Identifier of the token to be swapped.
    /// @dev The contract interacts only with this token identifier.
    uint256 public immutable id;

    /// @param _token The address of the ERC721 token contract.
    /// @param _otherParty The address of the other party in the swap.
    /// @param _id Identifier of the token to be locked.
    constructor(address _token, address _otherParty, uint256 _id) payable {
        owner = msg.sender;
        token = IERC721(_token);
        otherParty = _otherParty;
        id = _id;
    }

    /// @notice Deposits ERC721 token into the contract from the owner's balance.
    /// @dev Requires that the owner has approved the contract to transfer NFT on their behalf.
    /// @dev Only callable by the owner.
    /// @dev You cannot enter a deadline timestamp less than the current time
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the owner can withdraw the tokens if the swap hasn't been completed.
    /// @param _flag Determines who the swap initiator is.
    function deposit(
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external payable override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        require(
            block.timestamp < _deadline,
            "The deadline is earlier than the current time"
        );
        hashKey = _hashKey;
        // The user who initiates the swap sends flag = 1 and his funds will be locked for 24 hours longer,
        // done to protect the swap receiver (see documentation)
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
        token.safeTransferFrom(owner, address(this), id);
    }

    /// @notice Confirms the swap and transfers the ERC721 token to the other party if the provided key matches the hash key.
    /// @dev Requires that the key provided hashes to the stored hash key and transfers the token balance from this contract to the other party.
    /// Only callable by the otherParty.
    /// @param _key The secret key to unlock the swap.
    function confirmSwap(
        string calldata _key
    ) external override onlyOtherParty {
        // Key verification
        require(keccak256(abi.encodePacked(_key)) == hashKey, "Invalid key");
        require(block.timestamp <= deadline, "Deadline has passed");
        // Publishing a key
        key = _key;
        // Transfer ERC721 token to caller (otherParty)
        token.safeTransferFrom(address(this), msg.sender, id);
    }

    /// @notice Allows the owner to withdraw the token if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    /// Only callable by the owner.
    function withdrawal() external override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        token.safeTransferFrom(address(this), owner, id);
    }
}
