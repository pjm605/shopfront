

module.exports = ['$scope', function ($scope) {

    $scope.buyProduct = function () {

      var productId = parseInt($scope.buyProductId);
      var quantity  = parseInt($scope.buyProductQuantity);
      var value = parseInt($scope.buyValue);

      $scope.buyProductId       = "";
      $scope.buyProductQuantity = "";
      $scope.buyValue           = 0;
      $scope.contract.buyProduct(productId, quantity, {from: $scope.accounts[2], value: value})
      .then(tx => {
        console.log(tx);
      })
      .catch(err => {
        console.log("Error processing deleteProduct, ", err);
      })
    }

}]
