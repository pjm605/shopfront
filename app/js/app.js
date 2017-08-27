require("file-loader?name=../index.html!../index.html");

const Web3 = require("web3");
const Promise = require("bluebird");
const truffleContract = require("truffle-contract");
const shopfrontJson = require("../../build/contracts/Shopfront.json");

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


app.controller("ShopfrontCtrl", [ '$scope', '$location', '$http', '$q', '$window', '$timeout', 
  function ($scope, $location, $http, $q, $window, $timeout) {
  	$scope.products = [];
  	console.log("hello")
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
	  			newProduct.args.productPrice = newProduct.args.productPrice.toString(10);
	  			$scope.products.push(newProduct);
	  			$scope.$apply(); 
	  		}
  		})

  		$scope.$apply(); 
  	})

  	

  	//$scope.$apply();
}])