const { ethers, upgrades } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Get the ContractFactory
    const RateSender = await ethers.getContractFactory("RateSender");

    // Get the router address from command line arguments or environment variable
    let routerAddress = process.argv[2];
    if (!routerAddress) {
        routerAddress = process.env.ROUTER_ADDRESS;
    }

    if (!routerAddress) {
        throw new Error("Router address not provided. Please provide it as a command line argument or set the ROUTER_ADDRESS environment variable.");
    }

    // Get the LINK token address from command line arguments or environment variable
    let linkAddress = process.argv[3];
    if (!linkAddress) {
        linkAddress = process.env.LINK_ADDRESS;
    }

    if (!linkAddress) {
        throw new Error("LINK token address not provided. Please provide it as a command line argument or set the LINK_ADDRESS environment variable.");
    }

    adminAddress = deployer.address;

    console.log("Using router address:", routerAddress);
    console.log("Using LINK token address:", linkAddress);
    console.log("Using admin address:", adminAddress);

    console.log("Deploying RateSender...");
    const rateSender = await upgrades.deployProxy(RateSender, [routerAddress, linkAddress, adminAddress], { initializer: 'initialize' });

    // Wait for the transaction to be mined
    await rateSender.waitForDeployment();

    const deployedAddress = await rateSender.getAddress();
    console.log("RateSender deployed to:", deployedAddress);

    // Verify the contract on Etherscan
    if (process.env.ETHERSCAN_API_KEY) {
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