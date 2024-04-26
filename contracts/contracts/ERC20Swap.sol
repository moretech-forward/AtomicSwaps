// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IERC20.sol";

/// @title AtomicERC20Swap
/// @notice This contract implements an atomic swap for ERC20 tokens between two parties.
/// @dev The contract uses a cryptographic hash key for a swap, allowing one party to receive tokens if they provide the correct secret key before the deadline.
contract AtomicERC20Swap {
    /// @notice The owner of the contract who initiates the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable owner;

    /// @notice The other party involved in the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable otherParty;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp.
    uint256 public immutable deadline;

    /// @notice The cryptographic hash of the secret key required to complete the swap.
    /// @dev The hash is used to ensure that the swap cannot be completed without the correct secret key.
    bytes32 public immutable hashKey;

    /// @notice The ERC20 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC20 type.
    IERC20 public immutable token;

    /// @notice Emitted when the swap is confirmed with the correct secret key.
    /// @param key The secret key that was used to confirm the swap.
    event Swap(string indexed key);

    /// @param _token The address of the ERC20 token contract.
    /// @param _otherParty The address of the other party in the swap.
    /// @param _deadline The Unix timestamp after which the owner can withdraw the tokens if the swap hasn't been completed.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    constructor(
        address _token,
        address _otherParty,
        uint256 _deadline,
        bytes32 _hashKey
    ) payable {
        owner = msg.sender;
        token = IERC20(_token);
        otherParty = _otherParty;
        deadline = _deadline;
        hashKey = _hashKey;
    }

    /// @notice Confirms the swap and transfers the ERC20 tokens to the other party if the provided key matches the hash key.
    /// @dev Requires that the key provided hashes to the stored hash key and transfers the token balance from this contract to the other party.
    /// @param _key The secret key to unlock the swap.
    function confirmSwap(string calldata _key) external {
        require(
            hashKey == keccak256(abi.encodePacked(_key)),
            "The key does not match the hash"
        );

        emit Swap(_key);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(otherParty, balance), "Transfer failed");
    }

    /// @notice Allows the owner to withdraw the tokens if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    function withdrawal() external {
        require(block.timestamp >= deadline, "Swap not yet expired");
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }
}