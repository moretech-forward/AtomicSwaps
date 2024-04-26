// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IERC721.sol";

abstract contract ERC721TokenReceiver {
    address target;

    constructor(address _target) {
        target = _target;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        IERC721(target).safeMint(address(this));
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Simulating a wallet contract that has the correct interfaces but implements reentrancy
contract HackWallet is ERC721TokenReceiver {
    constructor(address _target) ERC721TokenReceiver(_target) {}
}
