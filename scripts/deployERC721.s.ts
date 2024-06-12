import { ethers } from "hardhat";

// npx hardhat run scripts/deployERC721.s.ts --network localhost
async function main() {
  const ERC721 = await ethers.getContractFactory("MockTokenERC721");
  const erc721 = await ERC721.deploy();

  console.log(`MockTokenERC721 deployed to ${await erc721.getAddress()}`);

  const AtomicERC721Swap = await ethers.getContractFactory("AtomicERC721Swap");
  const atomicERC721Swap = await AtomicERC721Swap.deploy();

  console.log(
    `AtomicERC721Swap deployed to ${await atomicERC721Swap.getAddress()}`
  );

  await erc721.safeMint("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
