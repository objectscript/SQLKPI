(function () {
    'use strict'
    function ConfigCtrl($scope, notify, Connector, Storage, $rootScope,$location) {
        $scope.model = {
            packages: [],
            resources: [],
            packageName: "",
            className: "",
            KPICaption: "",
            KPIName: "",
            description: "",
            domain: "",
            resource: ""
        };

        $scope.nextPage = nextPage;

        $rootScope.$on('config:changeNamespace', getPackages);

        var _main = $scope.$parent.model;

        function nextPage() {
            var pack = "."+$scope.model.packageName;
            if (pack == "." || !regTest(pack,/((\.%?[a-zA-Z])([a-zA-Z0-9])*)+/g)) {
                notify({
                    message: "Invalid package name.",
                    classes: 'alert-danger'
                });
                return;
            }

            if ($scope.model.className == "" || !regTest($scope.model.className,/^[a-zA-Z]([a-zA-Z0-9])*/)) {
                notify({
                    message: "Invalid class name.",
                    classes: 'alert-danger'
                });
                return;
            }

            if ($scope.model.KPIName === "") $scope.model.KPIName = angular.element(document.getElementById('KPIName')).val();
            var kpi = "/"+$scope.model.KPIName;
            if (kpi == "/" || !regTest(kpi,/((\/[a-zA-Z])([a-zA-Z0-9])*)+/g)) {
                notify({
                    message: "Invalid KPI name.",
                    classes: 'alert-danger'
                });
                return;
            }

            for (var key in _main.kpi.config) {
                _main.kpi.config[key] = $scope.model[key];
            }

            $location.path("/sql");
        }

        function getPackages() {
            Connector.getPackages(Storage.getNamespace()).then(function success(response) {
                $scope.model.packages = response.data.packages;
            }, function error(response) {

            });
        }

        function getResources() {
            Connector.getResources().then(function success(response) {
                $scope.model.resources = response.data.resources;
            }, function error(response) {

            });
        }

        function init() {
            for (var key in _main.kpi.config) {
                if (_main.kpi.config[key] !== "") $scope.model[key] = _main.kpi.config[key];
            }

            getResources();
            getPackages();
        }
        init();
    }

    function regTest(string , regexp) {
        var match = string.match(regexp);
        return match ? match[0] === string : false;
    }

    angular.module('app').controller('config', ['$scope','notify','Connector', 'Storage','$rootScope', '$location',ConfigCtrl]);
})();