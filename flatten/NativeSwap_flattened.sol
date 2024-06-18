// File: contracts/Atomic/AtomicSwap/Owned.sol

pragma solidity >=0.8.0;

/// @title Owned Contract
/// @notice Provides access control to contract functions
/// @dev This contract allows for ownership management and ensures only the owner or a designated other party can call certain functions.
abstract contract Owned {
    /// @notice The owner of the contract who initiates the swap.
    /// @dev The owner has exclusive access to functions marked with the `onlyOwner` modifier.
    address public owner;

    /// @notice The other party involved in the swap.
    /// @dev The other party has exclusive access to functions marked with the `onlyOtherParty` modifier.
    address public otherParty;

    /// @notice Ensures a function is called by the owner.
    /// @dev Reverts the transaction if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @notice Ensures a function is called by the otherParty.
    /// @dev Reverts the transaction if called by any account other than the otherParty.
    modifier onlyOtherParty() {
        require(msg.sender == otherParty, "UNAUTHORIZED");
        _;
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @dev Can only be called by the current owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

// File: contracts/Atomic/AtomicSwap/AtomicSwap.sol

pragma solidity >=0.8.0;

/// @title A contract for atomic swapping of assets with access control.
/// @notice Provides mechanisms for atomic swap transactions with time-bound constraints and access control.
/// @dev Inherits from the Owned contract to leverage ownership-based access control.
abstract contract AtomicSwap is Owned {
    /// @notice The address of this contract instance.
    /// @dev Used as an auxiliary variable for frontend interaction.
    address public immutable myAddr;

    /// @notice The secret key used to unlock the swap.
    /// @dev This variable should be securely managed and not exposed publicly.
    string public key;

    /// @notice One day in seconds.
    /// @dev Used as a time unit to define deadlines, particularly to protect side B in transactions.
    uint256 constant DAY = 86400;

    /// @notice The keccak256 hash of the secret key required to confirm the swap.
    /// @dev Ensures the security of the swap by preventing unauthorized access to the funds.
    bytes32 public hashKey;

    /// @notice Deadline after which the swap cannot be accepted.
    /// @dev Represented as a Unix timestamp, used to enforce the time limitation on the swap.
    uint256 public deadline;

    /// @notice Modifier to check if the swap deadline has passed.
    /// @dev Reverts the transaction if the current block timestamp is less than the deadline.
    modifier isSwap() {
        require(block.timestamp > deadline, "Swap not yet expired");
        _;
    }

    /// @notice Initializes the contract setting the deployer as the owner and the contract address.
    /// @dev Sets the owner to the deployer and myAddr to the contract's address.
    constructor() payable {
        owner = msg.sender;
        myAddr = address(this);
    }

    /// @notice Confirms the swap using a secret key, releasing the funds to the other party.
    /// @dev This function can only be called by a designated party other than the owner.
    /// @param _key The secret key that, if correct, will unlock and transfer the assets.
    function confirmSwap(
        string calldata _key
    ) external virtual onlyOtherParty {}

    /// @notice Allows the owner to withdraw assets from the contract.
    /// @dev This function can only be called by the owner, typically used when the swap did not occur before the deadline.
    function withdrawal() external virtual onlyOwner {}

    /// @notice Fallback function to accept incoming ether.
    /// @dev Allows the contract to receive ether.
    receive() external payable {}
}

// File: contracts/Atomic/NativeSwap.sol

pragma solidity ^0.8.23;

/// @title AtomicNativeSwap
/// @notice This contract implements an atomic swap using native Ether transactions.
/// It allows two parties to participate in a trustless exchange of Ether based on the fulfillment of a cryptographic condition.
/// @dev The contract uses a hashlock mechanism for the swap to ensure that only the participant with the correct secret can claim the Ether.
contract AtomicNativeSwap is AtomicSwap {
    /// @notice Amount of Ether to be swapped.
    /// @dev The contract holds this amount of Ether for the duration of the swap.
    uint256 public amount;

    constructor(uint) payable {}

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
        delete key;
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
