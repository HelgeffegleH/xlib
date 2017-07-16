
class xlib {
	static projectName:="xlib"
	;<< includes >>
	#include xinclude\misc.ahk
	#include xinclude\core.ahk
	#include xinclude\error.ahk
	#include xinclude\malloc.ahk
	#include xinclude\typeArr.ahk
	#include xinclude\type.ahk
	#include xinclude\struct.ahk
	#include xinclude\ui.ahk
	getClassPath(){
		return RegExReplace(this.__Class,"(.*)(\..*)","$1")
	}
}
