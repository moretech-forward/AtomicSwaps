
// File: contracts/Swaps/AtomicSwap/Owned.sol


pragma solidity >=0.8.0;

/// @notice Provides access control to contract functions
abstract contract Owned {
    /// @notice The owner of the contract who initiates the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable owner;

    /// @notice The other party involved in the swap.
    /// @dev Set at deployment and cannot be changed.
    address public immutable otherParty;

    /// @notice Ensures a function is called by the owner.
    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @notice Ensures a function is called by the otherParty.
    modifier onlyOtherParty() virtual {
        require(msg.sender == otherParty, "UNAUTHORIZED");
        _;
    }
}

// File: contracts/Swaps/AtomicSwap/AtomicSwap.sol


pragma solidity >=0.8.0;


/// @title A contract for atomic swapping of assets with access control.
/// @notice Provides access control and time-bound mechanisms for atomic swap transactions.
/// @dev Inherits from the Owned contract to utilize ownership-based access control.
abstract contract AtomicSwap is Owned {
    /// @notice Auxiliary variable for frontend
    address public immutable myAddr;

    /// @notice The secret key used to unlock the swap.
    string public key;

    /// @notice One day in timestamp
    /// @dev Used as a time unit for defining deadlines, specifically to protect side B in transactions.
    uint256 constant DAY = 86400;

    /// @notice The keccak256 hash of the secret key required to confirm the swap.
    /// @dev This hash secures the swap by preventing unauthorized access to the funds.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp, this is used to enforce the time limitation on the swap.
    uint256 public deadline;

    constructor() {
        myAddr = address(this);
    }

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

// File: contracts/Swaps/TokenReceivers/ERC1155TokenReceiver.sol


pragma solidity ^0.8.23;

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// File: contracts/Swaps/interfaces/IERC1155.sol


pragma solidity ^0.8.23;

interface IERC1155 {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}

// File: contracts/Swaps/ERC1155Swap.sol


pragma solidity ^0.8.23;




/// @title AtomicERC1155Swap
/// @notice A contract for a cross-chain atomic swap that stores a token identifier and amount that can be exchanged for any other asset
contract AtomicERC1155Swap is AtomicSwap, ERC1155TokenReceiver {
    /// @notice The ERC1155 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC1155 type.
    IERC1155 public immutable token;

    /// @notice Number of tokens to be exchanged
    uint256 public immutable value;

    /// @notice Identifier of the token to be swapped.
    /// @dev The contract interacts only with this token identifier.
    uint256 public immutable id;

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
    /// Only callable by the owner.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the swap can be cancelled.
    /// @param _flag Determines who the swap initiator is.
    function deposit(
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external payable override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        hashKey = _hashKey;
        // The user who initiates the swap sends flag = 1 and his funds will be locked for 24 hours longer,
        // done to protect the swap receiver (see documentation)
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
        token.safeTransferFrom(owner, address(this), id, value, "0x00");
    }

    /// @notice Confirms the swap and transfers the ERC1155 token to the other party if the provided key matches the hash key.
    /// @dev Requires that the key provided hashes to the stored hash key and transfers tokens (value) from this contract to the other party.
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
        // Transfer ERC1155 token to caller (otherParty)
        token.safeTransferFrom(address(this), msg.sender, id, value, "");
    }

    /// @notice Allows the owner to withdraw the token if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    /// Only callable by the owner.
    function withdrawal() external override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        token.safeTransferFrom(address(this), owner, id, value, "");
    }
}
