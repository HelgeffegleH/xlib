;<< Error handling >>
exception(msg:="",r:="",depth:=0, legacyParameter_1:="",legacyParameter_2:=""){
	; This looks wierd, it has been changed, it was convenient to keep this format	
	throw new xlib.error(msg,r,depth,"obj") ; Might just change to throw here.
}
getVersion(){
	; Used by core\initializeThreadpoolEnvironment
	static unsupportedOs:="WIN_2003,WIN_XP,WIN_2000"
	if inStr(unsupportedOs,A_OSVersion)
		xlib.exception(A_OSVersion " not supported for thread pools, minimum OS is Windows Vista.")
	else if A_OSVersion="WIN_VISTA"
		return 1
	return 3
}
verifyCallback(callbackFunction){
	if callbackFunction == ""
		return
	if !IsFunc(callbackFunction) && type(callbackFunction)!="BoundFunc"		; It is not a func object, a function name or a bound func, error
		xlib.exception(A_ThisFunc " failed, invalid callbackFunction",,-2)
	if !IsObject(callbackFunction) ; It is a function name. Make func object.
		callbackFunction:=func(callbackFunction)
	return callbackFunction
}