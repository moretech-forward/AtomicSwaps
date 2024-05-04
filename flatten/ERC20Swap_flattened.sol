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

// File: contracts/Swaps/interfaces/IERC20.sol

pragma solidity ^0.8.23;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/Swaps/ERC20Swap.sol

pragma solidity ^0.8.23;

/// @title AtomicERC20Swap
/// @notice This contract facilitates atomic swaps of ERC20 tokens using a secret key for completion.
/// @dev The contract leverages the ERC20 `transferFrom` method for deposits, allowing token swaps based on a hash key and a deadline.
contract AtomicERC20Swap is AtomicSwap {
    /// @notice The ERC20 token to be swapped.
    /// @dev The contract holds and transfers tokens of this ERC20 type.
    IERC20 public immutable token;

    /// @notice Amount of tokens for swap
    /// @dev Used when calling the deposit function
    uint256 public immutable amount;

    /// @param _token The address of the ERC20 token contract.
    /// @param _otherParty The address of the other party in the swap.
    /// @param _amount Number of tokens to be deposited into the contract
    constructor(address _token, address _otherParty, uint256 _amount) payable {
        owner = msg.sender;
        token = IERC20(_token);
        otherParty = _otherParty;
        amount = _amount;
    }

    /// @notice Deposits ERC20 tokens into the contract from the owner's balance.
    /// @dev Requires that the owner has approved the contract to transfer the specified `amount` of tokens on their behalf.
    /// Only callable by the owner.
    /// @param _hashKey The cryptographic hash of the secret key needed to complete the swap.
    /// @param _deadline The Unix timestamp after which the owner can withdraw the tokens if the swap hasn't been completed.
    /// @param _flag Determines who the swap initiator is.
    function deposit(
        bytes32 _hashKey,
        uint256 _deadline,
        bool _flag
    ) external payable override onlyOwner {
        hashKey = _hashKey;
        // The user who initiates the swap sends flag = 1 and his funds will be locked for 24 hours longer,
        // done to protect the swap receiver (see documentation)
        if (_flag) deadline = _deadline + DAY;
        else deadline = _deadline;
        require(
            token.transferFrom(owner, address(this), amount),
            "Transfer failed"
        );
    }

    /// @notice Confirms the swap and transfers the ERC20 tokens to the other party if the provided key matches the hash key.
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
        emit SwapConfirmed(_key);
        // Balance transfer of ERC20 token to the caller (otherParty)
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

    /// @notice Allows the owner to withdraw the tokens if the swap is not completed by the deadline.
    /// @dev Checks if the current time is past the deadline and transfers the token balance from this contract to the owner.
    /// Only callable by the owner.
    function withdrawal() external override onlyOwner {
        require(block.timestamp > deadline, "Swap not yet expired");
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }
}
