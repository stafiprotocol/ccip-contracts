const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

// Load configuration
let config;
try {
  config = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));
  console.log("Config loaded:", config);
} catch (error) {
  console.error("Error loading config:", error);
  process.exit(1);
}

async function deployMockToken(deployer, name, initialRate) {
  console.log(`Deploying MockToken for ${name}...`);
  const MockToken = await hre.ethers.getContractFactory("MockToken", deployer);
  const mockToken = await MockToken.deploy(hre.ethers.parseUnits(initialRate, 18));
  await mockToken.waitForDeployment();
  const deployedAddress = await mockToken.getAddress();

  // Verify the contract on Etherscan
  if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
    console.log(`Verifying MockToken for ${name} on Etherscan...`);
    await hre.run("verify:verify", {
      address: deployedAddress,
      constructorArguments: [hre.ethers.parseUnits(initialRate, 18)],
    });
    console.log(`MockToken for ${name} verified on Etherscan`);
  }

  return deployedAddress;
}

async function deployRateSender(deployer, routerAddress, linkAddress) {
  console.log("Deploying RateSender...");
  console.log(`Router address: ${routerAddress}`);
  console.log(`Link address: ${linkAddress}`);

  if (!routerAddress || !hre.ethers.isAddress(routerAddress)) {
    throw new Error(`Invalid router address: ${routerAddress}`);
  }
  if (!linkAddress || !hre.ethers.isAddress(linkAddress)) {
    throw new Error(`Invalid link address: ${linkAddress}`);
  }

  const RateSender = await hre.ethers.getContractFactory("RateSender", deployer);
  const adminAddress = deployer.address;

  console.log("Deploying RateSender contract...");
  const rateSender = await hre.upgrades.deployProxy(RateSender, [routerAddress, linkAddress, adminAddress], { initializer: 'initialize' });

  console.log("Waiting for RateSender deployment...");
  await rateSender.waitForDeployment();

  const deployedAddress = await rateSender.getAddress();

  // Verify the contract on Etherscan
  if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
    console.log(`Verifying RateSender for on Etherscan...`);
    await hre.run("verify:verify", {
      address: deployedAddress,
      constructorArguments: [],
    });
    console.log(`MockToken verified on Etherscan`);
  }

  return deployedAddress;
}

async function main() {
  console.log("Starting main deployment process");
  const deployer = (await hre.ethers.getSigners())[0];
  console.log(`Deployer address: ${deployer.address}`);

  const deployedTokens = [];
  for (const token of config.tokens) {
    console.log(`Processing token: ${token.name}`);
    let address;
    if (!token.address) {
      address = await deployMockToken(deployer, token.name, token.initialRate);
    } else {
      address = token.address;
    }
    deployedTokens.push(address);
    console.log(`Token ${token.name} address: ${address}`);
  }

  console.log("Deploying RateSender...");
  let rateSenderAddress;
  try {
    rateSenderAddress = await deployRateSender(deployer, config.routerAddressSource, config.linkAddressSource);
    console.log(`RateSender deployed at ${rateSenderAddress}`);
  } catch (error) {
    console.error("Error deploying RateSender:", error);
    process.exit(1);
  }

  const result = {
    rateSenderAddress,
    deployedTokens
  };

  // Output only the necessary JSON to stdout for shell script parsing
  console.log(JSON.stringify(result));

  return result;
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = { main };