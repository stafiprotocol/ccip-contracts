const { ethers, upgrades } = require("hardhat");

// eth sepolia
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy the RegisterUpkeep contract
    const RegisterUpkeep = await ethers.getContractFactory("RegisterUpkeep");

    // Replace these addresses with actual values for your network
    const linkAddress = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59"; // LINK token address
    const registrarAddress = "0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976"; // Replace with actual AutomationRegistrar address
    const adminAddress = deployer.address; // Using deployer as admin, you can change this

    console.log("Deploying RegisterUpkeep...");
    const registerUpkeep = await upgrades.deployProxy(RegisterUpkeep, [linkAddress, registrarAddress, adminAddress], { initializer: 'initialize' });

    // Wait for the transaction to be mined
    await registerUpkeep.waitForDeployment();

    console.log("RegisterUpkeep deployed to:", await registerUpkeep.getAddress());

    // Verify the contract on Etherscan
    // Note: You need to set up your Etherscan API key in the Hardhat config for this to work
    // Verify the new implementation on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
        if (process.env.ETHERSCAN_API_KEY) {
            // Verify the ContractChecker library on Etherscan
            console.log("Verifying contract on Etherscan...");
            await hre.run("verify:verify", {
                address: await registerUpkeep.getAddress(),
                constructorArguments: [],
            });

            console.log("Contract verified on Etherscan");
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });