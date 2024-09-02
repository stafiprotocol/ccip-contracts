const { ethers, upgrades } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy the RegisterUpkeep contract
    const RegisterUpkeep = await ethers.getContractFactory("RegisterUpkeep");

    // Get the LINK token address from command line arguments or environment variable
    let linkAddress = process.argv[3];
    if (!linkAddress) {
        linkAddress = process.env.LINK_ADDRESS;
    }

    if (!linkAddress) {
        throw new Error("LINK token address not provided. Please provide it as a command line argument or set the LINK_ADDRESS environment variable.");
    }

    let registrarAddress = process.argv[2];
    if (!registrarAddress) {
        registrarAddress = process.env.REGISTRAR_ADDRESS;
    }

    if (!registrarAddress) {
        throw new Error("Registrar address not provided. Please provide it as a command line argument or set the REGISTRAR_ADDRESS environment variable.");
    }

    const adminAddress = deployer.address; // Using deployer as admin, you can change this

    console.log("Deploying RegisterUpkeep...");
    const registerUpkeep = await upgrades.deployProxy(RegisterUpkeep, [linkAddress, registrarAddress, adminAddress], { initializer: 'initialize' });

    // Wait for the transaction to be mined
    await registerUpkeep.waitForDeployment();

    console.log("RegisterUpkeep deployed to:", await registerUpkeep.getAddress());

    // Verify the contract on Etherscan
    // Note: You need to set up your Etherscan API key in the Hardhat config for this to work
    // Verify the new implementation on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local" && process.env.ETHERSCAN_API_KEY) {
        // Verify the ContractChecker library on Etherscan
        console.log("Verifying contract on Etherscan...");
        await hre.run("verify:verify", {
            address: await registerUpkeep.getAddress(),
            constructorArguments: [],
        });

        console.log("Contract verified on Etherscan");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });