class taskHandler {
	static callbackMsgNumber:=0x5537
	;<< new >>
	__new(maxTasks:=8){
		this.maxTasks:=maxTasks
		this.initDataArrays()
		this.callbackFunctions:=[]
		this.callbackStructs:=[]
		this.stackSizes:=[]
		this.startOptions:=[]
		this.autoReleaseCallbackStructAfterCallback:=[] ; See autoReleaseCallbackStruct
	}
	getTask(ind){
		; Returns a an object on the form:
		; {pBin:pBin,pArgs:pArgs[,start:bool,stackSize:stackSize]}
		; where,
		;		pBin is a pointer to an executable binary buffer. Alocate memory with virtualAlloc()
		; 		pArgs is a pointer to the arguments which will be "passed to pBin"
		;		start, set to true to start the task when it is created.
		;		stackSize, size of the stack allocated for pBin, set to zero for default.
		; return -1 to indicate that all tasks are defined.
		throw Exception("getTask not implemented.",-1)
	}
	;<< note >>
	restartAllTasks(){
		; User should check that no threads are running before calling this methods. Exception on failure.
		local k, hThread
		if this.isAnyThreadRunning()		; Verify no threads still running. 
			xlib.exception("Cannot restart all tasks before all task finished.",,-1)	; This might be a bit harsh. Consider it.					<----- NOTE
		for k in this.binArr
			this.restartTask(k)
	}
	
	restartTask(ind){
		this.cleanUpThread(ind)
		if this.callback
			this.registerTaskCallback(this.binArr.Get(ind),this.argArr.Get(ind),this.callbackFunctions[ind],this.startOptions[ind],this.stackSizes[ind], ind) ; ind will indicate restart and serve as callbackNumber
		else
			this.createTask(this.binArr.Get(ind),this.argArr.Get(ind),this.startOptions[ind],this.stackSizes[ind], ind)
	}
	

	
	;<<Task methods>>
	registerTaskCallback(pBin,pArgs,callbackFunction,start:=true,stackSize:=0,restarting:=false){
		; "Return values" from task function pBin, should be put in pArgs
		; The callback function must accept two parameters, a reference to "this" and the callbackNumber returned by this function.
		; callbackFunction can be the name of a function, a func or boundFunc object.
		; Eg: myCallbackFunction(param1,...,callbackNumber, this){...}
		local pCb, callbackNumber
		if !restarting {
			callbackFunction:=this.verifyCallback(callbackFunction)
			callbackNumber:=this.callbackFunctions.Push(callbackFunction)
			this.makeCallbackStruct(pBin,pArgs,callbackNumber)
		} else {
			callbackNumber:=restarting
			start:=this.startOptions[callbackNumber]
			stackSize:=this.stackSizes[callbackNumber]
		}
		pCb:=xlib.ccore.taskCallbackBin()
		this.OnMessageReg()
		this.createTask(pCb,this.callbackStructs[callbackNumber].params.pointer,start,stackSize,restarting)
		return
	}

