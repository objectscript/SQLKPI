(function () {
    'use strict';
    function ModalWarningCtrl($scope, filter, $uibModalInstance) {

        $scope.ok = function () {
            $uibModalInstance.close();
        };

        $scope.cancel = function () {
            filter.active = !filter.active;
            $uibModalInstance.dismiss('cancel');
        };
    }

    angular.module('app').controller('warning', ['$scope','filter','$uibModalInstance', ModalWarningCtrl]);
})();