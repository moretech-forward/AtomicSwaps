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

// A swaps 1000 ERC20 tokens of network A for 1 ERC1155 token of network B
describe("ERC20 To ERC1155", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    const TokenA = await hre.ethers.getContractFactory("MockTokenERC20", {
      signer: partyA,
    });
    const tokenA = await TokenA.deploy();

    const TokenB = await hre.ethers.getContractFactory("MockTokenERC1155", {
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
    const erc20A = await ERC20A.deploy(
      tokenA,
      partyB,
      deadline,
      hashKeyA,
      amountA
    );

    // A transferred the tokens to the contract
    await tokenA.connect(partyA).approve(erc20A, amountA);
    await erc20A.deposit();
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

    const id = 0n;
    const value = 1n;

    // After A has created a contract, B checks the balance and deploys its
    // where tokens are locked with key A

    // B created a contract by fixing the time of execution
    const ERC1155B = await hre.ethers.getContractFactory("AtomicERC1155Swap", {
      signer: partyB,
    });
    const erc1155B = await ERC1155B.deploy(
      tokenB,
      partyA,
      deadline,
      hashKeyA,
      value,
      id
    );

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).setApprovalForAll(erc1155B, true);
    await erc1155B.connect(partyB).deposit();
    expect(await tokenB.balanceOf(erc1155B, id)).to.be.equal(1); // 1 = NFT

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key

    await erc1155B.connect(partyA).confirmSwap(keyA);
    expect(await tokenB.balanceOf(partyA, id)).to.be.equal(1); // 1 = NFT

    // B sees the key in the contract events and opens contract A
    await expect(
      erc20A.connect(partyB).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenA, partyB, amountA);
  });

  it("Successful withdrawal B (ERC1155)", async function () {
    const { partyA, partyB, keyA, hashKeyA, deadline, tokenB, tokenA } =
      await loadFixture(deployA);
    const id = 0;
    const value = 1;

    // B created a contract by fixing the time of execution
    const ERC1155B = await hre.ethers.getContractFactory("AtomicERC1155Swap", {
      signer: partyB,
    });
    const erc1155B = await ERC1155B.deploy(
      tokenB,
      partyA,
      deadline,
      hashKeyA,
      value,
      id
    );

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).setApprovalForAll(erc1155B, true);
    await erc1155B.deposit();
    expect(await tokenB.balanceOf(erc1155B, id)).to.be.equal(1); // 1 = NFT

    // B has not deployed his contract, after the deadline A can withdraw funds
    await time.increaseTo(deadline);

    await erc1155B.connect(partyB).withdrawal();
    expect(await tokenB.balanceOf(partyB, id)).to.be.equal(1); // 1 = NFT
    expect(await tokenB.balanceOf(erc1155B, id)).to.be.equal(0); // 1 = NFT
  });
});
