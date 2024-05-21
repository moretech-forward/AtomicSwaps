import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("hardhat-abi-exporter");

const config: HardhatUserConfig = {
  solidity: "0.8.24",
};

export default config;
