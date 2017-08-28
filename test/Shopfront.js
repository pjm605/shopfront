var Shopfront = artifacts.require("./Shopfront.sol");

contract('Shopfront', function(accounts) {
  var contract;
  var owner = accounts[0];

  beforeEach(function () {
    return Shopfront.new({ from: owner })
    .then((instance) => {
      contract = instance;
    })
  })

  it("owner should be set", function() {
    contract.owner()
    .then((_owner) => {
      assert.equal(owner, _owner, 'owner is not properly set');
    })
  });

  it("administrator should be set", function() {
    contract.registerAdministrator(accounts[1])
    .then((_result) => {
      return contract.administrator()
    })
    .then(administrator => {
      assert.equal(administrator, accounts[1], 'administrator is not expected value');
    })
  });

  it("only administrator can add product", function() {
    contract.registerAdministrator(accounts[1])
    .then((_result) => {
      return contract.addProduct( 1, "abc", 1, 5, {from: accounts[2]})
    })
    .then(_tx => {
      assert(false, "expected throw error for wrong administrator");
    })
    .catch(err => {
      assert(err.message.indexOf('invalid opcode') >= 0, 'only administrator should be able to add product');
    })
  });

  it("administrator should be able to add product", function() {
    contract.registerAdministrator(accounts[1])
    .then((_result) => {
      return contract.addProduct( 1, "abc", 1, 5, {from: accounts[1]})
    })
    .then(_tx => {
      return contract.isProduct(1)
    })
    .then((productAdded) => {
      assert.equal(true, productAdded, 'productId 1 should be added');
    })
  });

});