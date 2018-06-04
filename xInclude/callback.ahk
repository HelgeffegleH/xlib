class callback {
	; Creates a 'compiled' callback function which can be passed to a threadHandler or pool object.
	; See jit.ahk for details.
	__new(fn, decl*){
		; fn, the function to call, an address, or [dll]\FuncName. Note: PATH\dllFile.dll\FuncName not supported, load manually and pass address instead.
		; decl, paramter types and return type and calling convention, eg, "int", "ptr", ..., "cdecl ptr"
		local
		global xlib
		this.fn := this.getFn(fn)				; Get the function from string.
		this.bin := new xlib.jitFn(decl, rt)	; Compiles the function which will call fn
		this.decl := decl						; Stores decl for correct parameter passing and return retrieval
		this.o := this.setupOffsetArray(decl)	; parameter offset array
		this.rt := rt							; return type
	}
	getFn(fn){	; Either finds a function pointer from string or if fn is an address it just returns the address.
		local
		global xlib
		if type(fn) == "String" {	
			fn := strsplit(fn, ["\", "/"])
			if fn.length() == 2
				fn := xlib.ui.getFnPtrFromLib(fn.1, fn.2, -1)	; Dll file specified
			else
				fn := xlib.ui.getFnPtrFromLib(, fn.1, -1)		; Dll file omitted
		} ; else implies fn is a pointer
		if type(fn) != "Integer" || !fn
			xlib.exception(A_ThisFunc " failed, fn: " fn)
		return fn
	}
	setupOffsetArray(decl){
		; Builds an array of offsets for the parameters. In 32 bits each parameter offset is an multiple of 4, on 64 bit it is a multiple of 8 (bytes)
		
		static ofn := 	a_ptrsize == 8											; offset function.
						? (type) => 8 											; 64 bit functions takes 8 bytes per param
						: (type) => ( xlib.type.sizeof(type) == 8 ? 8 : 4 ) 	; 32 bit functions takes 4 bytes except for int64 and double
		local
		global xlib
		o := {0:0}	; offset of each parameter in the parameter array. First param is at offset 0, second param is at offset 0+ofn(param1)...
		
		for k, type in decl
			o[k] := o[k-1] + ofn.call(type)			; each iteration moves the offset ofn(type) bytes forward. Hence, param k+1 is at o[k]+ofn(paramk).
		this.paramSize := ceiln( o[o.maxindex()] )	; This is probably not needed, investigate.
		return o
		;
		;	Nested function
		;
		ceiln(x){
			; rounds up to a multiple of a_ptrsize
			return  ceil(x/a_ptrsize)*a_ptrsize
		}
	}
	
	callId := 0			; Each call has an id
	paramCache := []	; Stores all outstanding parameters at callId
	retCache := []		; -- "" -- for returns
	
	setupCall(params*){
		; Writes all parameters to memory and setup return address.
		local
		global xlib
		callId := this.callId++ ; In case of interruptions
		this.paramCache.setCapacity( callId, this.paramSize )
		, p := this.paramCache.getAddress( callId )					; pointer to params
		, o := this.o												; offsets, zero based index
		, d := this.decl											; decl, types
		
		for k, par in params										; Write parameters to memory
			numput( par, p, o[k-1], d[k] )
		
		this.retCache.setCapacity( callId, 8 )						; All returns are 8 bytes
		r := this.retCache.getAddress( callId )						; return pointer
		
		;
		; This struct is passed to the callback (new thread)
		; It contains a pointer to the work function, its parameters
		; and a pointer to store the return value from the function.
		;
		static structSize := 3 * A_PtrSize
		
		; Set up clean up function for releasing memory when the pv struct is released.
		; => is a closure.
		paramCache	:= this.paramCache	; free variables
		retCache 	:= this.retCache    ;
		cleanUpFn :=   ( struct ) => ( paramCache.delete(callId), retCache.delete(callId) ) ; xlib.struct passes this (it self) when it calls the clean up function.
		
		pv := new xlib.struct( structSize,  cleanUpFn, a_thisfunc . " ( pv )") ; name the struct 'a_thisfunc ( pv )' for db purposes.
		pv.build(	 
					["ptr",	this.fn,	"fn"],
					["ptr",	p, 			"params"],
					["ptr",	r,			"ret"]
				)
		
		return [pv, callId]
	}
	; Object to store and get result from. 
	class resObj {
		__new(pargs, o, decl, ret, max){
			; input, free vars.
			; pargs,	pointer to arguments passed by user.
			; o,		offsets of arguments.
			; decl,		the function declaration, for correct types.
			; ret,		the return value.
			; max,		the max index for k parameter of __get
			local
			return	{ base : { __get : func("__get"), __class : "resObj" } }
			__get(this, k := 0, derf*) { ; closure
				; k parameter number to retreive, omit to fetch the return, eg return := res[]
				; derf, dereference the parameter to this type. Eg, if parameter k is a pointer to a pointer to a 'string', str := res[k, "ptr", "str"]
				global xlib
				if type(k) != "Integer"
					xlib.exception("Invalid type, must be integer, got:"  . type(k))
				if k == 0
					r := ret
				else if  k > 0 && k <= max
					r := numget(pargs, o[k-1], decl[k])
				else
					xlib.exception("Index out of bounds: " . string(k) . " ( 0 - " . string(max) . " )")
				if derf {
					stop := false	; Needs to stop after "str" since remaining values in the array derf are strget params.
					for k, type in derf
						r := instr(type, "str") ? (stop := true , strget( getStrGetParams(derf, k+1, r)* ))	; str
												: numget(r, type)											; number
					until stop
				}
				return r
				; Nested function
				getStrGetParams(arr, ind, strPtr){	; When type is "str", the remaining parameter can be parameters for strget, eg, ret[k, "str", length := 32, encoding := "UTF-8"]
					local
					ret := [strPtr]					; First param for strget is the address.
					while arr.haskey(ind)			; Maximum two iterations else error.
						ret.push arr[ind++]
						
					return ret
				}
			}
		}
	}
}