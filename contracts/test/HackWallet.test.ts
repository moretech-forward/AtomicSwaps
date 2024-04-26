import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

// PoC reentrancy
describe("HackWallet test ERC721", function () {
  async function deployFixture() {
    const [owner] = await hre.ethers.getSigners();

    const ERC721 = await hre.ethers.getContractFactory("MockTokenERC721");
    const erc721 = await ERC721.deploy();

    const HackWallet = await hre.ethers.getContractFactory("HackWallet");
    const hackWallet = await HackWallet.deploy(erc721);

    return { hackWallet, erc721, owner };
  }

  it("SafeMint to HackWallet", async function () {
    const { hackWallet, erc721 } = await loadFixture(deployFixture);

    await expect(erc721.safeMint(hackWallet)).to.be.revertedWithCustomError(
      erc721,
      "OwnableUnauthorizedAccount"
    );
  });
});
