const { ethers, upgrades } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Get the ContractFactory
    const XStake = await ethers.getContractFactory("XStake");

    const WETH = process.env.WETH;
    const Lrd = process.env.LRD;
    const xLrd = process.env.XLDR;
    const xLrdLockbox = process.env.XLDRLOCKBOX;
    const stakeManager = process.env.STAKE_MANAGER;
    const connext = process.env.CONNEXT;
    const adminAddress = deployer.address;

    if (!WETH || !xLrd || !Lrd || !xLrdLockbox || !stakeManager || !connext) {
        throw new Error("Missing required environment variables");
    }

    console.log("Deploying XStake...");
    const xStake = await upgrades.deployProxy(XStake, [WETH, Lrd, xLrd, xLrdLockbox, stakeManager, connext, adminAddress], { initializer: 'initialize' });

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