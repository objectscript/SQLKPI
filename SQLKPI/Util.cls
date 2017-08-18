Class SQLKPI.Util [ Abstract ]
{

ClassMethod executeSql(query As %String) As %Status
{
	set sc = $$$OK
	
	set sql = $zcvt(query,"l")
	
	quit:'..isSelectQuery(sql,.sc) sc
	
	set rs = ##class(%SQL.Statement).%ExecDirect(,query)
	
	if (rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100) {
		quit $$$ERROR(5521,rs.%SQLCODE,rs.%Message)
	}
	
	set obj = ..buildProxyFromRS(rs, .sc)
	quit:$$$ISERR(sc) sc
	
	set sc = obj.%ToJSON()
	
	quit sc
}

ClassMethod isSelectQuery(query As %String, ByRef sc As %Status) As %Boolean
{
	set sc = $$$OK
	if ($find(query,"insert ")) || ($find(query,"delete ")) 
	|| ($find(query,"update ")) || ($find(query,"create ")) 
	|| ($find(query,"grant ")) || ($find(query,"drop ")) 
	|| ($find(query,"truncate ") || ($find(query,"revoke ")) 
	|| ($find(query,"deny ")) || ($find(query,"commit ")) 
	|| ($find(query,"rollback ")) || ($find(query,"savepoint "))){
		set sc = $$$ERROR(5001,"An illegal operator was used. Please change the query.")
		quit $$$NO	
	}
	quit $$$YES
}

ClassMethod buildProxyFromRS(rs As %SQL.StatementResult, ByRef sc As %Status) As %ZEN.proxyObject
{
	set obj = ##class(%ZEN.proxyObject).%New()
	set metadata = rs.%GetMetadata()
	if 'metadata {
		set sc = $$$ERROR(5001,"SQL execution error.")
		quit 0
	}
	
	set columns = ##class(%ListOfDataTypes).%New()
	for i=1:1:metadata.columns.Count() {
		set tCol = ##class(%ZEN.proxyObject).%New()
		set temp = metadata.columns.GetAt(i)
		set tCol.name = temp.colName
		set tCol.type = $case(temp.typeClassGetObjectId(), "%Library.Date":1,:0)
		do columns.Insert(tCol)
	}
	
	kill metadata
	
	set result = ##class(%ListOfDataTypes).%New()
	set count = 0
	
	while rs.%Next() {
		quit:count>=5
		
		set row = ##class(%ZEN.proxyObject).%New()
		for i = 1:1:rs.%ResultColumnCount {
			set $property(row,columns.GetAt(i).name) = rs.%GetData(i)
		}
		do result.Insert(row)
		
		set count = count + 1
	}
	
	set obj.columns = columns
	set obj.result = result
	
	quit obj
}

ClassMethod getNamespaces() As %ArrayOfObjects
{
	Set namespaces = ##class(%ListOfDataTypes).%New()
	Set st = ##class(%CSP.Portal.Utils).%GetNamespaceList(.nslist)
	If $$$ISERR(st) Quit st
	Set namespace = $O(nslist(""))
	While namespace '= "" {
		Set enabled = $lg(nslist(namespace),1)
		If enabled = 1 {
			Set st = ..CheckNamespace(namespace)
			if $$$ISOK(st) do namespaces.Insert(namespace)
		}
		Set namespace = $O(nslist(namespace))
	}
	return namespaces
}

/// Returns OK if namespace both exists and contains MDX2JSON package.<br>
/// <b>Namespace</b> - name of namespace. Sets namespace variable to current namespace if empty or missing.
ClassMethod CheckNamespace(ByRef Namespace As %String = {$Namespace}) As %Status
{
	if (Namespace = "") {
		set Namespace = $Namespace
		return $$$OK
	}

	return:('##class(%SYS.Namespace).Exists(Namespace)) $$$ERROR($$$NamespaceUnavailable,Namespace)

	if Namespace'=$Namespace {
		set oldNS = $Namespace
		zn Namespace
		set exists = ##class(%Dictionary.CompiledClass).%ExistsId("SQLKPI.Util")
		zn oldNS
		return:(exists=0) $$$ERROR($$$GeneralError, "SQLKPI package is not mapped to " _ Namespace)
	}

	return $$$OK
}

ClassMethod getPackages() As %Status
{
	set obj = ##class(%ZEN.proxyObject).%New()
	set list = ##class(%ListOfDataTypes).%New()
	
	&sql(DECLARE C1 CURSOR FOR
		SELECT Name
		INTO :name 
		FROM %Dictionary.PackageDefinitionQuery_FlatPackage()
		WHERE NOT Name %STARTSWITH '%')
		
	&sql(OPEN C1)
	&sql(FETCH C1)
	while SQLCODE = 0 {
		do list.Insert(name)
		&sql(FETCH C1)
	}
	&sql(CLOSE C1)
	
	set obj.packages = list
	do obj.%ToJSON()
	
	quit $$$OK
}

ClassMethod getResources() As %Status
{
	set namespace = $namespace
	set $namespace = "%SYS"
	set obj = ##class(%ZEN.proxyObject).%New()
	set list = ##class(%ListOfDataTypes).%New()
	
	set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT Name FROM Security.Resources_List()")
	
	if ((rs.%SQLCODE = 0) || (rs.%SQLCODE = 100)) {
		while rs.%Next() {
			do list.Insert(rs.Name)
		}
	} else {
		quit $$$ERROR(5521,rs.%SQLCODE,rs.%Message)
	}	
	
	set obj.resources = list
	do obj.%ToJSON()
	set $namespace = namespace
	
	quit $$$OK
}

ClassMethod generate(request) As %Status
{
	set sc = $$$OK
	
	set kpiGen = ##class(SQLKPI.Generator).%New(request.query, request.config, request.properties, request.filters, .sc)
	if $$$ISERR(sc) quit sc
	
	set sc = kpiGen.generateKPIClass()
	if $$$ISERR(sc) quit sc
	
	set sc = kpiGen.compileGeneratedKPI()
	kill kpiGen
	
	quit sc
}

}

