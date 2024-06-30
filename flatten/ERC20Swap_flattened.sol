
// File: contracts/Atomic/interfaces/IERC20.sol


pragma solidity ^0.8.23;

/// @title ERC20 Token Standard Interface
/// @notice Defines the standard functions for ERC20 tokens
/// @dev This interface is used to interact with ERC20 tokens, following the ERC20 standard.
interface IERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256 balance);
}

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

    function deleteGeneralInfo() internal {
        delete deadline;
        delete hashKey;
        delete otherParty;
        delete key;
    }
}

// File: contracts/Atomic/ERC20Swap.sol


pragma solidity ^0.8.23;

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
        deleteInfo();
    }

    /// @notice Allows the owner to withdraw the tokens if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    /// @dev Only callable by the owner.
    function withdrawal() external override onlyOwner isSwap {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
        deleteInfo();
    }

    function deleteInfo() internal {
        deleteGeneralInfo();
        delete token;
        delete amount;
    }
}
