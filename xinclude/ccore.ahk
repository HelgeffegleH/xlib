; Compiled functions
class ccore{
	taskCallbackBin(){
		; Used by taskHandler. For callback on user task complete. See task.ahk
		; source: see taskCallback.c
		local k, i, raw
		static flProtect:=0x40, flAllocationType:=0x1000 ; PAGE_EXECUTE_READWRITE ; MEM_COMMIT	
		static raw32:=[]
		static raw64:=[3968026707,25905184,1221298504,4278732939,676563728,273386312,138644296,541821772,407079756,549749576,3774826587,2425393296]
		static bin:=xlib.ccore.taskCallbackBin()
		if !bin {
			bin:=xlib.mem.virtualAlloc((raw:=A_PtrSize==4?raw32:raw64).length()*4,flProtect,flAllocationType)
			for k, i in raw
				NumPut(i,bin+(k-1)*4,"Int")
			raw32:="",raw64:=""
		}
		return bin
	}
}