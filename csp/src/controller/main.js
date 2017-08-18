(function () {
    'use strict';
    function MainCtrl($scope, $q) {

        $scope.model = {
            kpi: {
                sql: {
                    query: "",
                    columns: []
                },
                config: {
                    packageName: "",
                    className: "",
                    KPICaption: "",
                    KPIName: "",
                    description: "",
                    domain: "",
                    resource: ""
                },
                filters:[]
            }
        };

        $scope.clearMainModel = clearMainModel;
        
        $scope.generate = generate;

        function clearMainModel() {
            clearModel($scope.model);
        }

        function generate() {
            var deffered = $q.defer();

            var requestObj = {
                query: $scope.model.kpi.sql.query,
                properties: [],
                config: $scope.model.kpi.config,
                filters: []
            };

            for (var i = 1; i < $scope.model.kpi.sql.columns.length; i++) {
                requestObj.properties.push($scope.model.kpi.sql.columns[i].name);
            }

            for (var i = 0; i < $scope.model.kpi.filters.length; i++) {

                if (!$scope.model.kpi.filters[i].active) continue;

                var tObj = {};
                tObj.filterProperty = $scope.model.kpi.filters[i].filterProperty;
                tObj.name = $scope.model.kpi.filters[i].name;
                tObj.displayName = $scope.model.kpi.filters[i].displayName;

                if ($scope.model.kpi.filters[i].searchType === "") {
                    tObj.runtime = !!$scope.model.kpi.filters[i].runtime;

                    if (tObj.runtime) {
                        tObj.sql = $scope.model.kpi.filters[i].sql;
                    } else {

                        var tValueList = [];
                        var tDisplayList = [];
                        for (var j = 0; j < $scope.model.kpi.filters[i].valueList.length; j++) {
                            tValueList.push($scope.model.kpi.filters[i].valueList[j].value);
                            tDisplayList.push($scope.model.kpi.filters[i].valueList[j].displayName);
                        }

                        tObj.valueList = tValueList.join(',');
                        tObj.displayList = tDisplayList.join(',');
                    }
                }

                tObj.dependsOn = $scope.model.kpi.filters[i].dependsOn;
                tObj.multiSelect = $scope.model.kpi.filters[i].multiSelect;
                tObj.searchType = $scope.model.kpi.filters[i].searchType;

                requestObj.filters.push(tObj);
            }

            deffered.resolve(requestObj);
            return deffered.promise;
        }

        function clearModel(obj) {
            if (typeof(obj) === "object") {
                if (Array.isArray(obj)) obj.length = 0;
                else {
                    for (var key in obj) {
                        if (typeof(obj[key]) === "string") obj[key] = "";
                        else clearModel(obj[key]);
                    }
                }
            }
        }
    }

    angular.module('app').controller('main', ['$scope', '$q', MainCtrl]);
})();