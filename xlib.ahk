class xlib {

	#include xinclude\error.ahk						;	Error message formatting
	#include xinclude\constants.ahk					;	Constants
	#include xinclude\bases.ahk						;	Common base objects
	#include xinclude\misc.ahk                      ;	Misc functions
	#include xinclude\malloc.ahk                    ;	Memory allocation and freeing
	#include xinclude\core.ahk                      ;	Core api wrapper
	#include xinclude\poolbase.ahk                  ;	Pool structure object wrappers
	#include xinclude\poolCallback.ahk              ;	Pool callback
	#include xinclude\ccore.ahk                     ;	Compiled core functions. Script callbacks
	                                                
	#include xinclude\jit.ahk						;	Primitive just-in-time compiler
	#include xinclude\callback.ahk					; 	Creates a thread callback function
	                                                
													;	Primitive data type handling, Types are the "regular" dllcall types, char, short, int, ptr, ...
	#include xinclude\typeArr.ahk                   ;	"Type" array implementation. 
	#include xinclude\type.ahk                      ;	Single type value objects.
	#include xinclude\struct.ahk                    ;	Struct builder.
	                                                
	#include xinclude\ui.ahk                        ;	ui - User interface - object wrappers around the above, intended for direct use. Misc user functions.
	
}