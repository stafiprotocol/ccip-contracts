const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
    console.log("Deploying XERC20Factory...");

    // Get the ContractFactory and Signer
    // Get the ContractFactory and Signer
    const XERC20Factory = await ethers.getContractFactory("XERC20Factory");
    const [deployer] = await ethers.getSigners();

    // Deploy the contract
    const xerc20Factory = await XERC20Factory.deploy();

    // Wait for the contract to be mined
    await xerc20Factory.waitForDeployment();

    // Get the deployed contract address
    const xerc20FactoryAddress = await xerc20Factory.getAddress();

    console.log("XERC20Factory deployed to:", xerc20FactoryAddress);
    console.log("Deployed by:", deployer.address);

    // You might want to verify the contract on Etherscan here
    // Verify the contract on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local" && process.env.ETHERSCAN_API_KEY) {
        console.log("Verifying contract on Etherscan...");
        try {
            await hre.run("verify:verify", {
                address: xerc20FactoryAddress,
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
