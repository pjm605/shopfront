
module.exports = ['$scope', function ($scope) {


    $scope.addProduct = function () {
    	console.log("newProductId: ", $scope.newProductId)
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

    $scope.buyProduct = function () {

      var productId = parseInt($scope.buyProductId);
      var quantity  = parseInt($scope.buyProductQuantity);
      var value = parseInt($scope.buyValue);

      $scope.buyProductId       = "";
      $scope.buyProductQuantity = "";
      $scope.buyValue           = 0;
      //console.log("productId ," + productId + "quantity, " + quantity + " value " + value);
      $scope.contract.buyProduct(productId, quantity, {from: $scope.accounts[2], value: value})
      .then(tx => {
        console.log(tx);
      })
      .catch(err => {
        console.log("Error processing deleteProduct, ", err);
      })
    }

}]
