import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("NFTWallet test ERC721", function () {
  async function deployFixture() {
    const [owner] = await hre.ethers.getSigners();

    const NFTWallet = await hre.ethers.getContractFactory("NFTWallet");
    const nftwallet = await NFTWallet.deploy();

    const ERC721 = await hre.ethers.getContractFactory("MockTokenERC721");
    const erc721 = await ERC721.deploy();

    const Wallet = await hre.ethers.getContractFactory("Wallet");
    const wallet = await Wallet.deploy();

    return { nftwallet, erc721, wallet, owner };
  }

  it("SafeMint to NFTWallet", async function () {
    const { nftwallet, erc721 } = await loadFixture(deployFixture);

    await expect(erc721.safeMint(nftwallet)).to.emit(erc721, "Transfer");
  });

  it("SafeTransferFrom to NFTWallet", async function () {
    const { erc721, owner, nftwallet } = await loadFixture(deployFixture);

    await expect(
      erc721["safeTransferFrom(address,address,uint256)"](owner, nftwallet, 0)
    ).to.emit(erc721, "Transfer");
    expect(await erc721.balanceOf(nftwallet)).to.be.equal(1);
  });

  it("SafeMint to Wallet", async function () {
    const { wallet, erc721 } = await loadFixture(deployFixture);

    await expect(erc721.safeMint(wallet)).to.be.revertedWithCustomError(
      erc721,
      "ERC721InvalidReceiver"
    );
  });

  it("TransferFrom to Wallet", async function () {
    const { erc721, owner, wallet } = await loadFixture(deployFixture);

    await expect(erc721.transferFrom(owner, wallet, 0)).to.emit(
      erc721,
      "Transfer"
    );
    expect(await erc721.balanceOf(wallet)).to.be.equal(1);
  });

  it("SafeTransferFrom to Wallet", async function () {
    const { erc721, owner, wallet } = await loadFixture(deployFixture);

    await expect(
      erc721["safeTransferFrom(address,address,uint256)"](owner, wallet, 0)
    ).to.be.revertedWithCustomError(erc721, "ERC721InvalidReceiver");
  });
});
