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

	console.log(`Deploying Coupon contract`);
	const Coupon = await ethers.getContractFactory("Coupon", deployer);
	const coupon = await Coupon.deploy(exchange.address);
	await coupon.deployed();
	console.log(`Coupon contract deployed to ${coupon.address}`);

	console.log(`Initialize Exchange contract`);
	const initializeTx = await exchange.connect(deployer).initialize(coupon.address, cash.address);
	initializeTx.wait();
	console.log(`Initialize Exchange contract complete`);

	// startGame: ["0x00494e44","0x00415553","0x0049434357433232","1667509980"]

	/**
	 * 
	 * Compiled 1 Solidity file successfully
Deployment started!
Deploying contracts with: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deploying Cash contract
Cash contract deployed to 0x5FbDB2315678afecb367f032d93F642f64180aa3
Deploying Exchange contract
Exchange contract deployed to 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Deploying Coupon contract
Coupon contract deployed to 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
Initialize Exchange contract
Initialize Exchange contract complete
	 */
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
