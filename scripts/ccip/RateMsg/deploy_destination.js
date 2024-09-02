const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));

async function deployRateReceiver(deployer, routerAddress, allowedSenderAddress) {
  console.log(`Deploying RateReceiver...`);
  const RateReceiver = await hre.ethers.getContractFactory("RateReceiver", deployer);
  const rateReceiver = await RateReceiver.deploy(routerAddress, allowedSenderAddress);
  await rateReceiver.waitForDeployment();
  const deployedAddress = await rateReceiver.getAddress();

  // Verify the contract on Etherscan
  if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
    console.log("Verifying RateReceiver on Etherscan...");
    await hre.run("verify:verify", {
      address: deployedAddress,
      constructorArguments: [routerAddress, allowedSenderAddress],
    });
    console.log("RateReceiver verified on Etherscan");
  }

  return deployedAddress;
}

async function deployCCIPRateProvider(deployer, initialRate, receiverAddress) {
  console.log(`Deploying CCIPRateProvider...`);
  const CCIPRateProvider = await hre.ethers.getContractFactory("CCIPRateProvider", deployer);
  const ccipRateProvider = await CCIPRateProvider.deploy(initialRate, receiverAddress);
  await ccipRateProvider.waitForDeployment();
  const deployedAddress = await ccipRateProvider.getAddress();

  // Verify the contract on Etherscan
  if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
    console.log("Verifying CCIPRateProvider on Etherscan...");
    await hre.run("verify:verify", {
      address: deployedAddress,
      constructorArguments: [initialRate, receiverAddress],
    });
    console.error("CCIPRateProvider verified on Etherscan");
  }

  return deployedAddress;
}

async function main(rateSenderAddress) {
  const deployer = (await hre.ethers.getSigners())[0];

  if (!rateSenderAddress) {
    throw new Error("rateSenderAddress is not provided");
  }

  const rateReceiverAddress = await deployRateReceiver(deployer, config.routerAddressDestination, rateSenderAddress);
  const initialRate = hre.ethers.parseUnits(config.initialRate || "1", 18);
  const ccipRateProviderAddress = await deployCCIPRateProvider(deployer, initialRate, rateReceiverAddress);

  const result = {
    rateReceiverAddress,
    ccipRateProviderAddress
  };

  console.log(JSON.stringify(result));
  return result;
}

if (require.main === module) {
  const rateSenderAddress = process.env.RATE_SENDER_ADDRESS;
  main(rateSenderAddress).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = { main };