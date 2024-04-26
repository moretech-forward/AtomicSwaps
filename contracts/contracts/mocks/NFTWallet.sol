// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../TokenReceivers/ERC721TokenReceiver.sol";
import "../TokenReceivers/ERC1155TokenReceiver.sol";

contract NFTWallet is ERC721TokenReceiver, ERC1155TokenReceiver {}
