const {ethers, upgrades} = require("hardhat");

// eth sepolia
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy the TokenTransferor contract
    const TokenTransferor = await ethers.getContractFactory("TokenTransferor");

    // Replace these addresses with actual values for your network
    const routerAddress = "0xF694E193200268f9a4868e4Aa017A0118C9a8177"; // CCIP router address
    const linkAddress = "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"; // LINK token address
    const adminAddress = deployer.address; // Using deployer as admin, you can change this

    console.log("Deploying TokenTransferor...");
    const tokenTransferor = await upgrades.deployProxy(TokenTransferor, [routerAddress, linkAddress, adminAddress], {initializer: 'initialize'});

    // Wait for the transaction to be mined
    await tokenTransferor.waitForDeployment();

    console.log("TokenTransferor deployed to:", await tokenTransferor.getAddress());

    // Verify the contract on Etherscan
    // Note: You need to set up your Etherscan API key in the Hardhat config for this to work
    console.log("Verifying contract on Etherscan...");
    await hre.run("verify:verify", {
        address: await tokenTransferor.getAddress(),
        constructorArguments: [],
    });

    console.log("Contract verified on Etherscan");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });