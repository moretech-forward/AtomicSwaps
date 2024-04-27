import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("NFTWallet test ERC1155", function () {
  async function deployFixture() {
    const [owner] = await hre.ethers.getSigners();

    const NFTWallet = await hre.ethers.getContractFactory("NFTWallet");
    const nftwallet = await NFTWallet.deploy();

    const ERC1155 = await hre.ethers.getContractFactory("MockTokenERC1155");
    const erc1155 = await ERC1155.deploy();

    const Wallet = await hre.ethers.getContractFactory("Wallet");
    const wallet = await Wallet.deploy();

    return { nftwallet, erc1155, wallet, owner };
  }

  it("Mint to NFTWallet", async function () {
    const { nftwallet, erc1155 } = await loadFixture(deployFixture);

    await expect(erc1155.mint(nftwallet, 0, 1)).to.emit(
      erc1155,
      "TransferSingle"
    );
  });

  it("SafeTransferFrom to NFTWallet", async function () {
    const { erc1155, owner, nftwallet } = await loadFixture(deployFixture);

    await expect(
      erc1155.safeTransferFrom(owner, nftwallet, 0, 1, "0x00")
    ).to.emit(erc1155, "TransferSingle");
    expect(await erc1155.balanceOf(nftwallet, 0)).to.be.equal(1);
  });

  it("Mint to Wallet", async function () {
    const { wallet, erc1155 } = await loadFixture(deployFixture);

    await expect(erc1155.mint(wallet, 0, 1)).to.be.revertedWithCustomError(
      erc1155,
      "ERC1155InvalidReceiver"
    );
  });

  it("SafeTransferFrom to Wallet", async function () {
    const { erc1155, owner, wallet } = await loadFixture(deployFixture);

    await expect(
      erc1155.safeTransferFrom(owner, wallet, 0, 1, "0x00")
    ).to.be.revertedWithCustomError(erc1155, "ERC1155InvalidReceiver");
  });
});
