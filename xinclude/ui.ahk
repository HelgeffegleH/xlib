class ui {
	; User classes and methods.
	
	
	#include task.ahk	; For "manual" thread handling.
	#include pool.ahk	; For thread pooling.
	
	; Misc user methods
	getFnPtrFromLib(lib,fn,suffixWA:=false,free:=false){
		; lib, path to the library  / dll where the function resides
		; fn, name of the function.
		;	  suffixWA, if false (0) the fn name is not suffixed with W or  A  depending  on
		; 	  A_IsUnicode,  if  true (1) the fn name is always suffixed, if this parameter is
		; 	  (-1), the fn name is suffixed if the first attempt to get the address fails.
		local dll, fnPtr
		if IsObject(lib)
			dll:=lib[1]
		if !dll
			dll:=DllCall("Kernel32.dll\LoadLibrary", "Str", lib, "Ptr")
		if !dll
			xlib.exception("Failed to load library: " lib,,-1)
		if (suffixWA==1)
			fn.= A_IsUnicode ? "W" : "A"
		fnPtr:=DllCall("Kernel32.dll\GetProcAddress", "Ptr", dll, "AStr", fn, "Ptr")
		if (!fnPtr && suffixWA==-1)
			fnPtr:=DllCall("Kernel32.dll\GetProcAddress", "Ptr", dll, "AStr", fn . (A_IsUnicode ? "W" : "A"), "Ptr")
		if !fnPtr
			xlib.exception("Failed to get procedure address: " fn,,-1)
		if free ; This is probably not wanted.
			this.freeLibrary(dll)
		return fnPtr
	}
	freeLibrary(lib){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms683152(v=vs.85).aspx FreeLibrary function
		; Notes:
		;	If the function succeeds, the return value is nonzero.
		if !DllCall("Kernel32.dll\FreeLibrary", "Ptr", lib)
			xlib.exception("Free library failed for: " lib,,-2)
		return 1
	}
	setMemoryReadOnly(ptr,size){
		; Returns previous memory settings and set new to PAGE_READONLY
		static PAGE_READONLY:=0x02
		return xlib.mem.virtualProtect(ptr,size,PAGE_READONLY)
	}
}