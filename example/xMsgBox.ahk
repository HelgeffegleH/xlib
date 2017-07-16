#include ..\xlib.ahk
mb:= new xMsgBox(4,"MsgBox", "Hello world")
mb2:= new xMsgBox(48,"MsgBox", "Hello world 2",false)
ctr:=0
Loop
	ToolTip(A_TickCount), Sleep(10)
F1::mb2.show()
F2::
	
	Loop 6
		mb%A_Index% := new xMsgBox((Mod(A_Index,6)+1) | [0x10,0x20,0x30,0x40][mod(A_Index,4)+1], "MsgBox" A_Index+ctr, "Hello world" A_Index+ctr),ctr++
return
esc::exitapp
class xMsgBox extends xlib.ui.taskHandler {
	
	__new(Options:="", Title:="", Text:="",showOnCreate:=true){
		base.__new(1)
		this.options:=Options
		this.title:=Title
		this.text:=Text
		this.params:=this.makeParams()
		this.addTask(this.pmb,this.params.pointer,showOnCreate)
		this.init:=true
	}
	show(){
		if !this.init
			return
		this.startTask(1)
	}
	init(){
		return
	}
	makeParams(){
		static sizeOfMbStruct:= A_PtrSize*3+4
		/*
		typedef struct INOUTDATA {
			MsgBox mbFn;
			LPCTSTR lpText;
			LPCTSTR	lpCaption;
			unsigned int uType;
		}io, *pIO;
		*/
		local mbPtr, mbStruct
		mbPtr:=xlib.ui.getFnPtrFromLib("User32.Dll","MessageBox",true)
		mbStruct:= new xlib.struct(sizeOfMbStruct,"mbStruct")
		mbStruct.Build(  ["Ptr", mbPtr,						"mbFn"]
						,["Ptr", this.GetAddress("text"),	"lpText"]
						,["Ptr", this.GetAddress("title"),	"lpCaption"]
						,["Uint",this.options,				"uType"])
		return mbStruct
	}
	mbBin(){
		/* c source:
		#include <windef.h>
		typedef int __stdcall (*MsgBox)(HWND,LPCTSTR,LPCTSTR,UINT);

		typedef struct INOUTDATA {
			MsgBox mbFn;
			LPCTSTR lpText;
			LPCTSTR	lpCaption;
			unsigned int uType;
		}io, *pIO;
		int mb(pIO data){
			MsgBox mb=data->mbFn;
			int r = (*mb)(0,data->lpText,data->lpCaption, data->uType);
			return r;
		}
		*/
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/aa366887(v=vs.85).aspx 	(VirtualAlloc function)
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/aa366786(v=vs.85).aspx 	(Memory Protection Constants)
		local k, i, raw
		static flProtect:=0x40, flAllocationType:=0x1000 ; PAGE_EXECUTE_READWRITE ; MEM_COMMIT	
		static raw32:=[]
		static raw64:=[139561800,1140951880,1276660107,823148939,3774826697]
		bin:=DllCall("Kernel32.dll\VirtualAlloc", "Uptr",0, "Ptr", (raw:=A_PtrSize==4?raw32:raw64).length()*4, "Uint", flAllocationType, "Uint", flProtect, "Ptr")
		for k, i in raw
			NumPut(i,bin+(k-1)*4,"Int")
		return bin
	}
	static pmb:=xMsgBox.mbBin()
}