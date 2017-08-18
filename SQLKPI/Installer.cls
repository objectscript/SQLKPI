Class SQLKPI.Installer
{

XData Install [ XMLNamespace = INSTALLER ]
{
<Manifest>
	<IfNotDef Var="Namespace">
	<Var Name="Namespace" Value="SQLKPI"/>
	<Log Text="Set namespace to ${Namespace}" Level="0"/>
	</IfNotDef>
	
	<If Condition='(##class(Config.Namespaces).Exists("${Namespace}")=0)'>
        <Log Text="Creating namespace ${Namespace}" Level="0"/>
        <Namespace Name="${Namespace}" Create="yes" Code="${Namespace}" Ensemble="0" Data="${Namespace}">
            <Configuration>
                <Database Name="${Namespace}" Dir="${MGRDIR}${Namespace}" Create="yes"/>
            </Configuration>
        </Namespace>
        <Log Text="End Creating namespace ${Namespace}" Level="0"/>
    </If>
    
    <Role Name="SQLKPIRole" Description="Role to access and use the SQLKPI" Resources="%DB_CACHESYS:RW,%Admin_Secure:U" />
    <Namespace Name="${Namespace}" Create="no">
    	<RunInstall Class="SQLKPI.Installer" Method="CopyClasses"/>
        <RunInstall Class="SQLKPI.Installer" Method="CreateApplication"/>
        <CSPApplication Url="/csp/sqlkpi" Recurse="1" Directory="${CSPDIR}sqlkpi" AuthenticationMethods="64" IsNamespaceDefault="true" Grant="AppRole" />
        <Log Text="Copying web application files" Level="0"/>
        <RunInstall Class="SQLKPI.Installer" Method="CopyFiles"/>  
   </Namespace>
   
   <If Condition='(##class(Config.Namespaces).Exists("%All")=0)'>
        <Log Text="Creating namespace %All" Level="0"/>
        <Namespace Name="%All" Create="yes" Code="CACHETEMP" Data="CACHETEMP" Ensemble="0">
            <Configuration>
                <Log Text="Mapping SQLKPI package to %All namespace" Level="0"/>
                <ClassMapping From="${Namespace}" Package="SQLKPI"/>
            </Configuration>
        </Namespace>
    </If>
    
    <If Condition='(##class(Config.Namespaces).Exists("%All")=1)'>
        <Namespace Name="%All" Create="no" Code="CACHETEMP" Data="CACHETEMP" Ensemble="0">
            <Configuration>
                <Log Text="Mapping package SQLKPI to %All namespace" Level="0"/>
                <ClassMapping From="${Namespace}" Package="SQLKPI"/>
            </Configuration>
        </Namespace>
    </If>
    
    
    <Log Text="Mapping SQLKPI package to Samples namespace" Level="0"/>
    <If Condition='##class(Config.Namespaces).Exists("Samples")'>
        <Namespace Name="Samples" Create="no" Code="SAMPLES" Data="SAMPLES" Ensemble="0">
            <Configuration>
                <ClassMapping From="${Namespace}" Package="SQLKPI"/>
            </Configuration>
        </Namespace>
    </If>
	</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 0, pInstaller As %Installer.Installer) As %Status [ CodeMode = objectgenerator, Internal ]
{
    Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Install")
}

ClassMethod CreateApplication(pVars, pLogLevel, tInstaller)
{
	set Namespace = tInstaller.Evaluate("${Namespace}")
	do tInstaller.PushNS("%SYS")
	if ('##class(Security.Applications).Exists("/sqlkpi")) {
		set cspProperties("NameSpace") = Namespace
		set cspProperties("AutheEnabled") = $$$AutheCache
		set cspProperties("IsNameSpaceDefault") = $$$NO
		set cspProperties("DispatchClass") = "SQLKPI.REST"
		set cspProperties("GroupById") = "sqlkpi"
		set cspProperties("MatchRoles") = ":SQLKPIRole"
		set cspProperties("CookiePath") = "/"
		
		set tSC = ##class(Security.Applications).Create("/sqlkpi", .cspProperties)
		if $$$ISERR(tSC) throw ##class(%Installer.Exception).CreateFromStatus(tSC)
		kill cspProperties
	}
	
	do tInstaller.PopNS()
	
	quit $$$OK
}

ClassMethod CopyClasses(pVars, pLogLevel, tInstaller)
{
	set sc = $$$OK
	
	set i = 0
	while 1 {
		set id = "SQLKPI.CLSData||File" _ i
		if (##class(%Dictionary.CompiledXData).%ExistsId(id) = 0) Q		
		set class = ##class(%Dictionary.CompiledXData).%OpenId(id)
		set data = $zconvert(class.Data.Read(class.Data.Size), "O", "UTF8")
		set className = "SQLKPI."_$piece(class.Description,".",1)
		
		set Namespace = tInstaller.Evaluate("${Namespace}")
		do tInstaller.PushNS(Namespace)
		
		if ('##class(%Dictionary.ClassDefinition).%ExistsId(className)) {
			set clsDef = ##class(%Dictionary.ClassDefinition).%New()
			set clsDef.Name = className
			set sc = clsDef.%Save()
			quit:$$$ISERR(sc) 
		}
		set sc = ##class(%Compiler.UDL.TextServices).SetTextFromString(,className,$System.Encryption.Base64Decode(data))
		do $system.OBJ.Compile(className, "cuk")
		
		do tInstaller.PopNS()
		
		set i = i + 1
	}
	
	quit $$$OK
}

ClassMethod CopyFiles(pVars, pLogLevel, tInstaller)
{
	set csp = tInstaller.Evaluate("${CSPDIR}")
	set path = ##class(%File).NormalizeDirectory(csp _ "sqlkpi")	
	
	// Get path separator
	set r = ##class(%File).NormalizeDirectory("\")
	if ($find(r, "/") = 0) { 
		set r = "\"
	} else {
		 set r = "/"
	}
	
	set i = 0
	while 1 {
		set id = "SQLKPI.CSPData||File" _ i		
		if (##class(%Dictionary.CompiledXData).%ExistsId(id) = 0) Q		
		set file = ##class(%Dictionary.CompiledXData).%OpenId(id)
		
		set data = $zconvert(file.Data.Read(file.Data.Size), "O", "UTF8")
		set fileName = ##class(%File).NormalizeFilename(path _ file.Description)
		
		
		set fileName = $replace(fileName, "\", r)
		set fileName = $replace(fileName, "/", r)
		set dir = ##class(%File).ParentDirectoryName(fileName)
		if ('##class(%File).DirectoryExists(dir)) {
			do ##class(%File).CreateDirectory(dir)
		}
		
		do tInstaller.Log(pLogLevel, "Creating file", fileName)
		
		
		set f = ##class(%Stream.FileBinary).%New()
    	do f.LinkToFile(fileName)
    	do f.Write($System.Encryption.Base64Decode(data))
    	do f.%Save()
				
		set i = i + 1
	}
	
	quit $$$OK
}

}

