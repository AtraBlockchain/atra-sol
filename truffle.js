var HDWalletProvider = require("truffle-hdwallet-provider");
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    live: {
      host: "https://mainnet.infura.io/4Yqyf0LMVXyKPiucPCjx",
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(
          "run mosquito carry cave wood kidney budget athlete maximum crumble spell exclude",
          "https://ropsten.infura.io/4Yqyf0LMVXyKPiucPCjx")
      },
      network_id: 3
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(
          "run mosquito carry cave wood kidney budget athlete maximum crumble spell exclude",
          "https://rinkeby.infura.io/4Yqyf0LMVXyKPiucPCjx", 2)
      },
      network_id: 4
    }
  }
};
