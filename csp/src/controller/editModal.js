(function () {
    'use strict'
    function ModalEditCtrl($scope, value, $uibModalInstance) {
        $scope.model={
            valueObj : value,
            edit_value: "",
            edit_displayName: ""
        };

        $scope.ok = function () {

            if ($scope.model.edit_value === "") $scope.model.edit_value =
                angular.element(document.getElementById('edit_value')).val();
            $scope.model.valueObj.value = $scope.model.edit_value;

            if ($scope.model.edit_displayName === "") $scope.model.edit_displayName =
                angular.element(document.getElementById('edit_displayName')).val();
            $scope.model.valueObj.displayName = $scope.model.edit_displayName;

            $uibModalInstance.close();
        };

        $scope.cancel = function () {
            $uibModalInstance.close();
        };
    }

    angular.module('app').controller('edit', ['$scope','value', '$uibModalInstance', ModalEditCtrl]);
})();