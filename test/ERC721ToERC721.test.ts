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

const id = 0;
// A swaps 1 ERC721 token of network A for 1 ERC721 token of network B
describe("ERC721 To ERC721", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    const TokenA = await hre.ethers.getContractFactory("MockTokenERC721", {
      signer: partyA,
    });
    const tokenA = await TokenA.deploy();

    const TokenB = await hre.ethers.getContractFactory("MockTokenERC721", {
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
    const ERC721A = await hre.ethers.getContractFactory("AtomicERC721Swap", {
      signer: partyA,
    });

    const erc721A = await ERC721A.deploy();

    // A transferred the tokens to the contract
    await tokenA.connect(partyA).approve(erc721A, id);
    await erc721A.createSwap(tokenA, partyB, id, hashKeyA, deadline, flagA);
    expect(await tokenA.balanceOf(erc721A)).to.be.equal(1); // 1 = NFT

    return {
      erc721A,
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
      erc721A,
      partyA,
      partyB,
      keyA,
      hashKeyA,
      deadline,
      tokenB,
      tokenA,
    } = await loadFixture(deployA);

    // After A has created a contract, B checks the balance and deploys its
    // where tokens are locked with key A

    // B created a contract by fixing the time of execution
    const ERC721B = await hre.ethers.getContractFactory("AtomicERC721Swap", {
      signer: partyB,
    });
    const erc721B = await ERC721B.deploy();

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).approve(erc721B, 0);
    await erc721B
      .connect(partyB)
      .createSwap(tokenB, partyA, id, hashKeyA, deadline, flagB);
    expect(await tokenB.balanceOf(erc721B)).to.be.equal(1); // 1 = NFT

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key

    await expect(
      erc721B.connect(partyA).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenB, partyA, 1); // 1 = NFT

    // B sees the key in the contract events and opens contract A
    await expect(
      erc721A.connect(partyB).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenA, partyB, 1); // 1 = NFT
  });
});
