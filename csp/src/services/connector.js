(function () {
    'use strict'
    function ConnectorSvc($http, CONST, notify) {
        this.firstRun = true;
        this.loadSettings = loadSettings;
        this.getPackages = getPackages;
        this.getResources = getResources;
        this.executeSQL = executeSQL;
        this.generateKPI = generateKPI;
        this.unhandledErrors = unhandledErrors;

        function loadSettings() {
            if (!localStorage) localStorage = {};
            return $http({
                method: 'GET',
                url: CONST.protocol + '//' + CONST.host + '/' + CONST.application + '/get_settings'
            });
        }

        function getPackages(namespace) {
            return $http({
                method:'GET',
                url: CONST.protocol + '//' + CONST.host + '/' + CONST.application + '/get_packages?ns=' + namespace
            });
        }

        function getResources() {
            return $http({
                method:'GET',
                url: CONST.protocol + '//' + CONST.host + '/' + CONST.application + '/get_resources'
            })
        }

        function executeSQL(query, namespace) {
            return $http({
                method: 'POST',
                data: {query: query},
                url: CONST.protocol + '//' + CONST.host + '/' + CONST.application + '/sql?ns='+namespace,
                headers: {
                    'Content-Type': 'application/json'
                }
            })
        }

        function generateKPI(sendData, namespace) {
            return $http({
                method: 'POST',
                data: sendData,
                url: CONST.protocol + '//' + CONST.host + '/' + CONST.application + '/generate?ns='+namespace,
            })
        }

        function unhandledErrors(status) {
            notify({
                message: 'Error code ' + status,
                classes: 'alert-danger'
            });
        }
    }

    angular.module('app').service('Connector',['$http', 'CONST', 'notify', ConnectorSvc])
})();