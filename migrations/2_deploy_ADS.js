var ADS = artifacts.require("./ADS.sol");
var ADS_Pricing = artifacts.require("./ADS_Pricing.sol");

module.exports = function(deployer) {
  // Deploy the ADS Contract
  deployer.deploy(ADS);

  // TODO: ADS Needs a Pricing Route before it can be used

  // TODO: On deploy of ADS Pricing update atra.ads.pricing route in ADS

  // Deploy the ADS Pricing contract passing the ADS address to the constructor
  deployer.deploy(ADS_Pricing, ADS.address);
};
