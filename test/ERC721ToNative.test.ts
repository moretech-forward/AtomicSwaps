import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { generateRandomHexString } from "./common";

const timeout = 600;
// How much should B fix in the contract
const amountB = 10000;

const flagA = true;
const flagB = false;
const id = 0;

// A swaps 1 ERC721 token of network A for 10000 Native tokens of network B
describe("ERC721 To Native", function () {
  async function deployA() {
    const [partyA, partyB] = await hre.ethers.getSigners();

    const TokenA = await hre.ethers.getContractFactory("MockTokenERC721", {
      signer: partyA,
    });
    const tokenA = await TokenA.deploy();

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

    const erc721A = await ERC721A.deploy(tokenA, partyB, id);

    // A transferred the tokens to the contract
    await tokenA.connect(partyA).approve(erc721A, id);
    await erc721A.deposit(hashKeyA, deadline, flagA);
    expect(await tokenA.balanceOf(erc721A)).to.be.equal(1); // 1 = NFT

    return {
      erc721A,
      partyA,
      partyB,
      tokenA,
      keyA,
      hashKeyA,
      deadline,
    };
  }

  it("Good Swap", async function () {
    const { erc721A, partyA, partyB, keyA, hashKeyA, deadline, tokenA } =
      await loadFixture(deployA);

    // After A has created a contract, B checks the balance and deploys its
    // where tokens are locked with key A

    // B created a contract by fixing the time of execution
    const NativeB = await hre.ethers.getContractFactory("AtomicNativeSwap", {
      signer: partyB,
    });
    const nativeB = await NativeB.deploy(partyA, amountB);
    await nativeB.connect(partyB).deposit(hashKeyA, deadline, flagB, {
      value: amountB,
    });

    // A checks the contract B
    // If A is satisfied, he takes the funds from B's contract and publishes the key
    await expect(
      nativeB.connect(partyA).confirmSwap(keyA)
    ).to.changeEtherBalance(partyA, amountB);

    // B sees the key in the contract events and opens contract A
    await expect(
      erc721A.connect(partyB).confirmSwap(keyA)
    ).to.changeTokenBalance(tokenA, partyB, 1); // 1 = NFT
  });

  it("Successful withdrawal A (ERC721)", async function () {
    const { erc721A, partyA, deadline, tokenA, hashKeyA } = await loadFixture(
      deployA
    );

    // B has not deployed his contract, after the deadline A can withdraw funds
    await time.increaseTo(deadline + 86400);

    await expect(erc721A.connect(partyA).withdrawal()).to.changeTokenBalance(
      tokenA,
      partyA,
      1 // 1 = NFT
    );
  });

  it("Unsuccessful withdrawal A (ERC721)", async function () {
    const { erc721A, partyA } = await loadFixture(deployA);

    // B has not deployed his contract, after the deadline A can withdraw funds
    await expect(erc721A.connect(partyA).withdrawal()).to.be.revertedWith(
      "Swap not yet expired"
    );
  });
});
