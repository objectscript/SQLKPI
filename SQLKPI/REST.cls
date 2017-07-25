Class SQLKPI.REST Extends SQLKPI.AbstractREST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/sql" Method="POST" Call="executeSQL"/>
<Route Url="/kpi" Method="POST" Call="generateKPI"/>
<Route Url="/logout" Method="GET" Call="logout"/>
<Route Url="/test" Method="GET" Call="test"/>
</Routes>
}

/// Logout current session
ClassMethod logout() As %Status
{
    #dim %session As %CSP.Session
    set st = %session.Logout(1)
    set %session.EndSession = 1
    return st
}

/// Test
ClassMethod test() As %Status
{
    write "{""status"": ""OK""}"
    return $$$OK
}

ClassMethod executeSQL() As %Status
{
	set sc = $$$OK
	set rs = ##class(%SQL.Statement).%ExecDirect(,%request.Content.query)
	
	if (rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100) {
		quit $$$ERROR(5521,rs.%SQLCODE,rs.%Message)
	}
	
	set obj = ##class(%ZEN.proxyObject).%New()
	set metadata = rs.%GetMetadata()
	
	set columnNames = ##class(%ListOfDataTypes).%New()
	for i=1:1:metadata.columns.Count() {
		set tCol = metadata.columns.GetAt(i)
		do columnNames.Insert(tCol.colName)
	}
	
	set obj."sql_code" = rs.%SQLCODE
	set obj.columns = columnNames
	set sc = obj.%ToJSON()
	
	quit sc
}

ClassMethod generateKPI() As %Status
{
	set sql = %request.Content.SQL
	set name = %request.Content.Name
	set class = %request.Content.Class
	
	// TODO check that it's valid
	
	return ##class(SQLKPI.Generator).generateKPIClass(sql, name, class)
}

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.

}

