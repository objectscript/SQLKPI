(function () {
    'use strict';
    function StorageSvc() {
        var namespaces = [];
        var namespace = "" || localStorage.namespace;

        this.getNamespace = getNamespace;
        this.setNamespace = setNamespace;
        this.setNamespaces = setNamespaces;
        this.getNamespaces = getNamespaces;

        function getNamespace() {
            if (getNamespaces().indexOf(namespace) >= 0) return namespace;
            else return "";
        }

        function setNamespace(name) {
            if (!name) name = "";
            namespace = name;
            localStorage.namespace = namespace;
        }

        function setNamespaces(namespacesArray) {
            if (namespacesArray == null || !Array.isArray(namespacesArray)) namespaces = [];
            else namespaces = namespacesArray;
        }

        function getNamespaces() {
            if (namespaces) return namespaces;
            else return [];
        }
    }

    angular.module('app').service('Storage', [StorageSvc]);

})();