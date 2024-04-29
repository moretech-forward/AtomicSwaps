// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IERC1155.sol";
import "./TokenReceivers/ERC1155TokenReceiver.sol";

/// @title AtomicERC1155Swap
/// @notice A contract for a cross-chain atomic swap that stores a token identifier and amount that can be exchanged for any other asset
contract AtomicERC1155Swap is ERC1155TokenReceiver {
    /// @notice One day in timestamp
    /// @dev Used to protect side B
    uint256 constant DAY = 86400;

    /// @notice The owner of the contract who initiates the swap.
    address public immutable owner;

    /// @notice The other party involved in the swap.
    address public immutable otherParty;

    /// @notice The ERC1155 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC1155 type.
    IERC1155 public immutable token;

    /// @notice Number of tokens to be exchanged
    uint256 public immutable value;

    /// @notice Identifier of the token to be swapped.
    /// @dev The contract interacts only with this token identifier.
    uint256 public immutable id;

    /// @notice The cryptographic hash of the secret key required to complete the swap.
    /// @dev The hash is used to ensure that the swap cannot be completed without the correct secret key.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp.
    uint256 public deadline;

    /// @notice Emitted when the swap is confirmed with the correct secret key.
    /// @param key The secret key that was used to confirm the swap.
    event Swap(string indexed key);

    /// @param _token The address of the ERC1155 token contract
    /// @param _otherParty The address of the counterparty
    /// @param _value The value/amount of ERC1155 tokens
    /// @param _id The ID of the ERC1155 token
    constructor(
        address _token,
        address _otherParty,
        uint256 _value,
        uint256 _id
    ) payable {
        owner = msg.sender;
        token = IERC1155(_token);
        otherParty = _otherParty;
        value = _value;
        id = _id;
    }

    /// @notice Deposits ERC1155 token into the contract from the owner's balance.
    /// @dev Requires that the owner has approved the contract to transfer NFT on their behalf.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the swap can be cancelled.
    /// @param _flag Determines who the swap initiator is.
    function deposit(bytes32 _hashKey, uint256 _deadline, bool _flag) external {
        hashKey = _hashKey;
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
        token.safeTransferFrom(owner, address(this), id, value, "0x00");
    }

    /// @notice Confirms the swap and transfers the ERC1155 token to the other party if the provided key matches the hash key.
    /// @dev Requires that the key provided hashes to the stored hash key and transfers tokens (value) from this contract to the other party.
    /// @param _key The secret key to unlock the swap.
    function confirmSwap(string calldata _key) external {
        require(
            hashKey == keccak256(abi.encodePacked(_key)),
            "The key does not match the hash"
        );

        emit Swap(_key);
        token.safeTransferFrom(address(this), otherParty, id, value, "");
    }

    /// @notice Allows the owner to withdraw the token if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    function withdrawal() external {
        require(block.timestamp > deadline, "Swap not yet expired");
        token.safeTransferFrom(address(this), owner, id, value, "");
    }
}
