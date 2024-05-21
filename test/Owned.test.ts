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

const flagA = true;
const flagB = false;

describe("Owned", function () {
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
    const nativeA = await NativeA.deploy();

    await nativeA.createSwap(partyB, amountA, hashKeyA, deadline, flagA, {
      value: amountA,
    });

    return { nativeA, partyA, partyB, keyA, hashKeyA, deadline };
  }

  it("Only an owner can make a deposit", async function () {
    const { nativeA, partyB, deadline, hashKeyA } = await loadFixture(deployA);

    await expect(
      nativeA
        .connect(partyB)
        .createSwap(partyB, amountA, hashKeyA, deadline, flagA, {
          value: amountA,
        })
    ).to.be.revertedWith("UNAUTHORIZED");
  });

  it("Only an owner can make a withdrawal", async function () {
    const { nativeA, partyB } = await loadFixture(deployA);

    await expect(nativeA.connect(partyB).withdrawal()).to.be.revertedWith(
      "UNAUTHORIZED"
    );
  });

  it("Only an otherParty can call a confirmSwap", async function () {
    const { nativeA, partyA } = await loadFixture(deployA);

    await expect(nativeA.connect(partyA).confirmSwap("")).to.be.revertedWith(
      "UNAUTHORIZED"
    );
  });

  it("Only an owner can call a transferOwnership", async function () {
    const { nativeA, partyB } = await loadFixture(deployA);

    await expect(
      nativeA.connect(partyB).transferOwnership(partyB)
    ).to.be.revertedWith("UNAUTHORIZED");
  });
});
