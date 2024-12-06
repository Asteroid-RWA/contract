import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";

const PRIVATE_KEY = process.env.DEPLOYER_KEY;

/**
 * https://docs.blockscout.com/devs/verification/hardhat-verification-plugin
 */

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    hsk_testnet: {
      url: "https://hashkeychain-testnet.alt.technology",
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      // Is not required by blockscout. Can be any non-empty string
      hsk_testnet: "abc",
    },
    customChains: [
      {
        network: "hsk_testnet",
        chainId: 133,
        urls: {
          apiURL: "https://explorer.hsk.xyz/api",
          browserURL: "https://explorer.hsk.xyz/",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
};

export default config;
