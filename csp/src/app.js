(function() {
    'use strict';
    angular.module('templates',[]);

    angular.module('app',['ngRoute','cgNotify','smart-table','oi.select','ngAnimate','ui.bootstrap','templates'])
        .constant('CONST', {
            'ver': "{{package.json.version}}",
            'host': /*location.host,*/ "localhost:57773",
            'protocol': location.protocol,
            'application': 'sqlkpi'
        })
        .config(['$routeProvider', function ($routeProvider) {
        $routeProvider
            .when('/sql',{
                templateUrl: 'src/view/sql.html',
                controller: 'sql',
                resolve: {settings:['Connector', 'Storage', '$q', 'notify', '$rootScope', settingsResolver]}
            })
            .when('/config', {
                templateUrl: 'src/view/config.html',
                controller: 'config',
                resolve: {settings:['Connector', 'Storage', '$q', 'notify', '$rootScope', settingsResolver]}
            })
            .when('/filters', {
                templateUrl: 'src/view/filters.html',
                controller: 'filters',
                resolve: {settings:['Connector', 'Storage', '$q', 'notify', '$rootScope', settingsResolver]}
            })
            .otherwise('/config');
        }]);


    function settingsResolver(Connector, Storage, $q, notify, $rootScope) {

        var deffered = $q.defer();

        if (Connector.firstRun) {

            Connector.loadSettings().then(function success(response) {

                Storage.setNamespaces(response.data.namespaces);
                Connector.firstRun = false;
                $rootScope.$broadcast('menu:settingsLoaded');

                deffered.resolve();
            }, function error(response) {

                if (response.status == 500) {
                    notify({
                        message: response.data.ERROR,
                        classes: 'alert-danger'
                    });
                } else {
                    Connector.unhandledErrors(response.status);
                }

                deffered.reject();
            });
        }
        else deffered.resolve();

        return deffered.promise;
    }
})();