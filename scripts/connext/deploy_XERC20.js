const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

const config = JSON.parse(fs.readFileSync(path.join(__dirname, '/config/config_XERC20.json'), 'utf8'));

async function deployXERC20(deployer, xerc20FactoryAddress, name, symbol, minterLimits, burnerLimits, bridges) {
  console.log("Deploying XERC20...");
  const XERC20Factory = await hre.ethers.getContractFactory("XERC20Factory");
  const xerc20Factory = XERC20Factory.attach(xerc20FactoryAddress);

  console.log("Deployment parameters:", { name, symbol, minterLimits, burnerLimits, bridges });

  const deployXERC20Tx = await xerc20Factory.connect(deployer).deployXERC20(
    name,
    symbol,
    minterLimits,
    burnerLimits,
    bridges
  );

  console.log("XERC20 deployment transaction hash:", deployXERC20Tx.hash);

  const receipt = await deployXERC20Tx.wait();
  const xerc20DeployedEvent = receipt.logs.find(log => log.eventName === "XERC20Deployed");

  if (!xerc20DeployedEvent || !xerc20DeployedEvent.args) {
    throw new Error("Failed to find XERC20Deployed event in transaction receipt");
  }

  return xerc20DeployedEvent.args[0];
}

async function deployLockbox(deployer, xerc20FactoryAddress, xerc20Address, baseToken, isNative) {
  console.log("Deploying Lockbox...");
  const XERC20Factory = await hre.ethers.getContractFactory("XERC20Factory");
  const xerc20Factory = XERC20Factory.attach(xerc20FactoryAddress);

  const deployLockboxTx = await xerc20Factory.connect(deployer).deployLockbox(xerc20Address, baseToken, isNative);
  const deployLockboxReceipt = await deployLockboxTx.wait();
  const lockboxDeployedEvent = deployLockboxReceipt.logs.find(log => log.eventName === "LockboxDeployed");

  if (!lockboxDeployedEvent || !lockboxDeployedEvent.args) {
    throw new Error("Failed to find LockboxDeployed event in transaction receipt");
  }

  return lockboxDeployedEvent.args[0];
}

function convertToWei(value) {
  // Convert scientific notation to a regular number string
  const regularNumber = Number(value).toLocaleString('fullwide', {useGrouping:false});
  // Parse the number string and convert to wei (assuming 18 decimals)
  return hre.ethers.parseUnits(regularNumber, 18);
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deployer address:", await deployer.getAddress());

  if (!config.xerc20FactoryAddress || !config.name || !config.symbol) {
    throw new Error("Missing required configuration in config.json");
  }

  console.log("Configuration:", JSON.stringify(config, null, 2));

  const minterLimits = (config.minterLimits || []).map(convertToWei);
  const burnerLimits = (config.burnerLimits || []).map(convertToWei);

  console.log("Converted minterLimits:", minterLimits.map(l => l.toString()));
  console.log("Converted burnerLimits:", burnerLimits.map(l => l.toString()));

  const xerc20Address = await deployXERC20(
    deployer,
    config.xerc20FactoryAddress,
    config.name,
    config.symbol,
    minterLimits,
    burnerLimits,
    config.bridges || []
  );

  console.log("XERC20 deployed to:", xerc20Address);

  let lockboxAddress;
  if (config.baseToken) {
    lockboxAddress = await deployLockbox(
      deployer,
      config.xerc20FactoryAddress,
      xerc20Address,
      config.baseToken,
      config.isNative || false
    );
    console.log("Lockbox deployed to:", lockboxAddress);
  } else {
    console.log("Skipping Lockbox deployment as baseToken is not provided in config.json");
  }

  const result = {
    xerc20Address,
    lockboxAddress
  };

  console.log("Deployment result:", JSON.stringify(result, null, 2));
  return result;
}

if (require.main === module) {
  main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exitCode = 1;
  });
}

module.exports = { main };