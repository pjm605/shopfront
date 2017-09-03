

module.exports = ['$scope', function ($scope) {

  $scope.createNewCoBuying = function () {
    if (parseInt($scope.newCoBuying.quantitiy) > 0 && parseInt($scope.newCoBuying.duration) > 0)  {

      $scope.contract.createNewCoBuying ($scope.newCoBuying.PId, $scope.newCoBuying.quantitiy, $scope.newCoBuying.duration, {from: $scope.account, gas: 4000000})
      .then(function (txn) {
        $scope.newCoBuying.PId = 0;
        $scope.newCoBuying.quantitiy = 0;
        $scope.newCoBuying.duration = 0;
      })
      .catch(err => {
        console.log("Error processing creating new coBuying, ", err);
      })
    } else {
      alert('Integers over Zero, please');
    }
  }
  
}]
