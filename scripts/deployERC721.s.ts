import { ethers } from "hardhat";

// npx hardhat run scripts/deployERC721.s.ts --network localhost
async function main() {
  const ERC721 = await ethers.getContractFactory("MockTokenERC721");
  const erc721 = await ERC721.deploy();

  console.log(`MockTokenERC721 deployed to ${await erc721.getAddress()}`);

  const AtomicERC721Swap = await ethers.getContractFactory("AtomicERC721Swap");
  const atomicERC721Swap = await AtomicERC721Swap.deploy(
    erc721.target,
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    0
  );

  console.log(
    `AtomicERC721Swap deployed to ${await atomicERC721Swap.getAddress()}`
  );

  console.log(`AtomicERC721Swap deployed to ${await atomicERC721Swap.owner()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
