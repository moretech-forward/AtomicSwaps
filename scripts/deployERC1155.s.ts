import { ethers } from "hardhat";

// npx hardhat run scripts/deployERC1155.s.ts --network localhost
async function main() {
  const ERC1155 = await ethers.getContractFactory("MockTokenERC1155");
  const erc1155 = await ERC1155.deploy();

  console.log(`MockTokenERC1155 deployed to ${await erc1155.getAddress()}`);

  const AtomicERC1155Swap = await ethers.getContractFactory(
    "AtomicERC1155Swap"
  );
  const atomicERC1155Swap = await AtomicERC1155Swap.deploy();

  console.log(
    `AtomicERC1155Swap deployed to ${await atomicERC1155Swap.getAddress()}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
