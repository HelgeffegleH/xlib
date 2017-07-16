; Available types:
;	UInt, Int, Int64, Short, UShort, Char, UChar, Double, Float, Ptr or UPtr, strbuf
; example:
; myChar:= new char(37)
; Specify a memory address for ptr for custom memory allocation, will not be free automatically. "Caller" frees.
; Otherwise, memory is allocated and freed when last reference to the type object is released, eg, myChar:=""
;<< double >>

;<< float >>
class float extends xlib.type {
	min:="-inf"
	max:="inf"
	__new(val,ptr:="",type:="float"){
		base.__new(val,type,ptr)
	}
	outOfBounds(val){
		static oobTest
		if !oobTest
			VarSetCapacity(oobTest,this.size,0)
		NumPut(val,oobTest,this.type)
		return InStr(NumGet(oobTest,this.type),"inf") || InStr(val,"nan")
	}
	outOfBoundsException(val){
		throw Exception("Value out of bounds: " val,-2)
	}
}

class double extends xlib.float {
	__new(val,ptr:=""){
		base.__new(val,ptr,"double")
	}
}
;<< uptr >>
class uptr extends xlib.type{
	min:=A_PtrSize=4 ? 			 0 : -9223372036854775808
	max:=A_PtrSize=4 ? -4294967296 :  9223372036854775807
	__new(val,ptr:=""){
		base.__new(val,"Uptr",ptr)
	}
}
;<< ptr >>
class ptr extends xlib.type{
	min:=A_PtrSize=4 ? -2147483648 : -9223372036854775808
	max:=A_PtrSize=4 ? -2147483647 :  9223372036854775807
	__new(val,ptr:=""){
		base.__new(val,"Ptr",ptr)
	}
}
;<< int64 >>
class int64 extends xlib.type{
	min:=-9223372036854775808
	max:=9223372036854775807
	__new(val,ptr:=""){
		base.__new(val,"int64",ptr)
	}
}
;<< uint >>
class uint extends xlib.type{
	min:=0
	max:=4294967295
	__new(val,ptr:=""){
		base.__new(val,"Uint",ptr)
	}
}
;<< int >>
class int extends xlib.type{
	min:=-2147483648
	max:=2147483647
	__new(val,ptr:=""){
		base.__new(val,"Int",ptr)
	}
}
;<< ushort >>
class ushort extends xlib.type{
	min:=0
	max:=65535
	__new(val,ptr:=""){
		base.__new(val,"Ushort",ptr)
	}
}
;<< short >>
class short extends xlib.type{
	min:=-32768
	max:=32767
	__new(val,ptr:=""){
		base.__new(val,"Short",ptr)
	}
}
;<< uchar >>
class uchar extends xlib.type {
	min:=0
	max:=255
	__new(val,ptr:=""){
		base.__new(val,"Uchar",ptr)
	}
}
;<< char >>
class char extends xlib.type {
	min:=-128
	max:=127
	__new(val,ptr:=""){
		base.__new(val,"Char",ptr)
	}
}
;<< strbuf >>
class strbuf extends xlib.type{
	; specify len, the maximum string length that the buffer can hold for the specified encoding, enc. Null terminator excluded.
	__new(len,enc:=""){
		this.len:=len
		this.size:=(len+1)*(enc="utf-16" || enc="cp1200" ? 2 : 1) ; Deduced from the manual. 
		this.ptr:=this.parentClass.mem.globalAlloc(this.size)
		this.enc:=enc
	}
	str{
		get{
			return StrGet(this.ptr+0,this.enc)
		}
		set{
			if this.outOfBounds(value)
				this.outOfBoundsException(value)
			StrPut(value,this.ptr+0,this.enc)
		}
	}
	val{
		set{
			this.str:=value
		}
		get{
			return this.str
		}
	}
	outOfBoundsException(value){
		this.parentClass.exception("String to long: " strlen(value) ". Maximum length: " this.len,,-2)
	}
	outOfBounds(val){
		return (StrLen(val)+1) * (this.enc="utf-16" || this.enc="cp1200" ? 2 : 1)  > this.size
	}
}
;<< type >>
class type {
	static parentClass:=xlib
	__new(val,type,ptr:=""){
		if !(this.size:=this.sizeof(type))
			this.parentClass.exception("Invalid type: " type)
		this.ptr:= ptr ? ptr : this.parentClass.mem.globalAlloc(this.size)
		this.isStructMember:= ptr ? true : false
		this.type:=type
		this.val:=val
	}
	outOfBounds(num){
		return num<this.min || num>this.max
	}
	__Delete(){
		if !this.isStructMember	; Structs free their members.
			this.parentClass.mem.globalFree(this.ptr)
	}
	pointer {	; The pointer to the memory space
		set{
			this.parentClass.exception("Access denied.",,-2)
		}
		get{
			return this.ptr
		}
	}
	; Max / min values of the type.
	max{	
		set{
			this.ub:=value
		}
		get{
			if (this.ub="")
				this.parentClass.exception("Maximum value not defined for: " this.type,,-2)
			return this.ub
		}
	}
	min{
		set{
			this.lb:=value
		}
		get{
			if (this.lb="")
				this.parentClass.exception("Minimum value not defined for: " this.type,,-2)
			return this.lb
		}
	}
	val{ ; The value. Get it by myRef.val, set via myRef.val:=...
		set{
			if this.outOfBounds(value)
				this.outOfBoundsException(value)
			return NumPut(value,this.ptr+0,this.type)
		}
		get{
			local value:=NumGet(this.ptr+0,this.type)
			if this.outOfBounds(value)
				this.outOfBoundsException(value)
			return value
		}
	}
	outOfBoundsException(val){ ; Standart error message
		throw Exception("Value out of bounds: " val ". Expected value in range [" this.min "," this.max "]",-2)
	}
	sizeof(type){
		static sizeMap:={Ptr:A_PtrSize,Uptr:A_PtrSize,Uint:4,Int:4,Int64:8,Ushort:2,Short:2,Uchar:1,Char:1,Float:4,Double:8}
		if !sizeMap.haskey(type)
			this.parentClass.exception("Invalid type: " type ".",,-2)
		return sizeMap[type]
	}
	
}

