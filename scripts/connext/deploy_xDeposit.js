const { ethers, upgrades } = require("hardhat");
require('dotenv').config();

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Get the ContractFactory
    const XDeposit = await ethers.getContractFactory("XDeposit");

    const Lrd = process.env.LRD;
    const WETH = process.env.WETH;
    const nextWETH = process.env.NEXTWETH;
    const connext = process.env.CONNEXT;
    const rateProvider = process.env.RATEPROVIDER;
    const destinationDomain = process.env.DESTINATIONDOMAIN;
    const recipient = process.env.RECIPIENT;
    const bridgeAdmin = process.env.BRIDGEADMIN;

    if (!Lrd) {
        throw new Error("lrd address not provided. Please provide it as a command line argument or set the LRD environment variable.");
    }
    if (!WETH) {
        throw new Error("weth address not provided. Please provide it as a command line argument or set the WETH environment variable.");
    }
    if (!nextWETH) {
        throw new Error("nextweth address not provided. Please provide it as a command line argument or set the NEXTWETH environment variable.");
    }
    if (!connext) {
        throw new Error("connext address not provided. Please provide it as a command line argument or set the CONNEXT environment variable.");
    }
    if (!rateProvider) {
        throw new Error("rateProvider address not provided. Please provide it as a command line argument or set the RATEPROVIDER environment variable.");
    }
    if (!destinationDomain) {
        throw new Error("destinationDomain not provided. Please provide it as a command line argument or set the DESTINATIONDOMAIN environment variable.");
    }
    if (!recipient) {
        throw new Error("recipient address not provided. Please provide it as a command line argument or set the RECIPIENT environment variable.");
    }
    if (!bridgeAdmin) {
        throw new Error("bridgeAdmin address not provided. Please provide it as a command line argument or set the BRIDGEADMIN environment variable.");
    }

    const adminAddress = deployer.address;

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
    const xDeposit = await upgrades.deployProxy(XDeposit, [Lrd, WETH, nextWETH, connext, rateProvider, destinationDomain, recipient, bridgeAdmin, adminAddress], { initializer: 'initialize' });

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