import { ethers, run, network } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: ", deployer.address);

  const chainId = (await deployer.provider.getNetwork()).chainId;
  console.log("Current Network chainId: ", chainId);
  
  // Deploy contract
  const name = "Asteroid Universe";
  const symbol = "Asteroid";
  const uri = "";
  console.log("asteroidContract contract: ", 111111111);
  const usdtContract = Number(chainId) == 56 ? "0x55d398326f99059fF775485246999027B3197955" : "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";
  console.log("Current udst contract: ", usdtContract);
  
  // step 1
  // const asteroidContract = await ethers.deployContract("ERC1155Asteroid", [name, symbol, uri]);
  // await asteroidContract.waitForDeployment();

  // step 2
  // const launchPadContract = await ethers.deployContract("LaunchPadAsteroid", [usdtContract]);
  // await launchPadContract.waitForDeployment();

  // step 3
  if ((network.config.chainId === 56 || network.config.chainId === 137) && process.env.BSCSCAN_API_KEY || process.env.POLYGONSCAN_API_KEY) {
    console.log("verify contract start");
    //await ethers.provider.waitForBlock(5);
    //const asteroid_address = await asteroidContract.getAddress();
    const asteroid_address = "0xc26328c8b52b48fda9898e0e023ed6f934422a1d";
    await verify(asteroid_address, [name, symbol, uri]);
    //const launch_address = await launchPadContract.getAddress();
    const launch_address = "0x65f893756e7b797a77e7efc6401d52eceb65578d";
    await verify(launch_address, [usdtContract]);
  }

  // await launchPadContract.setERC1155AsteroidContract(asteroidContract.target);
  // await asteroidContract.grantRole("0x9e37095ee9b77171bf9351b5bf50a9f4803be693d3445664940ad3109c59b80c", launchPadContract.target);

//   const currentTimestampInSeconds = Math.round(Date.now() / 1000);
//   const unlockTime = currentTimestampInSeconds + 60;

//   const lockedAmount = ethers.parseEther("0.001");

//   const referralContract = await ethers.getContractFactory("Lock");
//   const referral = await referralContract.deploy(unlockTime);
//   const result = await referral.waitForDeployment();
//   console.log("111111111111111111111", result.target);
//   // const lock = await ethers.deployContract("Lock", [unlockTime]);
//   // await lock.waitForDeployment();

//   console.log(
//     `Lock with ${ethers.formatEther(
//       lockedAmount
//     )}ETH and unlock timestamp ${unlockTime} deployed to ${referral.target}`
//   );
}

async function verify(contractAddress: string, args: string[]) {
  console.log("Verifying contractAddress ING", contractAddress, args)
  try {
      await run("verify:verify", {
          address: contractAddress,
          constructorArguments: args,
      })
  } catch (e) {
    console.log(e)
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
