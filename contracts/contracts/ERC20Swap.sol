// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IERC20.sol";

contract AtomicERC20Swap {
    address public immutable owner;
    address public immutable otherParty;
    uint public immutable deadline;
    bytes32 public immutable hashKey;
    IERC20 public immutable token;

    event Swap(string indexed key);

    constructor(
        address _token,
        address _otherParty,
        uint _deadline,
        bytes32 _hashKey
    ) payable {
        owner = msg.sender;
        token = IERC20(_token);
        otherParty = _otherParty;
        deadline = _deadline;
        hashKey = _hashKey;
    }

    function confirmSwap(string calldata _key) external {
        require(
            hashKey == keccak256(abi.encodePacked(_key)),
            "The key does not match the hash"
        );

        emit Swap(_key);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(otherParty, balance), "Transfer failed");
    }

    function withdrawal() external {
        require(block.timestamp >= deadline, "Swap not yet expired");
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }
}
