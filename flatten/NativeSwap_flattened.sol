
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

    /// @notice One day in timestamp
    /// @dev Used as a time unit for defining deadlines, specifically to protect side B in transactions.
    uint256 constant DAY = 86400;

    /// @notice The keccak256 hash of the secret key required to confirm the swap.
    /// @dev This hash secures the swap by preventing unauthorized access to the funds.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp, this is used to enforce the time limitation on the swap.
    uint256 public deadline;

    /// @notice Emitted when the swap is confirmed successfully with the correct key.
    /// @param key The secret key used to unlock the swap.
    event SwapConfirmed(string indexed key);

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

// File: contracts/Swaps/NativeSwap.sol


pragma solidity ^0.8.23;


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
        emit SwapConfirmed(_key);
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
