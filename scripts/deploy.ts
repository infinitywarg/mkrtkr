import { ethers } from "hardhat";

async function main() {
	console.log(`Deployment started!`);
	const [deployer] = await ethers.getSigners();
	console.log(`Deploying contracts with: ${deployer.address}`);

	console.log(`Deploying Cash contract`);
	const Cash = await ethers.getContractFactory("Cash", deployer);
	const cash = await Cash.deploy();
	await cash.deployed();
	console.log(`Cash contract deployed to ${cash.address}`);

	console.log(`Deploying Exchange contract`);
	const Exchange = await ethers.getContractFactory("Exchange", deployer);
	const exchange = await Exchange.deploy();
	await exchange.deployed();
	console.log(`Exchange contract deployed to ${exchange.address}`);

	console.log(`Deploying Position contract`);
	const Position = await ethers.getContractFactory("Position", deployer);
	const position = await Position.deploy(exchange.address);
	await position.deployed();
	console.log(`Position contract deployed to ${position.address}`);

	console.log(`Initialize Exchange contract`);
	const initializeTx = await exchange.connect(deployer).initialize(position.address, cash.address);
	initializeTx.wait();
	console.log(`Initialize Exchange contract complete`);
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