class FILETIME {
	; Very much unverified
	; Url:
	;	- https://https://msdn.microsoft.com/en-us/library/windows/desktop/ms724284(v=vs.85).aspx (FILETIME structure)
	/*
	typedef struct _FILETIME {
		DWORD dwLowDateTime;
		DWORD dwHighDateTime;
	} FILETIME, *PFILETIME;
	*/
	static parentClass:=xlib
	__new(time:=0,low:="",high:=""){
		this.mem:=this.parentClass.mem.globalAlloc(8)
		if (low!="" && high!=""){
			this.dwLowDateTime:=low
			this.dwHighDateTime:=high
		} else if (time!="") {
			this.time:=time
		}
	}
	pointer{
		get{
			return this.mem
		}
	}
	time{
		set{
			this.dwLowDateTime	:= value << 32 >> 32
			this.dwHighDateTime	:= value >> 32 		
		}
		get{
			return NumGet(this.mem+0, 0, "Int64")
		}
	}
	low{ ; cannot remember full names
		set{
			this.dwLowDateTime:=value
		}
		get{
			return this.dwLowDateTime
		}
	}
	high{
		set{
			this.dwHighDateTime:=value
		}
		get{
			return this.dwHighDateTime
		}
	}
	dwLowDateTime{
		set{
			NumPut(value,this.mem+0,0,"Uint")
			return 
		}
		get{
			return NumGet(this.mem+0,0,"Uint")
		}
	}
	dwHighDateTime{
		set{
			NumPut(value,this.mem+0,4,"Uint")
			return 
		}
		get{
			return NumGet(this.mem+0,4,"Uint")
		}
	}
	__Delete(){
		this.parentClass.mem.globalFree(this.mem)
	}
	; Misc, db purposes
	systemTimeToFileTime(lpSystemTime, ByRef lpFileTime){
		if !DllCall("Kernel32.dll\SystemTimeToFileTime", "Ptr", lpSystemTime, "Int64P", lpFileTime)
			this.parentClass.exception("SystemTimeToFileTime failed")
	}
	GetSystemTime(ByRef st){
		VarSetCapacity(st,16,0)
		DllCall("Kernel32.dll\GetSystemTime", "Ptr", &st)
	}
}