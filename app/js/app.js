require("file-loader?name=../index.html!../index.html");

const Web3            = require("web3");
const Promise         = require("bluebird");
const truffleContract = require("truffle-contract");
const shopfrontJson   = require("../../build/contracts/Shopfront.json");

if (typeof web3 !== 'undefined') {
    // Use the Mist/wallet/Metamask provider.
    window.web3 = new Web3(web3.currentProvider);
} else {
    // Your preferred fallback.
    window.web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}

Promise.promisifyAll(web3.eth, { suffix: "Promise" });
Promise.promisifyAll(web3.version, { suffix: "Promise" });


const Shopfront = truffleContract(shopfrontJson);
Shopfront.setProvider(web3.currentProvider);

var app = angular.module('app', []);

app.config(function ($locationProvider) {
    $locationProvider.html5Mode(false);
});

function hexToAscii (str) {
  var hex = str.toString();
  var result = '';
  for (var i =2; i < str.length; i += 2) {
    var code = String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    result += code;
  }

  return result;
}

app.controller('ShopfrontCtrl', function ($scope) {
    $scope.products = [];

    Shopfront.deployed()
    .then(function (_instance) {
      $scope.contract = _instance;
      console.log("The contract: ", $scope.contract);

      $scope.productAddedWatch = $scope.contract.LogNewProduct({}, {fromBlock: 0})
      .watch(function (err, newProduct) {
        if (err) {
          console.log("Error watching new product events", err);
        } else {
          console.log("New Product ", newProduct);

          var pNameToString = hexToAscii(newProduct.args.productName);
          newProduct.args.productId = newProduct.args.productId.toString(10);
          newProduct.args.productName = pNameToString;
          newProduct.args.productPrice = newProduct.args.productPrice.toString(10);
          $scope.products.push(newProduct);
          $scope.$apply(); 
        }
      });

      $scope.productUpdateWatch = $scope.contract.LogUpdateProduct({}, {fromBlock: 0})
      .watch(function (err, updateProduct) {
        if (err) {
          console.log("Error watching update product events", err);
        } else {
          console.log("Update Product ", updateProduct);
          var updatedProdcutId = updateProduct.args.productId.toString(10);
          var updatedIndex = parseInt(updateProduct.args.index);
          
          updateProduct.args.productId = updatedProdcutId;
          updateProduct.args.productName = hexToAscii(updateProduct.args.productName);
          updateProduct.args.productPrice = updateProduct.args.productPrice.toString(10);

          $scope.products[updatedIndex] = updateProduct;
          $scope.$apply(); 

        }
      });

      $scope.productDeleteWatch = $scope.contract.LogDeleteProduct({}, {fromBlock: 0})
      .watch(function (err, deleteProduct) {
        if (err) {
          console.log("Error watching delete product events", err);
        } else {
          console.log("Delete Product", deleteProduct);
          $scope.products.splice($scope.products.length - 1);
          $scope.$apply(); 
        }
      })

      $scope.$apply(); 
    });


    $scope.addProduct = function () {
      var productId     = parseInt($scope.newProductId);
      var productName   = $scope.newProductName;
      var productPrice  = parseInt($scope.newProductPrice);
      var productStock  = parseInt($scope.newProductStock);

      $scope.newProductId     = "";
      $scope.newProductName   = "";
      $scope.newProductPrice  = 0;
      $scope.newProductStock  = 0;

      //if ()

      $scope.contract.addProduct (productId, productName, productPrice, productStock, { from: $scope.administrator, gas: 900000})
      .then(tx => {
        console.log(tx);
      })
      .catch(err => {
        console.log("Error processing addProduct, ", err);
      })

    };

    $scope.deleteProduct = function (productId) {
      $scope.deleteProductId = "";

      $scope.contract.deleteProduct (productId, { from: $scope.administrator, gas: 900000})
      .then(tx => {
        console.log(tx);
      })
      .catch(err => {
        console.log("Error processing addProduct, ", err);
      })
    }

    // $scope.buyProduct = function () {
    //   var productId = parseInt($scope.orderProductId);
    //   var quantity  = parseInt($scope.orderProductQuantity);
    //   var value = parseInt($scope.orderValue);

    //   $scope.orderProductId       = "";
    //   $scope.orderProductQuantity = "";
    //   $scope.orderValue           = 0;

    //   $scope.contract.buyProduct(productId, quantity, {from: $scope.accounts[2], value: value})
    //   .then(tx => {
    //     console.log(tx);
    //   })
    //   .catch(err => {
    //     console.log("Error processing deleteProduct, ", err);
    //   })
    // }



    web3.eth.getAccounts(function (err, accs) {
      if (err != null) {
        console.log ("There was an error fetching you accounts");
        return; 
      }
    
      if (accs.length == 0) {
        console.log ("There was zero account")
        return;
      }

      $scope.accounts = accs;
      $scope.owner = $scope.accounts[0];
      $scope.administrator = $scope.accounts[0];
      $scope.$apply();
    })

});
