class taskHandler {
	static parentClass:=xlib.ui.parentClass ; I'm not really fond of this...
	;<< new >>
	__new(maxTasks:=8,mute:=false){
		this.maxTasks:=maxTasks
		this.mute:=mute
		this.binArr:= new this.parentClass.typeArr(maxTasks,mute)	; Binary pointer array
		this.argArr:= new this.parentClass.typeArr(maxTasks,mute)	; Args pointer array
		this.thHArr:= new this.parentClass.typeArr(maxTasks,mute)	; thread handle array
		this.tIdArr:= new this.parentClass.typeArr(maxTasks,mute)	; thread id array
		this.init()
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
	init(){
		throw Exception("init() not implemented.",-1)
	}
	getArgPtr(ind){
		return this.argArr.getValPtr(ind)
	}
	;<<Task methods>>
	addTask(pBin,pArgs,start:=true,stackSize:=0){
		; pBin, pointer to binary buffer with 
		; pArgs, pointer to the arguments for the binary code
		static CREATE_SUSPENDED:=0x00000004
		local threadData
		this.binArr.push(pBin)
		this.argArr.push(pArgs)
		threadData := this.parentClass.core.createThread(pBin, pArgs, 0, stackSize, start ? 0 : CREATE_SUSPENDED) ; For reference, threadData := {hThread:th,threadId:lpThreadId}
		this.thHArr.push(threadData.hThread)
		this.tIdArr.push(threadData.threadId)
		return 
	}
	startAllTasks(){
		local k, hThread
		if this.thHArr.getLength()
			for k, hThread in this.thHArr
				this.parentClass.core.resumeThread(hThread)
		else
			this.parentClass.exception("No thread handles available.",,-1,"Warn")
		return 
	}
	startTask(ind){
		return this.parentClass.core.resumeThread(this.thHArr.get(ind))
	}
	terminateAllThreads() {
		local k, th
		if this.thHArr.getLength()
			for k, tH in this.thHArr
				this.parentClass.core.terminateThread(tH)
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
		
		r:=this.parentClass.core.waitForMultipleObjects(this.thHArr.getLength(), this.thHArr.getArrPtr(),waitForAll,ms)
		if !waitForAll
			return r ; Handle return in waitForAnyTask()
		if (r==WAIT_OBJECT_0)
			return true
		else if (r==WAIT_TIMEOUT)
			return -1
		this.parentClass.exception("Unknown return from WaitForMultipleObjects.",[r],-1,"Warn","ExitApp")
	}
	waitForAnyTask(ms:=0xFFFFFFFF){
		; Returns the lowest task number of all tasks which have finished. (This is  the
		; zero-based  index  in the thHArr, add one to get based one index for user) 
		; Return -1 if the wait times out.
		static WAIT_TIMEOUT:=0x00000102
		local r
		r:=this.parentClass.core.waitForAllTasks(ms,false)
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
		r:=this.parentClass.core.waitForSingleObject(this.thHArr.get(ind),ms)
		if (r==WAIT_OBJECT_0)
			return true
		else if (r==WAIT_TIMEOUT)
			return -1
		this.parentClass.exception("Unknown return from WaitForSingleObject.",[r],-1,"Warn","ExitApp")
		return
	}
	notifyOnAllTaskComplete(callback,rate:=50){
		return
	}
	notifyOnTaskComplete(ind,callback,rate:=50){
		return
	}
}