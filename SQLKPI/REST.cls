Class SQLKPI.REST Extends SQLKPI.AbstractREST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/sql" Method="POST" Call="executeSQL"/>
<Route Url="/get_settings" Method="GET" Call="getServerSettings" />
<Route Url="/get_packages" Method="GET" Call="getPackages" />
<Route Url="/get_resources" Method="GET" Call="getResources" />
<Route Url="/generate" Method="POST" Call="generate" />
</Routes>
}

/// Logout current session
ClassMethod executeSQL() As %Status
{
	new $namespace
	set namespace = %request.Get("ns")
	set $namespace = namespace
	set %response.ContentType = "application/json"
	quit ##class(SQLKPI.Util).executeSql(%request.Content.query)
}

ClassMethod getServerSettings() As %Status
{
	set obj = ##class(%ZEN.proxyObject).%New()
	set obj.namespaces = ##class(SQLKPI.Util).getNamespaces()
	do obj.%ToJSON()
	return $$$OK
}

ClassMethod getPackages() As %Status
{
	new $namespace
	set namespace = %request.Get("ns")
	set $namespace = namespace
	quit ##class(SQLKPI.Util).getPackages()
}

ClassMethod getResources() As %Status
{
	new $namespace
	set namespace = %request.Get("ns")
	set $namespace = namespace
	quit ##class(SQLKPI.Util).getResources()
}

ClassMethod generate() As %Status
{
	new $namespace
	set namespace = %request.Get("ns")
	set $namespace = namespace
	quit ##class(SQLKPI.Util).generate(%request.Content)
}

}

