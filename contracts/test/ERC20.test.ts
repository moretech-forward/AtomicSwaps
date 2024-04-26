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

// A swaps 1000 ERC20 tokens of network A for 10000 ERC20 tokens of network B
describe("Cross-Chain Atomic Swap ERC20 Tokens", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    const TokenA = await hre.ethers.getContractFactory("MockTokenERC20", {
      signer: partyA,
    });
    const tokenA = await TokenA.deploy();

    const TokenB = await hre.ethers.getContractFactory("MockTokenERC20", {
      signer: partyB,
    });
    const tokenB = await TokenB.deploy();

    // A and B chose a single exchange time
    const deadline = (await time.latest()) + timeout;

    // A generates a key
    const keyA = generateRandomHexString(64);
    const hashKeyA = hre.ethers.keccak256(hre.ethers.toUtf8Bytes(keyA));

    // A created a contract by fixing the time of execution
    // Also the tokens are locked with key A
    const ERC20A = await hre.ethers.getContractFactory("AtomicERC20Swap", {
      signer: partyA,
    });
    const erc20A = await ERC20A.deploy(tokenA, partyB, deadline, hashKeyA);

    // A transferred the tokens to the contract
    await tokenA.connect(partyA).transfer(erc20A, amountA);
    expect(await tokenA.balanceOf(erc20A)).to.be.equal(amountA);

    return {
      erc20A,
      partyA,
      partyB,
      tokenA,
      tokenB,
      keyA,
      hashKeyA,
      deadline,
    };
  }

  it("Good Swap", async function () {
    const { erc20A, partyA, partyB, keyA, hashKeyA, deadline, tokenB, tokenA } =
      await loadFixture(deployA);

    // After A has created a contract, B checks the balance and deploys its
    // where tokens are locked with key A

    // B created a contract by fixing the time of execution
    const ERC20B = await hre.ethers.getContractFactory("AtomicERC20Swap", {
      signer: partyB,
    });
    const erc20B = await ERC20B.deploy(tokenB, partyA, deadline, hashKeyA);

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).transfer(erc20B, amountB);
    expect(await tokenB.balanceOf(erc20B)).to.be.equal(amountB);

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key

    await expect(
      erc20B.connect(partyA).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenB, partyA, amountB);

    // B sees the key in the contract events and opens contract A
    await expect(
      erc20A.connect(partyB).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenA, partyB, amountA);
  });

  it("Successful withdrawal", async function () {
    const { erc20A, partyA, deadline, tokenA } = await loadFixture(deployA);

    // B has not deployed his contract, after the deadline A can withdraw funds
    await time.increaseTo(deadline);

    await expect(erc20A.connect(partyA).withdrawal()).to.changeTokenBalance(
      tokenA,
      partyA,
      amountA
    );
  });

  it("Unsuccessful withdrawal", async function () {
    const { erc20A, partyA } = await loadFixture(deployA);

    // B has not deployed his contract, after the deadline A can withdraw funds
    //  await time.increaseTo(deadline);

    await expect(erc20A.connect(partyA).withdrawal()).to.be.revertedWith(
      "Swap not yet expired"
    );
  });
});
