﻿#include <xlib>
#include <xcall>

xDllCall(callback, fn, typesAndArgs*){
	local
	global xlib, xcall
	; callback, user defined script function to call when the function fn (see next param) returns.
	; fn, the function to call, DllFile\Function
	; typesAndArgs, optional [Type1, Arg1, Type2, Arg2, ..., TypeN, ArgN, "Cdecl ReturnType]
	xlib.splitTypesAndArgs typesAndArgs, decl, params 	; decl and params are byref
	(new xcall(fn, decl*)).call(callback, params*)
}
