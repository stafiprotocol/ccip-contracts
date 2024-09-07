const { ethers, upgrades } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  // Read configuration from config.json
  const config = JSON.parse(fs.readFileSync(path.join(__dirname, '/config/config_XStake.json'), 'utf8'));

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Get the ContractFactory
  const XStake = await ethers.getContractFactory("XStake");

  // Extract parameters from config
  const {
    WETH,
    LRD,
    XLRD,
    XLRDLOCKBOX,
    STAKE_MANAGER: stakeManager,
    CONNEXT: connext
  } = config;

  const adminAddress = deployer.address;

  // Validate required parameters
  const requiredParams = [
    { name: 'WETH', value: WETH },
    { name: 'LRD', value: LRD },
    { name: 'XLRD', value: XLRD },
    { name: 'XLRDLOCKBOX', value: XLRDLOCKBOX },
    { name: 'STAKE_MANAGER', value: stakeManager },
    { name: 'CONNEXT', value: connext }
  ];

  for (const param of requiredParams) {
    if (!param.value) {
      throw new Error(`${param.name} not provided in config.json.`);
    }
  }

  console.log("Deploying XStake...");
  const xStake = await upgrades.deployProxy(XStake, [
    WETH,
    LRD,
    XLRD,
    XLRDLOCKBOX,
    stakeManager,
    connext,
    adminAddress
  ], { initializer: 'initialize' });

  // Wait for the transaction to be mined
  await xStake.waitForDeployment();
  const deployedAddress = await xStake.getAddress();
  console.log("XStake deployed to:", deployedAddress);

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