(function () {
    'use strict'
    function MenuCtrl($scope, CONST, Storage, $rootScope, $location) {
        $scope.model = {
            version: CONST.ver,
            namespaces: [],
            namespace: "" || localStorage.namespace
        };

        var _mainScope = $scope.$parent;

        $scope.updateNamespace = updateNamespace;

        $rootScope.$on('menu:settingsLoaded', init);

        function updateNamespace() {
            Storage.setNamespace($scope.model.namespace);
            _mainScope.clearMainModel();
            $location.path('/config');
            $rootScope.$broadcast('config:changeNamespace');
        }

        function init() {
            $scope.model.namespaces = Storage.getNamespaces();

            if(Storage.getNamespace() === "" && $scope.model.namespaces.length)
                Storage.setNamespace($scope.model.namespaces[0]);

            $scope.model.namespace=Storage.getNamespace();
        }

    }

    angular.module('app').controller('menu', ['$scope', 'CONST', 'Storage', '$rootScope', '$location', MenuCtrl]);
})();