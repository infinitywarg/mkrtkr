import { ethers, network } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";

function formatUnits(balance: BigNumber): any {
	return ethers.utils.formatUnits(balance, 6);
}

async function main() {
	const [deployer, maker1, maker2, taker1, taker2, taker3] = await ethers.getSigners();

	const CASH_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
	const EXCHANGE_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
	const COUPON_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
	const CASH_BALANCE = ethers.utils.parseUnits("99999", 6);
	const MAKER1_VALUE_1 = ethers.utils.parseUnits("3200", 6);
	const MAKER1_VALUE_2 = ethers.utils.parseUnits("9900", 6);
	const MAKER2_VALUE_1 = ethers.utils.parseUnits("4700", 6);
	const MAKER2_VALUE_2 = ethers.utils.parseUnits("1990", 6);
	const ODDS1 = ethers.utils.parseUnits("1.82", 2);
	const GAME1_ID = "1";
	const TAKER1_VALUE_1 = ethers.utils.parseUnits("2900", 6);
	const TAKER2_VALUE_1 = ethers.utils.parseUnits("3900", 6);
	const TAKER3_VALUE_1 = ethers.utils.parseUnits("4900", 6);
	const GAME_START_TIMESTAMP = Math.floor(Date.now() / 1000) + 7200;
	const REDEEM_TIMESTAMP = GAME_START_TIMESTAMP + 21600;

	const cash = await ethers.getContractAt("Cash", CASH_ADDRESS);
	const coupon = await ethers.getContractAt("Coupon", COUPON_ADDRESS);
	const exchange = await ethers.getContractAt("Exchange", EXCHANGE_ADDRESS);
	console.log(`loaded contract instances`);

	let faucetTx, approveTx;

	faucetTx = await cash.connect(maker1).faucet(CASH_BALANCE);
	await faucetTx.wait(1);
	approveTx = await cash.connect(maker1).approve(EXCHANGE_ADDRESS, CASH_BALANCE);
	await approveTx.wait(1);
	expect(await cash.balanceOf(maker1.address)).to.equal(CASH_BALANCE);
	expect(await cash.allowance(maker1.address, EXCHANGE_ADDRESS)).to.equal(CASH_BALANCE);
	console.log(`maker1 received and approved balance`);

	faucetTx = await cash.connect(maker2).faucet(CASH_BALANCE);
	await faucetTx.wait(1);
	approveTx = await cash.connect(maker2).approve(EXCHANGE_ADDRESS, CASH_BALANCE);
	await approveTx.wait(1);
	expect(await cash.balanceOf(maker2.address)).to.equal(CASH_BALANCE);
	expect(await cash.allowance(maker2.address, EXCHANGE_ADDRESS)).to.equal(CASH_BALANCE);
	console.log(`maker2 received and approved balance`);

	faucetTx = await cash.connect(taker1).faucet(CASH_BALANCE);
	await faucetTx.wait(1);
	approveTx = await cash.connect(taker1).approve(EXCHANGE_ADDRESS, CASH_BALANCE);
	await approveTx.wait(1);
	expect(await cash.balanceOf(taker1.address)).to.equal(CASH_BALANCE);
	expect(await cash.allowance(taker1.address, EXCHANGE_ADDRESS)).to.equal(CASH_BALANCE);
	console.log(`taker1 received and approved balance`);

	faucetTx = await cash.connect(taker2).faucet(CASH_BALANCE);
	await faucetTx.wait(1);
	approveTx = await cash.connect(taker2).approve(EXCHANGE_ADDRESS, CASH_BALANCE);
	await approveTx.wait(1);
	expect(await cash.balanceOf(taker2.address)).to.equal(CASH_BALANCE);
	expect(await cash.allowance(taker2.address, EXCHANGE_ADDRESS)).to.equal(CASH_BALANCE);
	console.log(`taker2 received and approved balance`);

	faucetTx = await cash.connect(taker3).faucet(CASH_BALANCE);
	await faucetTx.wait(1);
	approveTx = await cash.connect(taker3).approve(EXCHANGE_ADDRESS, CASH_BALANCE);
	await approveTx.wait(1);
	expect(await cash.balanceOf(taker3.address)).to.equal(CASH_BALANCE);
	expect(await cash.allowance(taker3.address, EXCHANGE_ADDRESS)).to.equal(CASH_BALANCE);
	console.log(`taker3 received and approved balance`);

	const startGameTx = await exchange
		.connect(deployer)
		.startGame(
			ethers.utils.toUtf8Bytes("IIND"),
			ethers.utils.toUtf8Bytes("IAUS"),
			ethers.utils.toUtf8Bytes("ICCWC-22"),
			GAME_START_TIMESTAMP
		);
	await startGameTx.wait(1);
	console.log(await exchange.games(GAME1_ID));

	const poolId = await exchange.poolId(ODDS1, GAME1_ID);
	const tokenIds = await exchange.tokenIds(poolId);
	console.log(`Pool Id: ${poolId} \nMaker Token Id: ${tokenIds.makerId} \nTaker Token Id: ${tokenIds.takerId} \n`);

	let makeTx;

	makeTx = await exchange.connect(maker1).make(ODDS1, GAME1_ID, MAKER1_VALUE_1);
	await makeTx.wait(1);
	expect(formatUnits(await exchange.makerBalance(poolId))).to.equal(formatUnits(MAKER1_VALUE_1.mul(ODDS1).div("100")));
	expect(formatUnits(await coupon.balanceOf(maker1.address, tokenIds.makerId))).to.equal(MAKER1_VALUE_1);
	expect(formatUnits(await cash.balanceOf(exchange.address))).to.equal(MAKER1_VALUE_1.mul(ODDS1));
	console.log(`maker1 made bet for value: ${MAKER1_VALUE_1}`);

	makeTx = await exchange.connect(maker1).make(ODDS1, GAME1_ID, MAKER1_VALUE_2);
	await makeTx.wait(1);
	expect(formatUnits(await exchange.makerBalance(poolId))).to.equal("23842.0");
	expect(await coupon.balanceOf(maker1.address, tokenIds.makerId)).to.equal(MAKER1_VALUE_1.add(MAKER1_VALUE_2));

	console.log(`maker1 made bet for value: ${MAKER1_VALUE_2}`);

	makeTx = await exchange.connect(maker2).make(ODDS1, GAME1_ID, MAKER2_VALUE_1);
	await makeTx.wait(1);
	expect(formatUnits(await exchange.makerBalance(poolId))).to.equal("32396.0");
	expect(await coupon.balanceOf(maker2.address, tokenIds.makerId)).to.equal(MAKER2_VALUE_1);

	console.log(`maker2 made bet for value: ${MAKER2_VALUE_1}`);

	makeTx = await exchange.connect(maker2).make(ODDS1, GAME1_ID, MAKER2_VALUE_2);
	await makeTx.wait(1);
	expect(formatUnits(await exchange.makerBalance(poolId))).to.equal("36017.8");
	expect(await coupon.balanceOf(maker2.address, tokenIds.makerId)).to.equal(MAKER2_VALUE_1.add(MAKER2_VALUE_2));

	console.log(`maker2 made bet for value: ${MAKER2_VALUE_2}`);

	let takeTx;
	takeTx = await exchange.connect(taker1).take(ODDS1, GAME1_ID, TAKER1_VALUE_1);
	await takeTx.wait(1);
	expect(await exchange.takerBalance(poolId)).to.equal(TAKER1_VALUE_1);
	expect(await exchange.matchedValue(poolId)).to.equal(TAKER1_VALUE_1);
	expect(await coupon.balanceOf(taker1.address, tokenIds.takerId)).to.equal(TAKER1_VALUE_1);
	console.log(`taker1 took bet for value: ${TAKER1_VALUE_1}`);

	takeTx = await exchange.connect(taker2).take(ODDS1, GAME1_ID, TAKER2_VALUE_1);
	await takeTx.wait(1);
	expect(await exchange.takerBalance(poolId)).to.equal(TAKER1_VALUE_1.add(TAKER2_VALUE_1));
	expect(await exchange.matchedValue(poolId)).to.equal(TAKER1_VALUE_1.add(TAKER2_VALUE_1));
	expect(await coupon.balanceOf(taker2.address, tokenIds.takerId)).to.equal(TAKER2_VALUE_1);
	console.log(`taker2 took bet for value: ${TAKER2_VALUE_1}`);

	takeTx = await exchange.connect(taker3).take(ODDS1, GAME1_ID, TAKER3_VALUE_1);
	await takeTx.wait(1);
	expect(await exchange.takerBalance(poolId)).to.equal(TAKER1_VALUE_1.add(TAKER2_VALUE_1).add(TAKER3_VALUE_1));
	expect(await exchange.matchedValue(poolId)).to.equal(TAKER1_VALUE_1.add(TAKER2_VALUE_1).add(TAKER3_VALUE_1));
	expect(await coupon.balanceOf(taker3.address, tokenIds.takerId)).to.equal(TAKER3_VALUE_1);
	console.log(`taker3 took bet for value: ${TAKER3_VALUE_1}`);

	await network.provider.send("evm_setNextBlockTimestamp", [REDEEM_TIMESTAMP]);
	console.log(`Increased evm timestamp by 12 hours`);

	// const endGameTx = await exchange.connect(deployer).endGame(GAME1_ID, true);
	// await endGameTx.wait(1);
	// console.log(await exchange.games(GAME1_ID));

	// const previewRedeem = await exchange.previewRedeem(tokenIds.makerId, "1100000000", maker1.address);
	// console.log(previewRedeem);

	// const exchangeBalance = await cash.balanceOf(exchange.address);
	// console.log(exchangeBalance);

	// let reedeemTx;
	// reedeemTx = await exchange.connect(maker1).redeem(tokenIds.makerId, "1100000000");
	// await reedeemTx.wait(1);
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
