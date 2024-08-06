const hre = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Get the ContractFactory
    const CCIPRateProvider = await hre.ethers.getContractFactory("CCIPRateProvider");

    // Get the initial rate from command line arguments or environment variable
    let initialRate = process.argv[2];
    if (!initialRate) {
        initialRate = process.env.INITIAL_RATE;
    }

    if (!initialRate) {
        throw new Error("Initial rate not provided. Please provide it as a command line argument or set the INITIAL_RATE environment variable.");
    }

    // Convert the initial rate to a BigNumber
    initialRate = hre.ethers.parseUnits(initialRate, 18);

    // Get the receiver address from command line arguments or environment variable
    let receiverAddress = process.argv[3];
    if (!receiverAddress) {
        receiverAddress = process.env.RECEIVER_ADDRESS;
    }

    if (!receiverAddress) {
        throw new Error("Receiver address not provided. Please provide it as a command line argument or set the RECEIVER_ADDRESS environment variable.");
    }

    console.log("Using initial rate:", hre.ethers.formatUnits(initialRate, 18));
    console.log("Using receiver address:", receiverAddress);

    console.log("Deploying CCIPRateProvider...");
    const ccipRateProvider = await CCIPRateProvider.deploy(initialRate, receiverAddress);

    // Wait for the transaction to be mined
    await ccipRateProvider.waitForDeployment();

    const deployedAddress = await ccipRateProvider.getAddress();
    console.log("CCIPRateProvider deployed to:", deployedAddress);

    // Verify the contract on Etherscan
    if (process.env.ETHERSCAN_API_KEY) {
        console.log("Verifying contract on Etherscan...");
        try {
            await hre.run("verify:verify", {
                address: deployedAddress,
                constructorArguments: [initialRate, receiverAddress],
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