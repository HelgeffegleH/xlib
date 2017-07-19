;<<Clean up methods.>>
__Delete(){
	this.cleanUp()
}
cleanUp(){
	return 
}
;<< Error handling >>
exception(msg:="",r:="",depth:=0,cleanUp:=1,afterWarn:="return"){
	; Error handling, add error info and calls cleanUp if appropriate.
	; Set clean up to -1 to exit app. avoid calling cleanUp() if error is originating from cleanUp(). Then either cleanUp:="warn" or exitapp.
	local output
	cleanUp:=0 ; I think this will be the case.
	if (cleanUp==-1)
		Exitapp
	if (cleanUp==1)
		this.cleanUp()
	;output := cleanUp = "warn" ? "string" : "obj" ; style of the output, either string or object
	output:="obj"
	this.lastError:= new this.error(msg,r,depth,output) ; Might just change to throw here.
	/*
	if xlib.extendedExceptionInfo
		Msgbox(IsObject(this.lastError)? this.lastError.Message : this.lastError, "Extended error info.", 0x10)
	if this.mute
		Exit
	*/
	/*
	else if (cleanUp="warn"){
		MsgBox  "Warning",   this.lastError
									. (afterWarn="exit" ? "`n`nThe thread will exit." : (afterWarn="ExitApp"?"`n`nThe application will terminate.":""))
		if (afterWarn="exit")
			Exit
		else if (afterWarn="ExitApp")
			ExitApp
		return
	}
	*/
	throw this.lastError
}
getVersion(){
	; Used by core\initializeThreadpoolEnvironment
	static unsupportedOs:="WIN_2003,WIN_XP,WIN_2000"
	if inStr(unsupportedOs,A_OSVersion)
		this.error.exception(A_OSVersion " not supported for thread pools, minimum OS is Windows Vista.")
	else if (A_OSVersion="WIN_VISTA")
		return 1
	return 3
}