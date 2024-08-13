const hre = require("hardhat");

async function main() {
    console.log("Deploying MockToken...");

    // Get the ContractFactory and Signer
    const MockToken = await hre.ethers.getContractFactory("MockToken");

    // Get the initial rate from command line arguments or environment variable
    let initialRate = process.env.INITIAL_RATE;

    // Deploy the contract
    const mockToken = await MockToken.deploy(initialRate);

    // Wait for the contract to be deployed
    await mockToken.waitForDeployment();

    console.log("MockToken deployed to:", await mockToken.getAddress());
    console.log("Initial rate set to:", hre.ethers.formatUnits(initialRate, 18));

    // Verify the contract on Etherscan
    if (hre.network.name !== "hardhat" && hre.network.name !== "local") {
        console.log("Verifying contract on Etherscan...");
        await hre.run("verify:verify", {
            address: await mockToken.getAddress(),
            constructorArguments: [initialRate],
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