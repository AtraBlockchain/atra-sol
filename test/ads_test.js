var ADS = artifacts.require("./ADS.sol");

contract('ADS', function(accounts) {
  // Constructor //
  it("ADS should be owned by who created the contract", function(){
    return ADS.deployed().then(function(instance) {
      return instance.owner.call();
    }).then(function(owner) {
      assert.equal(owner, accounts[0], "Default padding Route does not route to ADS contract");
    });
  });
  it("ADS should create padding route on deployment", function(){
    return ADS.deployed().then(function(instance) {
      return instance.Get.call(0,'');
    }).then(function(route) {
      // console.log(route.valueOf());
      // check name
      assert.equal(route[0], '', "Default padding Route wasn't created");
      // check owner
      assert.equal(route[9], accounts[0], "Default padding Route is not owned by Contract owner");
      // check where it points
      assert.equal(route[1], ADS.address, "Default padding Route does not route to ADS contract");
    });
  });
  it("ADS should create an atra.ads route on deployment", function(){
    return ADS.deployed().then(function(instance) {
      return instance.Get.call(0,'atra.ads');
    }).then(function(route) {
      // check name
      assert.equal(route[0], 'atra.ads', "atra.ads Route wasn't created");
      // check owner
      assert.equal(route[9], accounts[0], "atra.ads Route is not owned by the address that created it");
      // check where it points
      assert.equal(route[1], ADS.address, "atra.ads Route does not route to ADS contract");
    });
  });
  it("ADS should create an atra.ads.pricing route on deployment", function(){
    return ADS.deployed().then(function(instance) {
      return instance.Get.call(0,'atra.ads.pricing');
    }).then(function(route) {
      // check name
      assert.equal(route[0], 'atra.ads.pricing', "atra.ads.pricingRoute wasn't created");
      // check owner
      assert.equal(route[9], accounts[0], "atra.ads.pricing Route is not owned by the address that created it");
      // check where it points
      assert.equal(route[1], ADS.address, "atra.ads.pricing Route does not route to ADS contract");
    });
  });
  it("ADS should have 3 routes after deploy", function(){
    return ADS.deployed().then(function(instance) {
      return instance.RoutesLength.call();
    }).then(function(routesLength) {
      // check length
      assert.equal(routesLength, 3, "ads has the wrong amount of starting routes");

    });
  })

  // Transfer ADS Contract Owner //
  it('ADS contract should transfer to a new address and back to the owner', function(){
    // Try and transfer the ownership of the contract using NOT the ower acccounts

    // Try and transfer the owerhship of the ontract using the owner account

    // Test that the new owner was set correctly

    // Try and accept ownership with the wrong owner account

    // Try and accept ownership with the new route

    // Test if the ownership has transfered correctlly

  });

  // Owner Funds Functions //
  it('ADS contract should only allow owner to Widthdraw funds', function() {
    // get the balance of the contract

    // try and widraw funds using a non owner account
    // test Balance

    // try and withdraw funds form owner
    // check bakance of contract and owner to make sure the funds transferd correctly
  });
  it('ADS contract should only allow owner to view balance of contrat', function(){
    // test balance call with non owner accounts

    // test with owner account
  });

  // Create Routes //
  it('ADS should only store routes with unique names', function(){
    // test by trying to create the same route twice
  })
  it('ADS should not be able to create a blank route', function(){
    // try to create a route with a empty route name
    // try to create an route with all empty inputs
    // try to create a route mixed inputs valid and not
  });
  it('ADS msg.sender owns their routes', function(){
    // create a route and assert that the sender is the owner
  })

  // Update Routes //
  it('ADS should be able to update an owners routes', function(){

    // test with non owner acccounts
      // transaction should fail
    // check route to make sure it's unchanged

    // test with owner account
      // transaction should succeeed
    // check that route was updated correctly

    // test other routes to make sure they were uneffected by the change in storage
  });


  // Transfer Route //


  // Pricing //



});
