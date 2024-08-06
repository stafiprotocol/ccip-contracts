const hre = require("hardhat");
require('dotenv').config();

async function main() {
    console.log("Deploying RateReceiver...");

    // Get the ContractFactory and Signer
    const RateReceiver = await hre.ethers.getContractFactory("RateReceiver");

    // Get the router address from command line arguments or environment variable
    let routerAddress = process.argv[2];
    if (!routerAddress) {
        routerAddress = process.env.ROUTER_ADDRESS;
    }

    if (!routerAddress) {
        throw new Error("Router address not provided. Please provide it as a command line argument or set the ROUTER_ADDRESS environment variable.");
    }

    // Get the allowed sender address from command line arguments or environment variable
    let allowedSenderAddress = process.argv[3];
    if (!allowedSenderAddress) {
        allowedSenderAddress = process.env.ALLOWED_SENDER_ADDRESS;
    }

    if (!allowedSenderAddress) {
        throw new Error("Allowed sender address not provided. Please provide it as a command line argument or set the ALLOWED_SENDER_ADDRESS environment variable.");
    }

    console.log("Using router address:", routerAddress);
    console.log("Using allowed sender address:", allowedSenderAddress);

    // Deploy the contract
    const rateReceiver = await RateReceiver.deploy(routerAddress, allowedSenderAddress);

    // Wait for the contract to be deployed
    await rateReceiver.waitForDeployment();

    const deployedAddress = await rateReceiver.getAddress();
    console.log("RateReceiver deployed to:", deployedAddress);

    // Verify the contract on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
        console.log("Verifying contract on Etherscan...");
        await hre.run("verify:verify", {
            address: deployedAddress,
            constructorArguments: [routerAddress, allowedSenderAddress],
        });
        console.log("Contract verified on Etherscan");
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});