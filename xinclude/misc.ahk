;<< Error handling >>
exception(msg:="",r:="",depth:=0, legacyParameter_1:="",legacyParameter_2:=""){
	; This looks wierd, it has been changed, it was convenient to keep this format	
	throw new xlib.error(msg,r,depth,"obj") ; Might just change to throw here.
}
getEnvironmentVersion(){
	; Used by core\initializeThreadpoolEnvironment
	; Used by core\setThreadpoolCallbackPriority	
	local OS := xlib.getOsVersion() ; major.minor
	if OS < 6.0
		xlib.exception(OS . " not supported for thread pools, minimum OS is Windows Vista. ( 6.0 ) ")
	else if OS > 6.1
		return 3
	return 1
}

getOsVersion(major:=true, minor:=true, build:=false){
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