# Docs

## Description

A simple swaps of assets between two EVM networks.

Atomic swaps use a hash timelock contract (HTLC) which acts as a “virtual vault” or “cryptographic escrow account” that keeps user funds safe and only executes when the correct amount of tokens has been deposited to the contract. Each user must acknowledge receipt of tokens within a specified interval to unlock them.

### Hashed Timelock Contract (HTLC)

An HTLC is a time-bound smart contract where a private key and cryptographic hash are used to control access to funds. Each party must meet all of the swap agreements for it to be finalized, otherwise, tokens revert to their original owner.

An HTCL consists of two core security features:

- Hashlock key — Both parties must submit cryptographic proofs verifying that they have met their side of the swap contract.
- Timelock key — If the proofs are not submitted within a preset time limit, the deposited coins are returned to the original owner.

### Swaps

The repository is 4 templates for cross-chain trading:

- `AtomicNativeSwap`
- `AtomicERC20Swap`
- `AtomicERC721Swap`
- `AtomicERC1155Swap`

_Native = ETH, BNB, MATIC etc._

By combining these templates, you can get more than just such pairs to exchange:

- Native - Native
- ERC20 - ERC20
- ERC721 - ERC721
- ERC1155 - ERC1155

But they're also:

|                  |                  |
| ---------------- | ---------------- |
| Native - ERC20   | ERC20 - Native   |
| Native - ERC721  | ERC721 - Native  |
| Native - ERC1155 | ERC1155 - Native |
| ERC20 - ERC721   | ERC721 - ERC20   |
| ERC20 - ERC1155  | ERC1155 - ERC20  |
| ERC721 - ERC1155 | ERC1155 - ERC721 |

All contracts have the same functions, only the input parameters differ.

There are two roles:

- Initiator of the exchange (**Party A**)
- Receiver of the exchange (**Party B**)

The split is determined by the flag that will be passed on deposit + the split makes it so that the initiator's funds are locked for a day longer. This is done for security [more](https://github.com/moretech-forward/AtomicSwaps/blob/main/contracts/audit/Audit.md#manual-audit)

### Example of use

- **Party A** and **Party B** agree that they want to exchange two assets from different networks
  - The asset options are summarized above
  - They determine how long the swap will be possible (`deadline`)
- **Party A** initiates a swap
  - Selects the desired template
  - Deployment
    - `_otherParty` - **Party B**'s address on **Party A**'s network
  - Makes a deposit
- **Party B** checks
  - that **Party A**'s deadline is 24 hours longer than planned.
  - that the assets they agreed to swap belong to the contract
  - If he's **not** satisfied with something, he breaks the swap and **Party A** waits until the deadline to withdraw the funds
- **Party B** is satisfied
  - Selects the desired template
  - Deployment
    - `_otherParty` - **Party A**'s address on **Party B**'s network
  - Makes a deposit
    - Enters the hash of **Рarty A**'s key obtained from the contract
- **Party A** checks
  - that the assets they agreed to swap belong to the contract
  - If he's **not** happy with something, he breaks the swap, and **Рarty A** and **Рarty B** wait for the deadline to withdraw the funds.
- **Party A** is satisfied
  - Enters the key to be published and receives **Party B**'s assets
- **Party B** receives **Party A**'s key.
  - Enters it into **Party A**'s contract
  - Receives **Party A**'s funds

## Contracts

### Additionally

- AtomicSwap

  - `AtomicSwap`
    - Abstract contract to create a universal contract interface for different assets
  - `Owned`
    - Provides access control to contract functions

- interfaces

  - Interfaces for working with tokens

- mocks

  - Directory with tokens for tests
  - `HackWallet` - PoC for the SafeMint Reentrancy vulnerability in SBT-721.

- TokenReceivers

  - The directory with contracts that define the interface for interoperability of the ERC721 and 1155 contract and `safe`-functions

- `Owned`

  - Provides access control to contract functions

### General functions

#### `createSwap`

Transfer of funds to the contract account.

- `_hashKey` The cryptographic hash of the secret key needed to complete the swap.
  - **Party A** enters its key
  - **Party B** looks at **Party A**'s key hash and then enters it at their place.
- `_deadline` The Unix timestamp after which the swap can be cancelled.
  - The two parties must necessarily agree up to what point funds will be blocked in the contracts.
- `_flag` Determines who the swap initiator is.
  - **Party A** transmits `_flag = 1`.
  - **Party B** transmits `_flag = 0`.

_The deposit function parameters could be moved to the contract constructor, but the Forward contract deployment interface does not support customization -> you can't use hashing and date input to get a timestamp_

#### `confirmSwap`

Confirms the swap and sends the assets to the `otherParty` if the provided key matches the hash key. The function requires that the caller provides a key that hashes to the pre-stored hash key. If the condition is met, the contract emits the `Swap` event and transfers all assets to the `otherParty`.

- `_key` The secret key that unlocks the swap.
  - **Party A** is the first to call this function and a Swap event is triggered, which records the key that **Party B** will need to obtain in order to unlock the funds in y` The secret key that unlocks the swap.
  - **Party A**'s contract

#### `withdrawal`

Allows the `owner` to withdraw assets if the swap is not completed by the deadline.
This function checks if the current timestamp is past the deadline, and if so, it allows the owner to withdraw assets.

### `AtomicNativeSwap`

#### `createSwap`

- `_otherParty` The address of the other party in the swap.
- `_amount` How much the user will deposit
- It is necessary to send a `value`.

### `AtomicERC20Swap`

#### `createSwap`

- `_token` The address of the ERC20 token contract.
- `_otherParty` The address of the other party in the swap.
- `_amount` How much the user will deposit

### `AtomicERC721Swap`

#### `createSwap`

- `_token` The address of the ERC721 token contract.
- `_otherParty` The address of the other party in the swap.
- `_id` Identifier of the token to be locked.

### `AtomicERC1155Swap`

#### `createSwap`

- `_token` The address of the ERC1155 token contract
- `_otherParty` The address of the other party in the swap.
- `_value` Value/amount of ERC1155 tokens to be deposited
- `_id` The ID of the ERC1155 token
