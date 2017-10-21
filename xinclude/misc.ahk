;<< Error handling >>
exception(msg:="",r:="",depth:=0, legacyParameter_1:="",legacyParameter_2:=""){
	; This looks wierd, it has been changed, it was convenient to keep this format	
	throw new xlib.error(msg,r,depth,"obj") ; Might just change to throw here.
}
getEnvironmentVersion(){
	; Used by core\initializeThreadpoolEnvironment
	; Used by core\setThreadpoolCallbackPriority	
	local OS := xlib.getOsVersion() ; major.minor
	if OS < 6.0			; Older than windows vista
		xlib.exception(OS . " not supported for thread pools, minimum OS is Windows Vista. ( 6.0 ) ")
	else if OS >= 6.1	; Newer or equal to win7
		return 3
	return 1			; Windows vista	
}

getOsVersion(major:=true, minor:=true, build:=false){
	/*
	Url:
		- https://msdn.microsoft.com/en-us/library/windows/desktop/ms724832(v=vs.85).aspx (Operating System Version)
	Operating system				Version number
	Windows 10						10.0*
	Windows Server 2016				10.0*
	Windows 8.1						6.3*
	Windows Server 2012 R2			6.3*
	Windows 8						6.2
	Windows Server 2012				6.2
	Windows 7						6.1
	Windows Server 2008 R2			6.1
	Windows Server 2008				6.0
	Windows Vista					6.0
	Windows Server 2003 R2			5.2
	Windows Server 2003				5.2
	Windows XP 64-Bit Edition		5.2
	Windows XP						5.1
	Windows 2000					5.0
	*/
	static OS := strSplit(A_OSVersion,".")
	return 	 	(major ? OS.1 : "")
			.	(minor ? OS.2 : "")
			.	(build ? OS.3 : "")
}

verifyCallback(callbackFunction){
	if callbackFunction == ""
		return
	if !IsFunc(callbackFunction) && type(callbackFunction)!="BoundFunc"	; It is not a func object, a function name or a bound func, error
		xlib.exception(A_ThisFunc " failed, invalid callbackFunction",,-2)
	if !IsObject(callbackFunction) ; It is a function name. Make func object.
		callbackFunction:=func(callbackFunction)
	return callbackFunction
}