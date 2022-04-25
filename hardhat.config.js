require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
const dotenv = require("dotenv")

dotenv.config();

module.exports = {
  solidity: "0.8.9",
  networks: {
    rinkeby: {
      url: process.env.RPC_URL,
      accounts: [process.env.RINKEBY_PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
