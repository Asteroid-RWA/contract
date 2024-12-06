import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "dotenv/config";

const DEPLOYER_KEY = process.env.DEPLOYER_KEY;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

export interface localConfig {
  DEPLOYER_KEY: string;
  BSCSCAN_API_KEY: string;
  POLYGONSCAN_API_KEY: string;
}

const config: HardhatUserConfig = {
  solidity: {
    // version: "0.8.28",
    // settings: {
    //   optimizer: {
    //     enabled: true,
    //     runs: 200,
    //   },
    // },
    compilers: [
      {
        version: "0.4.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    overrides: {
      "contracts/Main-usdt.sol": {
        version: "0.4.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      "contracts/LaunchPadAsteroidV2.sol": {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      "contracts/ERC1155Asteroid.sol": {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
    // apiKey: {
    //   // Is not required by blockscout. Can be any non-empty string
    //   hsk_testnet: "abc",
    // },
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
  networks: {
    // Eth mainnet
    mainnet: {
      chainId: 1,
      url: `https://eth.llamarpc.com`,
      accounts: [],
    },
    // Eth testnet - sepolia
    testnet: {
      chainId: 11155111,
      url: `https://rpc.sepolia.org`,
      accounts: [DEPLOYER_KEY],
    },
    // Bsc mainnet
    bnb_mainnet: {
      chainId: 56,
      url: `https://bsc-dataseed.binance.org`,
      accounts: [],
    },
    // Bsc testnet
    bnb_testnet: {
      chainId: 97,
      url: `https://bsc-testnet.publicnode.com`,
      accounts: [DEPLOYER_KEY],
    },
    // Polygon mainnet
    polygon: {
      chainId: 137,
      url: `https://polygon-rpc.com`,
      accounts: [DEPLOYER_KEY],
    },
    // Polygon mumbai testnet
    mumbai: {
      chainId: 80001,
      url: `https://rpc-mumbai.maticvigil.com/`,
      accounts: [DEPLOYER_KEY],
    },
    hsk_testnet: {
      chainId: 133,
      url: `https://hashkeychain-testnet.alt.technology`,
      accounts: [DEPLOYER_KEY],
    },
  },
  sourcify: {
    enabled: false,
  },
};

export default config;
