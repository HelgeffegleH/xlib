class xlib {
	static projectName:="xlib"
	static extendedExceptionInfo:=true
	
	#include xinclude\error.ahk									;	Error handling
	#include xinclude\misc.ahk                                  ;	Misc functions
	#include xinclude\malloc.ahk                                ;	Memory allocation and freeing
	#include xinclude\core.ahk                                  ;	Core api wrapper
	#include xinclude\poolbase.ahk                              ;	Pool structure object wrappers
	#include xinclude\ccore.ahk                                 ;	Compiled core functions. Script callbacks
		                                                        ;
																;	Primitive data type handling, Types are the "regular" dllcall types, char, short, int, ptr, ...
	#include xinclude\typeArr.ahk                               ;	"Type" array implementation. 
	#include xinclude\type.ahk                                  ;	Single type value objects.
	#include xinclude\struct.ahk                                ;	Struct builder.
	
	#include xinclude\ui.ahk                                    ;	ui - User interface - object wrappers around the above, intended for direct use.
	
}
