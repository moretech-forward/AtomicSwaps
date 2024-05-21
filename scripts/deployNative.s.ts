import { ethers } from "hardhat";

// npx hardhat run scripts/deployNative.s.ts --network localhost
async function main() {
  const AtomicNativeSwap = await ethers.getContractFactory("AtomicNativeSwap");
  const atomicNativeSwap = await AtomicNativeSwap.deploy();

  console.log(
    `AtomicNativeSwap deployed to ${await atomicNativeSwap.getAddress()}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
