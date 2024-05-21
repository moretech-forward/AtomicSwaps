# AtomicSwaps

## Google Docs

- [AtomicSwaps - MoreTech](https://docs.google.com/document/d/14Fha9TKhlnKRjIvWq2qdCTfINw5r2krWyk2Yh0qRyFo/edit?usp=sharing)
- [contract_review_AtomicSwaps_MoreTech](https://docs.google.com/document/d/1BL7N0oFpmZygeZ_kqIFmpzsZ_--fU-k33SZHs0zLmfU/edit)

## Docs

- [Docs](https://github.com/moretech-forward/AtomicSwaps/blob/main/Docs.md)
- [Audit](https://github.com/moretech-forward/AtomicSwaps/blob/main/audit/Audit.md)

## Usage

```sh
git clone git@github.com:moretech-forward/AtomicSwaps-contracts.git
cd AtomicSwaps-contracts
npm install
npx hardhat compile
npx hardhat test
```

## ABIs

```sh
npx hrabi parse abi\contracts\NativeSwap.sol\AtomicNativeSwap.json abi\AtomicNativeSwapABI.json
npx hrabi parse abi\contracts\ERC20Swap.sol\AtomicERC20Swap.json abi\AtomicERC20SwapABI.json
npx hrabi parse abi\contracts\ERC721Swap.sol\AtomicERC721Swap.json abi\AtomicERC721SwapABI.json
npx hrabi parse abi\contracts\ERC1155Swap.sol\AtomicERC1155Swap.json abi\AtomicERC1155SwapABI.json

npx hrabi parse abi\contracts\mocks\ERC20.sol\MockTokenERC20.json abi\ERC20TokenABI.json
npx hrabi parse abi\contracts\mocks\ERC721.sol\MockTokenERC721.json abi\ERC721TokenABI.json
npx hrabi parse abi\contracts\mocks\ERC1155.sol\MockTokenERC1155.json abi\ERC1155TokenABI.json
```
