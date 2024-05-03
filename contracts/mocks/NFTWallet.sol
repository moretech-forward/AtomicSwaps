// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../TokenReceivers/ERC721TokenReceiver.sol";
import "../TokenReceivers/ERC1155TokenReceiver.sol";

/// @notice Simulating a wallet contract that have the right interfaces
contract NFTWallet is ERC721TokenReceiver, ERC1155TokenReceiver {

}
