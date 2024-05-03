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

const id = 0;

const flagA = true;
const flagB = false;

// A swaps 1000 ERC20 tokens of network A for 1 ERC721 token of network B
describe("ERC20 To ERC721", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    const TokenA = await hre.ethers.getContractFactory("MockTokenERC20", {
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
    const ERC20A = await hre.ethers.getContractFactory("AtomicERC20Swap", {
      signer: partyA,
    });
    const erc20A = await ERC20A.deploy(
      tokenA,
      partyB,
      amountA,
    );

    // A transferred the tokens to the contract
    await tokenA.connect(partyA).approve(erc20A, amountA);
    await erc20A.deposit(hashKeyA, deadline, flagA);
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
    const ERC721B = await hre.ethers.getContractFactory("AtomicERC721Swap", {
      signer: partyB,
    });
    const erc721B = await ERC721B.deploy(tokenB, partyA, id);

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).approve(erc721B, id);
    await erc721B.connect(partyB).deposit(hashKeyA, deadline, flagB);
    expect(await tokenB.balanceOf(erc721B)).to.be.equal(1); // 1 = NFT

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key

    await expect(
      erc721B.connect(partyA).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenB, partyA, 1); // 1 = NFT

    // B sees the key in the contract events and opens contract A
    await expect(
      erc20A.connect(partyB).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenA, partyB, amountA);
  });

  it("Successful withdrawal B (ERC721)", async function () {
    const { partyA, partyB, hashKeyA, deadline, tokenB, tokenA } =
      await loadFixture(deployA);

    // B created a contract by fixing the time of execution
    const ERC721B = await hre.ethers.getContractFactory("AtomicERC721Swap", {
      signer: partyB,
    });
    const erc721B = await ERC721B.deploy(tokenB, partyA,  id);

    // B transferred the tokens to the contract
    await tokenB.connect(partyB).approve(erc721B, 0);
    await erc721B.deposit(hashKeyA, deadline,flagB);
    expect(await tokenB.balanceOf(erc721B)).to.be.equal(1); // 1 = NFT

    // B has not deployed his contract, after the deadline A can withdraw funds
    await time.increaseTo(deadline);

    await expect(erc721B.connect(partyB).withdrawal()).to.changeTokenBalance(
      tokenB,
      partyB,
      1
    );
  });
});