	createTask(pBin,pArgs,start:=true,stackSize:=0,restarting:=false){
		; pBin, pointer to binary buffer with 
		; pArgs, pointer to the arguments for the binary code
		; "Return values" from task function pBin, should be put in pArgs
		static CREATE_SUSPENDED:=0x00000004
		local threadData,ind
		if !restarting {
			this.stackSizes.push(stackSize)
			this.startOptions.Push(start)
			this.binArr.push(pBin)
			this.argArr.push(pArgs)
		} else {
			ind:=restarting
		}
		threadData := xlib.core.createThread(pBin, pArgs, 0, stackSize, start ? 0 : CREATE_SUSPENDED) ; For reference, threadData := {hThread:th,threadId:lpThreadId}
		if !restarting{
			this.thHArr.Push(threadData.hThread)
			this.tIdArr.Push(threadData.threadId)
		} else { ; FIX THIS
			msgbox("hi" threadData.hThread  "`n" threadData.threadId "`n" ind)
			this.thHArr.Set(ind,threadData.hThread)
			this.tIdArr.Set(ind,threadData.threadId)
		}
		return
	}
	startAllTasks(){
		local k, hThread
		if this.thHArr.getLength()
			for k, hThread in this.thHArr
				xlib.core.resumeThread(hThread)
		else
			xlib.exception("No thread handles available.",,-1,"Warn")
		return 
	}
	setTask(ind,pBin:="",pArgs:=""){
		; Sets new binary and or arguments for task ind.
		; Thread must not run while this method is called, exception is thrown.
		if this.isThreadRunning(ind)
			xlib.exception("Cannot set task when thread is still runngin.",,-1)
		if pBin!=""
			this.binArr.Set(ind,pBin)
		if pArgs!=""
			this.argArr.Set(ind,pArgs)
		this.updateCallbackStruct(this.binArr.Get(ind),this.argArr.Get(ind),ind)
		return
	}
	setCallback(ind,callback){
		callback:=this.verifyCallback(callback)
		this.callbackFunctions[ind]:=callback
	}
	startTask(ind){
		return xlib.core.resumeThread(this.thHArr.get(ind))
	}
	terminateAllThreads() {
		local k, th
		if this.thHArr.getLength()
			for k, tH in this.thHArr
				xlib.core.terminateThread(tH), xlib.code.closeHandle(tH)
		return
	}
	terminateTask(ind){
		local th
		if !th:=this.thHArr.get(ind)
			xlib.exception(A_ThisFunc " failed, no thread running for task: " ind,,-1)
		return xlib.core.terminateThread(tH)
	}
	autoReleaseAllCallbackStructs(bool:=true){
		; See autoReleaseAllCallbackStructs()
		loop this.maxTasks
			this.autoReleaseCallbackStructAfterCallback[A_Index]:=bool
	}
	autoReleaseCallbackStruct(callbackNumber, bool:=true){
		; Call this method for indicating wether to release the callback struct after the callback.
		; This is convenient when making new task as a local parameter and the returning without keeping a reference to task. The task will then be freed after the callback.
		; By default, structs are not released.
		; This should be called before starting the threads. Otherwise the callback might be recieved before this is set.
		this.autoReleaseCallbackStructAfterCallback[callbackNumber]:=bool
	}
	cleanUpThread(ind){
		; Close thread handle and delete handle and id.
		local hThread
		if hThread:=this.thHArr.Get(ind) {
			xlib.core.closeHandle(hThread)
			this.thHArr.Set(ind,0)
			this.tIdArr.Set(ind,0)
		}
		return
	}
	;<<Wait functions>>
		;waitForMultipleObjects(nCount, lpHandles, bWaitAll:=true, dwMilliseconds:=0xFFFFFFFF)
	waitForAllTasks(ms:=0xFFFFFFFF,waitForAll:=true){
		; Returns true if all tasks are done.
		; Return -1 if the wait times out.
		static WAIT_OBJECT_0:=	0x00000000
		static WAIT_TIMEOUT:=	0x00000102
		local r
		
		r:=xlib.core.waitForMultipleObjects(this.thHArr.getLength(), this.thHArr.getArrPtr(),waitForAll,ms)
		if !waitForAll
			return r ; Handle return in waitForAnyTask()
		if (r==WAIT_OBJECT_0)
			return true
		else if (r==WAIT_TIMEOUT)
			return -1
		xlib.exception("Unknown return from WaitForMultipleObjects.",[r],-1,"Warn","ExitApp")
	}
	waitForAnyTask(ms:=0xFFFFFFFF){
		; Returns the lowest task number of all tasks which have finished. (This is  the
		; zero-based  index  in the thHArr, add one to get based one index for user) 
		; Return -1 if the wait times out.
		static WAIT_TIMEOUT:=0x00000102
		local r
		r:=xlib.core.waitForAllTasks(ms,false)
		if (r==WAIT_TIMEOUT)
			return -1
		return r+1
	}
	waitForTask(ind,ms:=0xFFFFFFFF){
		; Returns true if all task is done.
		; Return -1 if the wait times out.
		static WAIT_OBJECT_0:=	0x00000000
		static WAIT_TIMEOUT:=	0x00000102
		local r
		r:=xlib.core.waitForSingleObject(this.thHArr.get(ind),ms)
		if (r==WAIT_OBJECT_0)
			return true
		else if (r==WAIT_TIMEOUT)
			return -1
		xlib.exception("Unknown return from WaitForSingleObject.",[r],-1,"Warn","ExitApp")
		return
	}
	areAllThreadsRunning(){
		return this.waitForAnyTask(0)	== -1 ? true : false		; This one,...
	}
	isAnyThreadRunning(){
		return this.waitForAllTasks(0)	== -1 ? true : false		; ..., and this one might seem swaped, but they are not.
	}
	isThreadRunning(ind){
		; Return true (1) if thread is running.
		; Return blank ("") if no thread handle available
		; Return false (0) if thread is not running.
		if !this.thHArr.Get(ind)
			return ""
		return this.waitForTask(ind,0) 	== -1 ? true : false
	}
	;<< notification methods >>
	notifyOnAllTaskComplete(callback,rate:=50){
		; Needs a compiled waiting thread for this one. (TODO)
		return
	}
	notifyOnTaskComplete(ind,callback,rate:=50){
		; This will probably not be needed due registerTaskCallback()
		return
	}
	; Task callback methods - internal use but fits best here.
	; Task Message handler
	callbackReciever(wParam, lParam, msg, hwnd){
		; wParam is the address to the object which requested the callback
		; lParam is the callback number of that object.
		;Critical()
		this:=Object(wParam)
		; Close thread handle here so it is done when user recieves the callback.
		this.cleanUpThread(lParam)
		if this.callbackFunctions.Haskey(lParam) 
			this.callbackFunctions[lParam].Call(lParam,this)	 ;<< note >> use threadFunc instead. To ensure the below is executed if the user function would throw an exception.
		if this.autoReleaseCallbackStructAfterCallback[lParam]
			this.callbackStructs[lParam]:=""	; this will decrement the reference count.
		return 0
	}
	OnMessageReg() {
		; Set up for recieving callback messages.
		;if xlib.ui.taskHandler.isRegistredForCallbacks
		;	return
		local msgFn
		msgFn:=xlib.ui.taskHandler.msgFn:=ObjBindMethod(xlib.ui.taskHandler,"callbackReciever")
		OnMessage(this.callbackMsgNumber, msgFn)
		xlib.ui.taskHandler.isRegistredForCallbacks:=true
	}
	makeCallbackStruct(pBin,pArgs,callbackNumber){
		/*
		see xlib.ccore.taskCallbackBin()
		size: A_PtrSize*2
		typedef struct udf	{					// User defined function and pointer to arguments
			udFn	pudFn;						// Function pointer of type udFn
			void* 	pParams;					// Pointer to arguments
		} *pudf;
		Size: A_PtrSize*5+4
		typedef struct params {
			pudf			userStruct;			// A struct on the form of udf 
			_PostMessage 	pPostMessage;		// For posting message to "calling thread".
			HWND 			hwnd;				// handle to the window which will recieve the msg.
			WPARAM 			wParam;				// "this" reference
			LPARAM 			lParam;				// callbackNumber
			unsigned int 	msg;				// message number
		} *pPar;
		*/
		static sizeOfudf:=A_PtrSize*2
		static sizeOfParams:=A_PtrSize*5+4
		static msgWin
		local pPostMessage, udf, params
		if !msgWin
			msgWin:=guiCreate()
		pPostMessage:=xlib.ui.getFnPtrFromLib("User32.dll","PostMessage",true)
		
		udf		:= new xlib.struct(sizeOfudf, 										, "taskCallbackUDF")
		params	:= new xlib.struct(sizeOfParams,	Func("ObjRelease").Bind(&this)	, "taskCallbackParams")
		
		; udf struct
		udf.build(	 ["Ptr",	pBin, 	"pudFn"		]									; Pointer to binary code.					
					,["Ptr",	pArgs,	"pParams"	])									; Pointer to arguments.
		; params struct	
		params.build(	 ["Ptr",	udf.pointer,			"userStruct"		]		; pointer to the user struct.
						,["Ptr",	pPostMessage,			"pPostMessage"		]		;
						,["Ptr",	msgWin.hwnd,			"hwnd"				]		; The mesage is posted to the msgWin window.
						,["Ptr",	&this,					"this"				]		; See callbackReciever.
						,["Ptr",	callbackNumber,			"callbackNumber"	]		; The threads index, internal.
						,["Uint",	this.callbackMsgNumber, "callbackMsgNumber"	])		; Defined at the top of this file.
						
		ObjAddRef(&this)	; Increment the reference count to ensure the object exists when the callback is recieved. See callbackReciever()
							; Needs to be released when the struct is deleted, hence Func("ObjRelease").Bind(&this) is used as clean up function for the struct.
		this.callbackStructs[callbackNumber]:={udf:udf,params:params}
		return
	}
	updateCallbackStruct(pBin,pArgs,callbackNumber){
		static sizeOfudf:=A_PtrSize*2
		local cbs
		cbs:=this.callbackStructs[callbackNumber] ; convenience.
		cbs.udf:= new xlib.struct(sizeOfudf, 	"taskCallbackUDF")
		cbs.udf.build(	 ["Ptr",	pBin, 	"pudFn"		]									; udf struct
						,["Ptr",	pArgs,	"pParams"	])
		cbs.params.Set("userStruct", cbs.udf.pointer)
		return
	}
	initDataArrays(restarting:=false){
		if !restarting{
			this.binArr:= new xlib.typeArr(this.maxTasks)	; User binary 		; Needed on restart.
			this.argArr:= new xlib.typeArr(this.maxTasks)	; and arguments.
		}
		this.thHArr:= new xlib.typeArr(this.maxTasks)		; thread handle array
		this.tIdArr:= new xlib.typeArr(this.maxTasks)		; thread id array
	}
	verifyCallback(callbackFunction){
		if !IsFunc(callbackFunction) && type(callbackFunction)!="BoundFunc"		; It is not a func object, a function name or a bound func, error
			xlib.exception(A_ThisFunc " failed, invalid callbackFunction",,-2)
		if !IsObject(callbackFunction) ; It is a function name. Make func object.
			callbackFunction:=func(callbackFunction)
		return callbackFunction
	}
	verifyInd(ind){
		local caller:=Exception("",-2).What
		if !this.indexInRange(ind,1,this.thHArr.getLength())
			xlib.exception("Invalid")
	}
}