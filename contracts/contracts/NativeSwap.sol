// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract AtomicNativeSwap {
    address public immutable owner;
    address public immutable otherParty;
    uint public immutable deadline;
    bytes32 public immutable hashKey;

    event Swap(string indexed key);

    constructor(address _otherParty, uint _deadline, bytes32 _hashKey) payable {
        owner = msg.sender;
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
        payable(otherParty).transfer(address(this).balance);
    }

    function withdrawal() external {
        require(block.timestamp >= deadline, "Swap not yet expired");
        payable(owner).transfer(address(this).balance);
    }
}
