var ADS = artifacts.require("./ADS.sol");
var ADS_Pricing = artifacts.require("./ADS_Pricing.sol");

module.exports = function(deployer) {
  const STL = 0; //seconds til live
  const ABI_PATH = 'https://atra.io/public/abi/ads-v2.json';
  deployer.deploy(ADS_Pricing, ADS.address).then(()=>{
    console.log('ADS Pricing deployed!');
    ADS.deployed().then((instance)=>{
      console.log(`ADS Address: ${instance.address}`);
      instance.ScheduleUpdate(0, 'atra.ads.pricing', STL, ADS_Pricing.address, ABI_PATH);
    })
  });


};
