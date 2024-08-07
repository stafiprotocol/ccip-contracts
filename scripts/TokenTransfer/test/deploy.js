const { ethers, upgrades } = require("hardhat");

// eth sepolia
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy the TokenTransferor contract
    const TokenTransferor = await ethers.getContractFactory("TokenTransferor");

    // Replace these addresses with actual values for your network
    const routerAddress = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59"; // CCIP router address
    const adminAddress = deployer.address; // Using deployer as admin, you can change this

    console.log("Deploying TokenTransferor...");
    const tokenTransferor = await upgrades.deployProxy(TokenTransferor, [routerAddress, adminAddress], { initializer: 'initialize' });

    // Wait for the transaction to be mined
    await tokenTransferor.waitForDeployment();

    console.log("TokenTransferor deployed to:", await tokenTransferor.getAddress());

    // Verify the contract on Etherscan
    // Note: You need to set up your Etherscan API key in the Hardhat config for this to work
    // Verify the new implementation on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
        if (process.env.ETHERSCAN_API_KEY) {
            console.log("Verifying contract on Etherscan...");
            await hre.run("verify:verify", {
                address: await tokenTransferor.getAddress(),
                constructorArguments: [],
            });
        }
    }

    console.log("Contract verified on Etherscan");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });