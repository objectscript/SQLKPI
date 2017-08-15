(function () {
    'use strict'
    function SqlCtrl($scope, notify, $location, Storage, Connector) {
        $scope.model = {
            query: '',
            executed: false,
            executed_data: {
                columns:[],
                result:[]
            }
        };

        $scope.executeSQL = executeSQL;
        $scope.nextPage = nextPage;
        $scope.prevPage = prevPage;

        var _main = $scope.$parent.model;

        function executeSQL() {
            Connector.executeSQL($scope.model.query, Storage.getNamespace()).then(function success(response) {
                var data = response.data;
                $scope.model.executed_data = data;
                $scope.model.executed = true;
            }, function error(response) {
                var data = response.data;
                notify({
                    message: data.ERROR,
                    classes: 'alert-danger'
                });
            });
        }

        function nextPage() {
            if (!$scope.model.executed) return;
            _main.kpi.sql.query = $scope.model.query;
            _main.kpi.sql.columns = $scope.model.executed_data.columns;
            $location.path('/filters');
        }

        function prevPage() {
            _main.kpi.sql.query = $scope.model.query;
            _main.kpi.sql.columns = $scope.model.executed_data.columns;
            $location.path('/config');
        }

        function init() {

            if (!_main.kpi.config.packageName ||
                !_main.kpi.config.className ||
                !_main.kpi.config.KPIName) {
                $location.path('/config');
            }
            if (_main.kpi.sql.query) {
                $scope.model.query = _main.kpi.sql.query;

            }
            if (_main.kpi.sql.columns.length) {
                $scope.model.executed_data.columns = _main.kpi.sql.columns;
            }
        }
        init();
    }

    angular.module('app').controller('sql', ['$scope', 'notify', '$location', 'Storage', 'Connector', SqlCtrl]);
})();