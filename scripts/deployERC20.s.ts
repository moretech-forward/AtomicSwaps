import { ethers } from "hardhat";

// npx hardhat run scripts/deployERC20.s.ts --network localhost
async function main() {
  const ERC20 = await ethers.getContractFactory("MockTokenERC20");
  const erc20 = await ERC20.deploy();

  console.log(`MockTokenERC20 deployed to ${await erc20.getAddress()}`);

  const AtomicNativeSwap = await ethers.getContractFactory("AtomicERC20Swap");
  const atomicNativeSwap = await AtomicNativeSwap.deploy();

  console.log(
    `AtomicERC20Swap deployed to ${await atomicNativeSwap.getAddress()}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
