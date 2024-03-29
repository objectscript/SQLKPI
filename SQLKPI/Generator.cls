/// Generates kpi class
Class SQLKPI.Generator Extends %RegisteredObject
{

Property kpiClass As %Dictionary.ClassDefinition;

Property properties As %ListOfDataTypes;

Property filters As %ListOfObjects;

Property config As %ZEN.proxyObject;

Property query As %String;

Property generated As %Boolean [ InitialExpression = {$$$NO} ];

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew(query As %String = "", config As %ZEN.proxyObject, properties As %ListOfDataTypes, filters As %ListOfObjects, ByRef sc As %Status) As %Status [ Private, ServerOnly = 1 ]
{

	if (query = "") quit $$$ERROR(5001, "SQLKPI can not exist without a sql query.")
	
	if ('$data(config)) 
	|| (config.packageName = "") 
	|| (config.className = "") 
	|| (config.KPIName = "")
	{
		set sc = $$$ERROR(5001, "Error with KPI configuratin.")
	}
	
	if ('$data(properties)) set properties = ##class(%ListOfDataTypes).%New()
	if ('$data(filters)) set filters = ##class(%ListOfObjects).%New()
	
	set fullName = config.packageName_"."_config.className
	
	if '##class(%Dictionary.ClassDefinition).%ExistsId(fullName) {
		set ..kpiClass = ##class(%Dictionary.ClassDefinition).%New()
	} else {
		set sc = $$$ERROR(5001,"Class with this name already exists.")
	}
	
	set ..query = query
	set ..config = config
	set ..properties = properties
	set ..filters = filters
	
	quit $$$OK
}

Method generateKPIClass() As %Status
{
	set (sc,sc1,sc2,sc3, SC) = $$$OK
	set fullName = ..config.packageName_"."_..config.className
		
	do ..kpiClass.NameSet(fullName)
	do ..kpiClass.SuperSet("%DeepSee.KPI")
	do ..kpiClass.GeneratedBySet("SQLKPI.Generator")
	
	set descripton = "This kpi class was automatically generated by SQLKPI utility."_$char(10)_..config.description
	
	set descList = $listFromString(descripton, $char(10))
	for i = 2:1:$listLength(descList) set $list(descList,i) = "/// "_$list(descList,i)
	set descripton = $listToString(descList, $char(10))
	
	do ..kpiClass.DescriptionSet(descripton)
	
	set domain = ##class(%Dictionary.ParameterDefinition).%New(fullName_":DOMAIN")
	set domain.Default = ..config.domain
	//set sc2 = domain.%Save()
	do ..kpiClass.Parameters.Insert(domain)
	
	set resource = ##class(%Dictionary.ParameterDefinition).%New(fullName_":RESOURCE")
	set resource.Default = ..config.resource
	//set sc3 = resource.%Save()
	do ..kpiClass.Parameters.Insert(resource)
	
	
	set kpiXData = ..generateXData(sc)
	do ..kpiClass.XDatas.Insert(kpiXData)
	
	set onSQLMethod = ..generateFilterMethod(sc)
	do ..kpiClass.Methods.Insert(onSQLMethod)
	
	set sc1 = ..kpiClass.%Save()
	
	set SC = $$$ADDSC(sc, $$$ADDSC(sc1, $$$ADDSC(sc2, sc3)))
	
	if $$$ISOK(SC) set ..generated = $$$YES
	
	quit SC
}

Method compileGeneratedKPI() As %Status
{
	set sc = $$$OK
	set fullName = ..config.packageName_"."_..config.className
	
	if ('..generated) quit $$$ERROR(5001,"You are trying to compile a non-existent class.")
	set sc = $system.OBJ.Compile(fullName, "cuks /displaylog=0 /displayerror=0")
	quit sc
}

Method generateXData(ByRef sc As %Status) As %Dictionary.XDataDefinition
{
	set sc = $$$OK
	set fullName = ..config.packageName_"."_..config.className
	
	set kpi = ##class(%Dictionary.XDataDefinition).%New(fullName_":KPI")
	set kpi.XMLNamespace = "http://www.intersystems.com/deepsee/kpi"
	
	set writer = ##class(%XML.Writer).%New()
	do writer.OutputToString()
	
	set elem = ##class(%XML.Element).%New("kpi")
	do elem.AddAttribute("xmlns","http://www.intersystems.com/deepsee/kpi")
	do elem.AddAttribute("name",..config.KPIName)
	do elem.AddAttribute("sourceType","sql")
	do elem.AddAttribute("caption",..config.KPICaption)
	do elem.AddAttribute("sql",..query)
	
	do writer.RootElement(elem)
	kill elem
	
	for i=1:1:..properties.Count() {
		set elem = ##class(%XML.Element).%New("property")
		do elem.AddAttribute("name",..properties.GetAt(i))
		do elem.AddAttribute("columnNo",i+1)
		
		do writer.Element(elem)
		do writer.EndElement()
		kill elem
	}
	
	for i=1:1:..filters.Count() {
		set elem = ##class(%XML.Element).%New("filter")
		do elem.AddAttribute("name",..filters.GetAt(i).name)
		do elem.AddAttribute("filterProperty",..filters.GetAt(i).filterProperty)
		do elem.AddAttribute("multiSelect",$case(..filters.GetAt(i).multiSelect, 1:"true", :"false"))
		do elem.AddAttribute("dependsOn",..filters.GetAt(i).dependsOn)
		do elem.AddAttribute("displayName",..filters.GetAt(i).displayName)
		
		if ..filters.GetAt(i).searchType = "day" {
			do elem.AddAttribute("searchType",..filters.GetAt(i).searchType)
		} else {
			if (..filters.GetAt(i).runtime) {
				do elem.AddAttribute("sql",..filters.GetAt(i).sql)
			} else {
				do elem.AddAttribute("valueList",..filters.GetAt(i).valueList)
				do elem.AddAttribute("displayList",..filters.GetAt(i).displayList)
			}
		}
		
		do writer.Element(elem)
		do writer.EndElement()
		kill elem
	}
	
	do writer.EndRootElement()
	set simplePrettify = $replace(writer.GetXMLString(), "><",">"_$char(10)_"<")
	do kpi.Data.Write(simplePrettify)
	
	quit kpi
}

Method generateFilterMethod(ByRef sc As %Status) As %Dictionary.MethodDefinition
{
	set sc =  $$$OK
	set fullName = ..config.packageName_"."_..config.className

	set method = ##class(%Dictionary.MethodDefinition).%New(fullName_":%OnGetSQL")
	set method.ReturnType = "%Status"
	set method.FormalSpec = "&pSQL:%String"
	set method.Description = "Return an SQL statement to execute."

	set implementation = ""
	if (..filters.Count() > 0) {
		set tSql = $zconvert(..query, "l")
		set parsed = $$$YES
		set diffPart = ""
		set where = $$$NO
		
		if (..isSingleInString(tSql,"select ")) {
			if ($find(tSql,"where ")) {
				if (..isSingleInString(tSql,"where ")) {
					set diffPart = "	set tSql = $zconvert(pSQL,""l"")"_$char(10)
								 _ "	set tPos = $find(tSql,""where "")-1"
					set where = $$$YES
				} else {
					set parsed = $$$NO
				}
				
			} elseIf ($find(tSql,"group by ")) {
				if (..isSingleInString(tSql,"group by ")) {
					set diffPart = "	set tSql = $zconvert(pSQL,""l"")"_$char(10)
								 _ "	set tPos = $find(tSql,""group by "")-$length(""group by "")-1"
				} else {
					set parsed = $$$NO
				}
				
			} elseIf ($find(tSql,"order by ")) {
				if (..isSingleInString(tSql,"order by ")) {
					set diffPart = "	set tSql = $zconvert(pSQL,""l"")"_$char(10)
								 _ "	set tPos = $find(tSql,""order by "")-$length(""order by "")-1"
				} else {
					set parsed = $$$NO
				}
				
			} else {
				set diffPart =     "	set pSQL = pSQL_"" """_$char(10)
							 _     "	set tPos = $length(pSQL)"
			}
		} else {
			set parsed = $$$NO
		}
		
		if (parsed) {
			set implementation = implementation_$char(10)_diffPart_$char(10)
							 _     "	if $isObject(..%filterValues) {"_$char(10)
							 _     "		set tWHERE = """""
		
			for i=1:1:..filters.Count() {
				set implementation = implementation_$char(10)
								 _ "		if (..%filterValues."""_..filters.GetAt(i).name_""" '= """") {"_$char(10)
								 _ "			set tWHERE = tWHERE _ $select(tWHERE="""":"""",1:"" AND "") _ ..%GetSQLForFilter("""_..filters.GetAt(i).filterProperty_""","""_..filters.GetAt(i).name_""")"_$char(10)
								 _ "		}"
			}
			
			set implementation = implementation_$char(10)
								 _ "		if (tWHERE '= """") {"
			if (where) {
				set implementation = implementation_$char(10)
								 _ "			set tWHERE = "" ""_tWHERE_"" AND """
			} else {
				set implementation = implementation_$char(10)
								 _ "			set tWHERE = "" WHERE ""_tWHERE_"" """
			}
			
			set implementation = implementation_$char(10)
								 _ "			set $extract(pSQL,tPos) = tWHERE"_$char(10)
								 _ "		}"_$char(10)
								 _ "	}"
			
		} else {
			set implementation = " quit $$$ERROR(5001, ""We can not parse your query to apply filters. "
			_"Please implement filtering yourself."")"
		}
	}
	set implementation = implementation_$char(10)_"	quit $$$OK"
	
	do method.Implementation.Write(implementation)

	quit method
}

ClassMethod isSingleInString(string As %String, substring As %String) As %Boolean
{
	set tPos1 = $find(string, substring)
	set tPos2 = $length(string) + $length(substring) + 2 - $find($reverse(string),$reverse(substring))
	
	if tPos1 = tPos2 {quit $$$YES}
	else {quit $$$NO}
}

}

