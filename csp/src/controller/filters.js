(function () {
    'use strict'
    function FiltersCtrl($scope, $location, $uibModal, Connector, Storage, notify) {
        $scope.model = {
            filters: []
        };

        var _main = $scope.$parent;

        $scope.scrollToTop = function () {
            window.scrollTo(0,0);
        };

        $scope.scrollToBottom = function () {
            window.scrollTo(0,document.body.scrollHeight)
        };

        $scope.addToValueList = addToValueList;

        $scope.removeFromValueList = removeFromValueList;

        $scope.editValueListElem = editValueListElem;
        
        $scope.checkDepends = checkDepends;

        $scope.prevPage = prevPage;

        $scope.generate = generate;

        function addToValueList(f_idx) {
            if ($scope.model.filters[f_idx].current_displayName === "")
                $scope.model.filters[f_idx].current_displayName = angular.element(document.getElementById('cur_displayName_'+f_idx)).val();

            $scope.model.filters[f_idx].valueList.push({
                value: $scope.model.filters[f_idx].current_value,
                displayName: $scope.model.filters[f_idx].current_displayName
            });

            $scope.model.filters[f_idx].current_value = "";
            $scope.model.filters[f_idx].current_displayName = "";
        }

        function removeFromValueList(f_idx,idx) {
            $scope.model.filters[f_idx].valueList.splice(idx,1);
        }

        function editValueListElem(elem) {
           var instance = $uibModal.open({
               templateUrl: 'src/template/editModal.html',
               controller: 'edit',
               ariaLabelledBy: 'modal-title',
               ariaDescribedBy: 'modal-body',
               animation: true,
               resolve: {
                   value: function () {
                       return elem;
                   }
               }
           });
        }

        function checkDepends(filter) {
            if (filter.active) {
                filter.dependsOn = "";
                return;
            }

            for (var i = 0; i < $scope.model.filters.length; i++) {
                if ($scope.model.filters[i].dependsOn) {
                    if ($scope.model.filters[i].active && !$scope.model.filters[i].dependsOn.localeCompare(filter.name)) {

                        var instance = $uibModal.open({
                            templateUrl: 'src/template/warningModal.html',
                            controller: 'warning',
                            ariaLabelledBy: 'modal-title',
                            ariaDescribedBy: 'modal-body',
                            animation: true,
                            size: 'sm',
                            resolve: {
                                filter: function () {
                                    return filter;
                                }
                            }
                        });

                        instance.result.then(function () {

                            for (var i = 0; i < $scope.model.filters.length; i++) {
                                if ($scope.model.filters[i].dependsOn === null) {
                                    $scope.model.filters[i].dependsOn = "";
                                }
                            }
                        }, function () {

                            for (var i = 0; i < $scope.model.filters.length; i++) {
                                if ($scope.model.filters[i].dependsOn === null) {
                                    $scope.model.filters[i].dependsOn = filter.name;
                                }
                            }
                        });

                        break;
                    }
                }
            }
        }
        
        function prevPage() {
            _main.model.kpi.filters = $scope.model.filters;
            $location.path('/sql');
        }

        function generate() {

            for (var i = 0; i < $scope.model.filters.length; i++) {
                if ($scope.model.filters[i].active) {
                    if ($scope.model.filters[i].runtime) {
                        if (!$scope.model.filters[i].sql) {
                            notify({
                                message: "Please, fill 'sql' field of the filter '"+$scope.model.filters[i].filterProperty+"' property.",
                                classes: 'alert-danger'
                            });
                            return;
                        }
                    } else {
                        if (!$scope.model.filters[i].valueList.length) {
                            notify({
                                message: "Please, add at least one property to the list of the filter '"+$scope.model.filters[i].filterProperty+"' property.",
                                classes: 'alert-danger'
                            });
                            return;
                        }
                    }
                }
            }

            _main.model.kpi.filters = $scope.model.filters;

            _main.generate().then(function success(requestObj) {
                Connector.generateKPI(requestObj,Storage.getNamespace()).then(function success(response) {
                    notify({
                        message: "Generation complete. Please, check you class.",
                        classes: 'alert-success'
                    });
                }, function error(response) {

                    if (response.status == 500) {
                        notify({
                            message: response.data.ERROR,
                            classes: 'alert-danger'
                        });
                    } else {
                        Connector.unhandledErrors(response.status);
                    }
                });
            }, function error() {

            });
        }

        function init() {
            if (_main.model.kpi.sql.columns.length === 0) $location.path('/sql');

            if (_main.model.kpi.filters.length !== (_main.model.kpi.sql.columns.length - 1)) _main.model.kpi.filters.length = 0;
            else {
                for (var i = 0; i < _main.model.kpi.filters.length; i++) {
                    if (_main.model.kpi.filters[i].filterProperty.localeCompare(_main.model.kpi.sql.columns[i+1].name) !== 0) {
                        _main.model.kpi.filters.length = 0;
                        break;
                    }
                }
            }

            if (_main.model.kpi.filters.length === 0) {
                for (var i = 1; i < _main.model.kpi.sql.columns.length; i++) {
                    $scope.model.filters.push({
                        filterProperty: String(_main.model.kpi.sql.columns[i].name),
                        name: _main.model.kpi.sql.columns[i].name+"_filter",
                        displayName: String(_main.model.kpi.sql.columns[i].name),
                        active: false,
                        runtime: '1',
                        valueList: [],
                        sql: String(_main.model.kpi.sql.query),
                        dependsOn:"",
                        multiSelect: false,
                        searchType: _main.model.kpi.sql.columns[i].type ? "day" : "",
                        current_value: "",
                        current_displayName: ""
                    });
                }
            } else $scope.model.filters = _main.model.kpi.filters;
        }
        init();
    }

    angular.module('app').controller('filters',['$scope', '$location','$uibModal', 'Connector', 'Storage', 'notify', FiltersCtrl]);
})();