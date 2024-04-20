import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { generateRandomHexString } from "./common";

const timeout = 600;
// How much should A fix in the contract
const amountA = 1000;
// How much should B fix in the contract
const amountB = 10000;

// A swaps 1000 native tokens of network A for 10000 native tokens of network B
describe("Cross-Chain Atomic Swap Native Tokens", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    // A and B chose a single exchange time
    const deadline = (await time.latest()) + timeout;

    // A generates a key
    const keyA = generateRandomHexString(64);
    const hashKeyA = hre.ethers.keccak256(hre.ethers.toUtf8Bytes(keyA));

    // A created a contract by fixing the time of execution
    // Also the tokens are locked with key A
    const NativeA = await hre.ethers.getContractFactory("AtomicNativeSwap", {
      signer: partyA,
    });
    const nativeA = await NativeA.deploy(partyB.address, deadline, hashKeyA, {
      value: amountA,
    });

    return { nativeA, partyA, partyB, keyA, hashKeyA, deadline };
  }

  it("Good Swap", async function () {
    const { nativeA, partyA, partyB, keyA, hashKeyA, deadline } =
      await loadFixture(deployA);

    // After A has created a contract, B checks the balance and deploys its
    // where tokens are locked with key A

    // B created a contract by fixing the time of execution

    const NativeB = await hre.ethers.getContractFactory("AtomicNativeSwap", {
      signer: partyB,
    });
    const nativeB = await NativeB.deploy(partyA.address, deadline, hashKeyA, {
      value: amountB,
    });

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key

    await expect(nativeB.connect(partyA).confirmSwap(keyA))
      .to.emit(nativeB, "Swap")
      .withArgs(keyA);

    // B sees the key in the contract events and opens contract A
    await expect(
      nativeA.connect(partyB).confirmSwap(keyA)
    ).to.changeEtherBalance(partyB, amountA);
  });

  it("Successful withdrawal", async function () {
    const { nativeA, partyA, deadline } = await loadFixture(deployA);

    // B has not deployed his contract, after the deadline A can withdraw funds
    await time.increaseTo(deadline);

    await expect(nativeA.connect(partyA).withdrawal()).to.changeEtherBalance(
      partyA,
      amountA
    );
  });

  it("Unsuccessful withdrawal", async function () {
    const { nativeA, partyA, deadline } = await loadFixture(deployA);

    // B has not deployed his contract, after the deadline A can withdraw funds
    //  await time.increaseTo(deadline);

    await expect(nativeA.connect(partyA).withdrawal()).to.be.revertedWith(
      "Swap not yet expired"
    );
  });
});
