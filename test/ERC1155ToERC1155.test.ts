import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { generateRandomHexString } from "./common";

const timeout = 600;

const flagA = true;
const flagB = false;
// A swaps 1 ERC1155 token of network A for 1 ERC1155 token of network B
describe("ERC1155 To ERC1155", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    const TokenA = await hre.ethers.getContractFactory("MockTokenERC1155", {
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
    const ERC1155A = await hre.ethers.getContractFactory("AtomicERC1155Swap", {
      signer: partyA,
    });
    const id = 0;
    const value = 1;
    const erc1155A = await ERC1155A.deploy(tokenA, partyB, value, id);

    // A transferred the tokens to the contract
    await tokenA.connect(partyA).setApprovalForAll(erc1155A, true);
    await erc1155A.connect(partyA).deposit(hashKeyA, deadline, flagA);
    expect(await tokenA.balanceOf(erc1155A, id)).to.be.equal(value); // 1 = NFT

    return {
      erc1155A,
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
    const {
      erc1155A,
      partyA,
      partyB,
      keyA,
      hashKeyA,
      deadline,
      tokenB,
      tokenA,
    } = await loadFixture(deployA);

    const id = 0n;
    const value = 1n;

    // After A has created a contract, B checks the balance and deploys its
    // where tokens are locked with key A

    // B created a contract by fixing the time of execution
    const ERC1155B = await hre.ethers.getContractFactory("AtomicERC1155Swap", {
      signer: partyB,
    });
    const erc1155B = await ERC1155B.deploy(tokenB, partyA, value, id);

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).setApprovalForAll(erc1155B, true);
    await erc1155B.connect(partyB).deposit(hashKeyA, deadline, flagB);
    expect(await tokenB.balanceOf(erc1155B, id)).to.be.equal(1); // 1 = NFT

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key
    await erc1155B.connect(partyA).confirmSwap(keyA);

    expect(await tokenB.balanceOf(partyA, id)).to.be.equal(1); // 1 = NFT

    // B sees the key in the contract events and opens contract A
    await erc1155A.connect(partyB).confirmSwap(keyA);
    expect(await tokenA.balanceOf(partyB, id)).to.be.equal(1); // 1 = NFT
  });
});
