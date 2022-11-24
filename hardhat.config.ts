import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
	solidity: "0.8.17",
	defaultNetwork: "localhost",
	networks: {
		hardhat: {},
		localhost: { url: "http://localhost:8545" }
	}
};

export default config;
