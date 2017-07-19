; Todo, 	
;		use threadFunc for callbacks. see note in task.ahk
;		cleanUpFn for "type"			
;		Much more
class xlib {
	static projectName:="xlib"
	static extendedExceptionInfo:=true
	;<< includes >>
	#include xinclude\error.ahk
	#include xinclude\misc.ahk
	#include xinclude\malloc.ahk
	#include xinclude\core.ahk
	#include xinclude\ccore.ahk
		
	#include xinclude\typeArr.ahk
	#include xinclude\type.ahk
	#include xinclude\struct.ahk
	#include xinclude\ui.ahk
	getClassPath(){
		return RegExReplace(this.__Class,"(.*)(\..*)","$1")
	}
}
