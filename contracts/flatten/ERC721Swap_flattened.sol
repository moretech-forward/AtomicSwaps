
// File: contracts/Swaps/TokenReceivers/ERC721TokenReceiver.sol


pragma solidity ^0.8.23;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
abstract contract ERC721TokenReceiver {
    /// @notice Handles the receipt of an NFT.
    /// @return Returns the selector to confirm the interface and proper receipt.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// File: contracts/Swaps/interfaces/IERC721.sol


pragma solidity ^0.8.23;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeMint(address to) external;
}

// File: contracts/Swaps/ERC721Swap.sol


pragma solidity ^0.8.23;



/// @title AtomicERC721Swap
/// @notice A contract for a cross-chain atomic swap that stores a token identifier that can be exchanged for any other asset
contract AtomicERC721Swap is ERC721TokenReceiver {
    /// @notice One day in timestamp
    /// @dev Used to protect side B
    uint256 constant DAY = 86400;

    /// @notice The owner of the contract who initiates the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable owner;

    /// @notice The other party involved in the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable otherParty;

    /// @notice The ERC721 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC721 type.
    IERC721 public immutable token;

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
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the owner can withdraw the tokens if the swap hasn't been completed.
    /// @param _flag Determines who the swap initiator is.
    function deposit(bytes32 _hashKey, uint256 _deadline, bool _flag) external {
        hashKey = _hashKey;
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
        token.safeTransferFrom(owner, address(this), id);
    }

    /// @notice Confirms the swap and transfers the ERC721 token to the other party if the provided key matches the hash key.
    /// @dev Requires that the key provided hashes to the stored hash key and transfers the token balance from this contract to the other party.
    /// @param _key The secret key to unlock the swap.
    function confirmSwap(string calldata _key) external {
        require(
            hashKey == keccak256(abi.encodePacked(_key)),
            "The key does not match the hash"
        );

        emit Swap(_key);
        token.safeTransferFrom(address(this), otherParty, id);
    }

    /// @notice Allows the owner to withdraw the token if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    function withdrawal() external {
        require(block.timestamp > deadline, "Swap not yet expired");
        token.safeTransferFrom(address(this), owner, id);
    }
}
