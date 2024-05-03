import { ethers } from "hardhat";

// npx hardhat run scripts/deployNative.s.ts --network localhost
async function main() {
  const AtomicNativeSwap = await ethers.getContractFactory("AtomicNativeSwap");
  const atomicNativeSwap = await AtomicNativeSwap.deploy(
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    1000
  );

  console.log(
    `AtomicNativeSwap deployed to ${await atomicNativeSwap.getAddress()}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
