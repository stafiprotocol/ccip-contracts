const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
    console.log("Deploying LrdFactory...");

    // Get the ContractFactory and Signer
    const MockLRD = await ethers.getContractFactory("MockLRD");
    const [deployer] = await ethers.getSigners();

    // Deploy the contract
    const mockLrd = await MockLRD.deploy("mckLrd", "mLRD");

    // Wait for the contract to be mined
    await mockLrd.waitForDeployment();

    // Get the deployed contract address
    const mockLrdAddress = await mockLrd.getAddress();

    console.log("MockLrd deployed to:", mockLrdAddress);

    console.log("Deploying StakeManagerFactory...");

    // Get the ContractFactory and Signer
    const MockStakeManager = await ethers.getContractFactory("MockStakeManager");

    // Deploy the contract
    const mockStakeManager = await MockStakeManager.deploy();

    // Wait for the contract to be mined
    await mockStakeManager.waitForDeployment();

    // Get the deployed contract address
    const mockStakeManagerAddress = await mockStakeManager.getAddress();

    console.log("MockStakeManager deployed to:", mockStakeManagerAddress);
    console.log("Deployed by:", deployer.address);

    await mockStakeManager.setLrdToken(mockLrdAddress)
    await mockLrd.initMinter(mockStakeManagerAddress)

    // You might want to verify the contract on Etherscan here
    // Verify the contract on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local" && process.env.ETHERSCAN_API_KEY) {
        console.log("Verifying contract on Etherscan...");
        try {
            await hre.run("verify:verify", {
                address: mockLrdAddress,
                constructorArguments: ["mckLrd", "mLRD"],
            });
            await hre.run("verify:verify", {
                address: mockStakeManagerAddress,
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
