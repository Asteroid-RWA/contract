import { ethers, run, network } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: ", deployer.address);

  const chainId = (await deployer.provider.getNetwork()).chainId;
  console.log("Current Network chainId: ", chainId);

  // Deploy contract
  const name = "AsteroidX Universe";
  const symbol = "AsteroidX";
  const uri = "";
  // const asteroidContract = await ethers.deployContract("ERC1155Asteroid", [
  //   name,
  //   symbol,
  //   uri,
  // ]);
  // await asteroidContract.waitForDeployment();
  // console.log("asteroidContract contract: ", asteroidContract.getAddress);

  const usdtContract =
    Number(chainId) == 1
      ? "0xdAC17F958D2ee523a2206206994597C13D831ec7"
      : "0xbE6cAD380f232d848C788d2d7D65DC9A50d2eCC3";
  console.log("Current udst contract: ", usdtContract);

  const _initialSupply = 100000000000000;
  const _name = "Tether USD";
  const _symbol = "USDT";
  const _decimals = 6;

  // const usdtContract_v2 = await ethers.deployContract("TetherToken", [
  //   _initialSupply,
  //   _name,
  //   _symbol,
  //   _decimals,
  // ]);
  // await usdtContract_v2.waitForDeployment();
  // console.log("asteroidContract contract: ", usdtContract_v2.getAddress);

  // const launchPadContract = await ethers.deployContract("LaunchPadAsteroidV2", [
  //   usdtContract,
  // ]);
  // await launchPadContract.waitForDeployment();

  // const airdropContract = await ethers.deployContract("Airdrop", [
  //   usdtContract,
  // ]);
  // await airdropContract.waitForDeployment();

  if (
    (network.config.chainId === 1 ||
      network.config.chainId === 11155111 ||
      network.config.chainId === 133) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    console.log("verify contract start");
    const usdt_address = "0x19dB00983696B797D82D6E80A2EE5ec5fC2b20B5";
    await verify(usdt_address, [_initialSupply, _name, _symbol, _decimals]);
    //await ethers.provider.waitForBlock(5);
    //const asteroid_address = await asteroidContract.getAddress();
    // const asteroid_address = "0xa667b0dbB6A88982A98B8a6f85Cfb39586BF29c8";
    // await verify(asteroid_address, [name, symbol, uri]);
    // const launch_address = await launchPadContract.getAddress();
    // const launch_address = "0x99025CfFBC293b7109EB40ac2bD9827702E7C32A";
    // await verify(launch_address, [usdtContract]);
    // const airdrop_address = "0x845f05531Da515752465d2D6dd3708dca894b9A1";
    // await verify(airdrop_address, [usdtContract]);
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

async function verify(contractAddress: string, args: any[]) {
  console.log("Verifying contractAddress ING", contractAddress, args);
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    console.log(e);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
