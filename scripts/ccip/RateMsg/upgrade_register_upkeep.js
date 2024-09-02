const {ethers, upgrades} = require("hardhat");
const hre = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Upgrading contract with the account:", deployer.address);

    // Get the ContractFactory of the new implementation
    const RegisterUpkeepNew = await ethers.getContractFactory("RegisterUpkeep");

    const PROXY_ADDRESS = process.env.PROXY_ADDRESS;

    if (!PROXY_ADDRESS) {
        throw new Error("Proxy address not provided. Please set the PROXY_ADDRESS environment variable.");
    }

    console.log("Upgrading RegisterUpkeep...");
    const upgradedRegisterUpkeep = await upgrades.upgradeProxy(PROXY_ADDRESS, RegisterUpkeepNew);

    // Wait for the transaction to be mined
    await upgradedRegisterUpkeep.waitForDeployment();

    console.log("RegisterUpkeep upgraded at address:", await upgradedRegisterUpkeep.getAddress());

    // Verify the new implementation on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
        if (process.env.ETHERSCAN_API_KEY) {
            console.log("Verifying new implementation on Etherscan...");
            try {
                const implementationAddress = await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS);
                await hre.run("verify:verify", {
                    address: implementationAddress,
                    constructorArguments: [],
                });
                console.log("New implementation verified on Etherscan");
            } catch (error) {
                console.error("Error verifying contract:", error);
            }
        } else {
            console.log("Skipping Etherscan verification due to missing API key");
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});