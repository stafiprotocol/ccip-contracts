const { ethers, upgrades } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  // Read configuration from config.json
  const config = JSON.parse(fs.readFileSync(path.join(__dirname, '/config/config_XDeposit.json'), 'utf8'));

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Get the ContractFactory
  const XDeposit = await ethers.getContractFactory("XDeposit");

  // Extract parameters from config
  const {
    LRD: Lrd,
    WETH,
    NEXTWETH: nextWETH,
    CONNEXT: connext,
    RATEPROVIDER: rateProvider,
    DESTINATIONDOMAIN: destinationDomain,
    RECIPIENT: recipient,
    BRIDGEADMIN: bridgeAdmin
  } = config;

  // Validate required parameters
  const requiredParams = [
    { name: 'LRD', value: Lrd },
    { name: 'WETH', value: WETH },
    { name: 'NEXTWETH', value: nextWETH },
    { name: 'CONNEXT', value: connext },
    { name: 'RATEPROVIDER', value: rateProvider },
    { name: 'DESTINATIONDOMAIN', value: destinationDomain },
    { name: 'RECIPIENT', value: recipient },
    { name: 'BRIDGEADMIN', value: bridgeAdmin }
  ];

  for (const param of requiredParams) {
    if (!param.value) {
      throw new Error(`${param.name} not provided in config.json.`);
    }
  }

  const adminAddress = deployer.address;

  // Log deployment parameters
  console.log("Using lrd address:", Lrd);
  console.log("Using weth address:", WETH);
  console.log("Using nextweth address:", nextWETH);
  console.log("Using connext address:", connext);
  console.log("Using rateProvider address:", rateProvider);
  console.log("Using destinationDomain:", destinationDomain);
  console.log("Using recipient address:", recipient);
  console.log("Using bridgeAdmin address:", bridgeAdmin);
  console.log("Using admin address:", adminAddress);

  console.log("Deploying XDeposit...");
  const xDeposit = await upgrades.deployProxy(XDeposit, [
    Lrd, WETH, nextWETH, connext, rateProvider, destinationDomain, recipient, bridgeAdmin, adminAddress
  ], { initializer: 'initialize' });

  // Wait for the transaction to be mined
  await xDeposit.waitForDeployment();
  const deployedAddress = await xDeposit.getAddress();
  console.log("XDeposit deployed to:", deployedAddress);

  // Verify the contract on Etherscan
  if (hre.network.name !== "hardhat" && hre.network.name !== "local" && process.env.ETHERSCAN_API_KEY) {
    console.log("Verifying contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: deployedAddress,
        constructorArguments: [],
      });
      console.log("Contract verified on Etherscan");
    } catch (error) {
      console.error("Error verifying contract:", error);
    }
  } else {
    console.log("Skipping Etherscan verification due to missing API key");
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});