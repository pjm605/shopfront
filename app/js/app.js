require("file-loader?name=../index.html!../index.html");

const Web3            = require("web3");
const Promise         = require("bluebird");
const truffleContract = require("truffle-contract");
const shopfrontJson   = require("../../build/contracts/Shopfront.json");
const coBuyingJson   = require("../../build/contracts/CoBuying.json");

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

const CoBuying = truffleContract(coBuyingJson);
CoBuying.setProvider(web3.currentProvider);


/////////////////////////////////////////////////////////
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

app.run(['$rootScope', function ($rootScope) {
    $rootScope.products = [];
    $rootScope.purchase = [];
    $rootScope.coBuyings = [];

    Shopfront.deployed()
    .then(function (_instance) {
      $rootScope.contract = _instance;
      console.log("The contract: ", $rootScope.contract);

      $rootScope.productAddedWatch = $rootScope.contract.LogNewProduct({}, {fromBlock: 0})
      .watch(function (err, newProduct) {
        if (err) {
          console.log("Error watching new product events", err);
        } else {
          console.log("New Product ", newProduct);

          var pNameToString = hexToAscii(newProduct.args.productName);
          newProduct.args.productId = newProduct.args.productId.toString(10);
          newProduct.args.productName = pNameToString;
          newProduct.args.productPrice = newProduct.args.productPrice.toString(10);
          $rootScope.products.push(newProduct);
          $rootScope.$apply(); 
        }
      });

      $rootScope.productUpdateWatch = $rootScope.contract.LogUpdateProduct({}, {fromBlock: 0})
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

          $rootScope.products[updatedIndex] = updateProduct;
          $rootScope.$apply(); 

        }
      });

      $rootScope.productDeleteWatch = $rootScope.contract.LogDeleteProduct({}, {fromBlock: 0})
      .watch(function (err, deleteProduct) {
        if (err) {
          console.log("Error watching delete product events", err);
        } else {
          console.log("Delete Product", deleteProduct);
          if ($rootScope.products.length == 1) {
            $rootScope.products = [];
          } else {
            $rootScope.products.splice($rootScope.products.length - 1);
          }
          $rootScope.$apply(); 
        }
      })

      $rootScope.productPurchaseWatch = $rootScope.contract.LogBuyProduct({}, {fromBlock: 0})
      .watch(function (err, purchasedProduct) {
        if (err) {
          console.log("Error watching purchase product events", err);
        } else {
          console.log("purchase Product", purchasedProduct);

          purchasedProduct.args.productId = purchasedProduct.args.productId.toString(10);
          purchasedProduct.args.quantity = purchasedProduct.args.quantity.toString(10);
          $rootScope.purchase.push(purchasedProduct);
          $rootScope.$apply(); 
        }
      })

      $rootScope.$apply(); 
    });
    
    // $rootScope.setAccount = function () {
    //   $rootScope.account = $scope.accountSelected;
    //   $rootScope.balance = web3.eth.getBalance($scope.account).toString(10);

    //   console.log('Using account',$scope.account);
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

      $rootScope.accounts = accs;
      $rootScope.owner = $rootScope.accounts[0];
      $rootScope.administrator = $rootScope.accounts[0];
      // $rootScope.account = $rootScope.accounts[0];
      // $rootScope.balance = web3.eth.getBalance($rootScope.account).toString(10);
      $rootScope.$apply();
    })

}])

app.controller('AdminCtrl', require('./controllers/AdminCtrl.js'));
app.controller('BuyCtrl', require('./controllers/BuyCtrl.js'));


