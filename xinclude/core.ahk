class core {
	static parentClass:=xlib
	;<< thread pool functions >>
	createThreadPool(){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms682456(v=vs.85).aspx (CreateThreadpool function)
		; Note:
		;	- If function fails, it returns NULL.
		local TP_POOL
		if !(TP_POOL:=DllCall("Kernel32.dll\CreateThreadpool", "Ptr"))
			this.parentClass.exception("Failed to create thread pool.",0,0,0)
		return TP_POOL
	}
	setThreadpoolThreadMaximum(TP_POOL, max){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms686266(v=vs.85).aspx (SetThreadpoolThreadMaximum function)
		; Note:
		;	- Sets the maximum number of threads that the specified thread pool can allocate to process callbacks
		;	- This function does not return a value.
		DllCall("Kernel32.dll\SetThreadpoolThreadMaximum", "Ptr", TP_POOL, "Uint", max)
		return
	}
	setThreadpoolThreadMinimum(TP_POOL, min){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms686268(v=vs.85).aspx (SetThreadpoolThreadMinimum function)
		; Note:
		;	- Sets the minimum number of threads that the specified thread pool must make available to process callbacks.
		;	- If the function succeeds, it returns TRUE. If the function fails, it returns FALSE.
		if !DllCall("Kernel32.dll\SetThreadpoolThreadMinimum", "Ptr", TP_POOL, "Uint", min)
			this.parentClass.exception("SetThreadpoolThreadMinimum failed for minimum: " min) 
		return
	}
	initializeThreadpoolEnvironment(){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms683486(v=vs.85).aspx (InitializeThreadpoolEnvironment function)
		; Note:
		;	- Initializes a callback environment.
		;	- Forced inline function.
		;	
		/*
			
		Source, winnt.h
		#if (_WIN32_WINNT >= _WIN32_WINNT_WIN7)

		typedef struct _TP_CALLBACK_ENVIRON_V3 {										offset:
			TP_VERSION (ULONG)                 Version;									0
			PTP_POOL                           Pool;									4  : 8
			PTP_CLEANUP_GROUP                  CleanupGroup;							8  : 16
			PTP_CLEANUP_GROUP_CANCEL_CALLBACK  CleanupGroupCancelCallback;				12 : 24
			PVOID                              RaceDll;									16 : 32
			struct _ACTIVATION_CONTEXT        *ActivationContext;						20 : 40
			PTP_SIMPLE_CALLBACK                FinalizationCallback;					24 : 48
			union {
				DWORD                          Flags;									28 : 56	
				struct {
					DWORD                      LongFunction :  1;
					DWORD                      Persistent   :  1;
					DWORD                      Private      : 30;
				} s;
			} u;    
			TP_CALLBACK_PRIORITY               CallbackPriority;						32 : 60
			DWORD                              Size;									36 : 64 
		} TP_CALLBACK_ENVIRON_V3;
		size: A_PtrSize == 4 ?  40 : 72 
		typedef TP_CALLBACK_ENVIRON_V3 TP_CALLBACK_ENVIRON, *PTP_CALLBACK_ENVIRON;

		#else

		typedef struct _TP_CALLBACK_ENVIRON_V1 {
			TP_VERSION                         Version;
			PTP_POOL                           Pool;
			PTP_CLEANUP_GROUP                  CleanupGroup;
			PTP_CLEANUP_GROUP_CANCEL_CALLBACK  CleanupGroupCancelCallback;
			PVOID                              RaceDll;
			struct _ACTIVATION_CONTEXT        *ActivationContext;
			PTP_SIMPLE_CALLBACK                FinalizationCallback;
			union {
				DWORD                          Flags;
				struct {
					DWORD                      LongFunction :  1;
					DWORD                      Persistent   :  1;
					DWORD                      Private      : 30;
				} s;
			} u;    
		} TP_CALLBACK_ENVIRON_V1;
		size: A_PtrSize == 4 ?  32 : 64 
		
		typedef enum _TP_CALLBACK_PRIORITY {
			TP_CALLBACK_PRIORITY_HIGH,			(0)
			TP_CALLBACK_PRIORITY_NORMAL,		(1)
			TP_CALLBACK_PRIORITY_LOW,			(2)
			TP_CALLBACK_PRIORITY_INVALID		(3)
		} TP_CALLBACK_PRIORITY;
		
		FORCEINLINE
		VOID
		TpInitializeCallbackEnviron(
			__out PTP_CALLBACK_ENVIRON CallbackEnviron
			)
		{

		#if (_WIN32_WINNT >= _WIN32_WINNT_WIN7)

			CallbackEnviron->Version = 3;

		#else

			CallbackEnviron->Version = 1;

		#endif

			CallbackEnviron->Pool = NULL;
			CallbackEnviron->CleanupGroup = NULL;
			CallbackEnviron->CleanupGroupCancelCallback = NULL;
			CallbackEnviron->RaceDll = NULL;
			CallbackEnviron->ActivationContext = NULL;
			CallbackEnviron->FinalizationCallback = NULL;
			CallbackEnviron->u.Flags = 0;

		#if (_WIN32_WINNT >= _WIN32_WINNT_WIN7)

			CallbackEnviron->CallbackPriority = TP_CALLBACK_PRIORITY_NORMAL;
			CallbackEnviron->Size = sizeof(TP_CALLBACK_ENVIRON);

		#endif

		}
		*/
		local envVerion, pcbe
		
		static TP_CALLBACK_PRIORITY_NORMAL:=1
		static sizeOf_TP_CALLBACK_ENVIRON_V1 := A_PtrSize == 4 ? 32 : 64	; The size depends on the os version.	(This is for Vista)
		static sizeOf_TP_CALLBACK_ENVIRON_V3 := A_PtrSize == 4 ? 40 : 72	;										(This is for >vista)
		envVerion := this.parentClass.getVersion()
		if !envVerion ; Remove
			throw "envVerion"
		pcbe := this.parentClass.mem.globalAlloc( envVerion == 1 ? sizeOf_TP_CALLBACK_ENVIRON_V1 : sizeOf_TP_CALLBACK_ENVIRON_V3)
		NumPut(envVerion, pcbe+0, 0, "Uint")																		; CallbackEnviron->Version
		if (envVerion == 3){
			NumPut(TP_CALLBACK_PRIORITY_NORMAL,		pcbe+0, A_PtrSize == 4 ? 32 : 60, "Uint")						; CallbackEnviron->CallbackPriority
			NumPut(sizeOf_TP_CALLBACK_ENVIRON_V3, 	pcbe+0, A_PtrSize == 4 ? 36 : 64, "Uint")						; CallbackEnviron->Size
		}
		return pcbe
	}
	setThreadpoolCallbackPool(pcbe,PTP_POOL){
	; Url:
	;	- (SetThreadpoolCallbackPool function)
	; Note:
	;	- Sets the thread pool to be used when generating callbacks.
	;	- Forced inline function.
	;
	; Parameters:
	; 	pcbe, 		a TP_CALLBACK_ENVIRON structure  that  defines  the  callback  environment.  The
	;				InitializeThreadpoolEnvironment  function  returns  this  structure. 
	;	TP_POOL, 	structure that defines the thread pool.  The  CreateThreadpool  function
	;				returns this structure.
	/*
		FORCEINLINE
		VOID
		TpSetCallbackThreadpool(
			__inout PTP_CALLBACK_ENVIRON CallbackEnviron,							(pcbe)
			__in    PTP_POOL             Pool
			)
		{
			CallbackEnviron->Pool = Pool;
		}
	*/
		return NumPut(PTP_POOL, pcbe+0, A_PtrSize == 4 ? 4 : 8, "Ptr")												; CallbackEnviron->Pool
	}
	createThreadpoolCleanupGroup(){
		local PTP_CLEANUP_GROUP
		if !(PTP_CLEANUP_GROUP:=DllCall("Kernel32.dll\CreateThreadpoolCleanupGroup","Ptr"))
			this.parentClass.exception("CreateThreadpoolCleanupGroup failed.")
		return PTP_CLEANUP_GROUP
	}
	setThreadpoolCallbackCleanupGroup(pcbe, PTP_CLEANUP_GROUP, PTP_CLEANUP_GROUP_CANCEL_CALLBACK:=0){
		/*
		FORCEINLINE
		VOID
		TpSetCallbackCleanupGroup(
			__inout  PTP_CALLBACK_ENVIRON              CallbackEnviron,				(pcbe)
			__in     PTP_CLEANUP_GROUP                 CleanupGroup,
			__in_opt PTP_CLEANUP_GROUP_CANCEL_CALLBACK CleanupGroupCancelCallback
			)
		{
			CallbackEnviron->CleanupGroup = CleanupGroup;
			CallbackEnviron->CleanupGroupCancelCallback = CleanupGroupCancelCallback;
		}
		*/
		NumPut(PTP_CLEANUP_GROUP,					pcbe+0, A_PtrSize == 4 ?  8 : 16, "Ptr")						; CallbackEnviron->CleanupGroup
		NumPut(PTP_CLEANUP_GROUP_CANCEL_CALLBACK,	pcbe+0, A_PtrSize == 4 ? 12 : 24, "Ptr")						; CallbackEnviron->CleanupGroupCancelCallback
		return
	}
	createThreadpoolWork(pfnwk, pv, pcbe){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms682478(v=vs.85).aspx (CreateThreadpoolWork function)
		; Note:
		;	- If the function fails, it returns NULL.
		/*
		PTP_WORK_CALLBACK    pfnwk,
		PVOID                pv,
		PTP_CALLBACK_ENVIRON pcbe
		*/
		local PTP_WORK
		if !(PTP_WORK:=DllCall("Kernel32.dll\CreateThreadpoolWork", "Ptr", pfnwk, "Ptr", pv, "Ptr", pcbe, "Ptr"))
			this.parentClass.exception("CreateThreadpoolWork failed.")
		return PTP_WORK
	}
	submitThreadpoolWork(PTP_WORK){
	; Url:
	;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms686338(v=vs.85).aspx (SubmitThreadpoolWork function)
	; Note:
	;	- PTP_WORK, A TP_WORK structure that defines the work object. The CreateThreadpoolWork function returns this structure.
		DllCall("Kernel32.dll\SubmitThreadpoolWork", "Ptr", PTP_WORK) ; This function does not return a value.
		return
	}
	;<< threadPool wait function >>
	createThreadpoolWait(pfnwa, pv, pcbe){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms682474(v=vs.85).aspx (CreateThreadpoolWait function)
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms687017(v=vs.85).aspx (WaitCallback callback function)
		; Note:
		;	- If the function fails, it returns NULL.
		/*
		PTP_WAIT_CALLBACK    pfnwa,
		PVOID                pv,
		PTP_CALLBACK_ENVIRON pcbe
		
		VOID CALLBACK WaitCallback(
		  _Inout_     PTP_CALLBACK_INSTANCE Instance,
		  _Inout_opt_ PVOID                 Context,
		  _Inout_     PTP_WAIT              Wait,
		  _In_        TP_WAIT_RESULT        WaitResult
		);
		*/
		local PTP_WAIT
		if !(PTP_WAIT:=DllCall("Kernel32.dll\CreateThreadpoolWait", "Ptr", pfnwa, "Ptr", pv, "Ptr", pcbe, "Ptr"))
			this.parentClass.exception("CreateThreadpoolWait failed.")
		return PTP_WAIT
	}
	setThreadpoolWait(PTP_WAIT, h:=0, pftTimeout:=0){
		; Url:
		;	- https://https://msdn.microsoft.com/en-us/library/windows/desktop/ms686273(v=vs.85).aspx (SetThreadpoolWait function)
		; Note:
		;	- This function does not return a value.
		;	- pftTimeout, a pointer to a FILETIME structure that specifies the absolute or relative time at which the wait operation should time out. 
		;	  If this parameter points to a positive value, it indicates the absolute time since January 1, 1601 (UTC), in 100-nanosecond intervals.
		;     If this parameter points to a negative value, it indicates the amount of time to wait relative to the current time. For more information about time values, see File Times.
		; 	  If this parameter points to 0, the wait times out immediately. 
		;	  If this parameter is NULL, the wait will not time out. pftTimeout=0 (corresponds to NULL) is deafault.
		/*
		PTP_WAIT  pwa,
		HANDLE    h,
		PFILETIME pftTimeout
		*/
		DllCall("Kernel32.dll\SetThreadpoolWait", "Ptr", PTP_WAIT, "Ptr", h, "Ptr", pftTimeout)
		return
	}
	waitForThreadpoolWaitCallbacks(PTP_WAIT,fCancelPendingCallbacks:=false){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms687047(v=vs.85).aspx (WaitForThreadpoolWaitCallbacks function)
		; Note:
		;	- This function does not return a value.
		/*
		_Inout_ PTP_WAIT pwa,
		_In_    BOOL     fCancelPendingCallbacks
		*/
		DllCall("Kernel32.dll\WaitForThreadpoolWaitCallbacks", "Ptr", PTP_WAIT, "Int", fCancelPendingCallbacks)
		return
	}
	waitForThreadpoolWorkCallbacks(PTP_WORK, fCancelPendingCallbacks:=false){
		; Url:
		;	- https://https://msdn.microsoft.com/en-us/library/windows/desktop/ms687053(v=vs.85).aspx (WaitForThreadpoolWorkCallbacks function)
		; Note:
		;	- Waits for outstanding work callbacks to complete and optionally cancels pending callbacks that have not yet started to execute.
		;	- This function does not return a value.
		DllCall("Kernel32.dll\WaitForThreadpoolWorkCallbacks", "Ptr", PTP_WORK, "Int", fCancelPendingCallbacks)
		return 
	}
	createThreadpoolTimer(pfnti, pv, pcbe){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms682466(v=vs.85).aspx (CreateThreadpoolTimer function)
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms686790(v=vs.85).aspx (TimerCallback callback function)
		; Note:
		;	- If the function fails, it returns NULL. (CreateThreadpoolTimer function)
		/*
		_In_        PTP_TIMER_CALLBACK   pfnti, (See TimerCallback callback function)
		_Inout_opt_ PVOID                pv,
		_In_opt_    PTP_CALLBACK_ENVIRON pcbe
		
		TimerCallback function:
		VOID CALLBACK TimerCallback(
		_Inout_     PTP_CALLBACK_INSTANCE Instance,
		_Inout_opt_ PVOID                 Context,
		_Inout_     PTP_TIMER             Timer
		);
		*/
		local TP_TIMER
		if !(TP_TIMER:=DllCall("Kernel32.dll\CreateThreadpoolTimer", "Ptr", pfnti, "Ptr", pv, "Ptr", pcbe, "Ptr"))
			this.parentClass.exception("CreateThreadpoolTimer failed.",,-2)
		return TP_TIMER
	}
	setThreadpoolTimer(pti, pftDueTime, msPeriod, msWindowLength){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms686271(v=vs.85).aspx (SetThreadpoolTimer function)
		; Note:
		;	- This function does not return a value.
		;	- Setting the timer cancels the previous timer, if any.
		/*
		_Inout_  PTP_TIMER pti,
		_In_opt_ PFILETIME pftDueTime,
		_In_     DWORD     msPeriod,
		_In_opt_ DWORD     msWindowLength
		*/
		DllCall("Kernel32.dll\SetThreadpoolTimer", "Ptr", pti, "Ptr", pftDueTime, "Uint", msPeriod, "Uint", msWindowLength)
		return
	}
	;<< thread functions >>
	createThread(lpStartAddress,lpParameter:=0,lpThreadAttributes:=0,dwStackSize:=0,dwCreationFlags:=0){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms682453(v=vs.85).aspx (CreateThread function)
		; Note:
		;	- If the function fails, the return value is NULL.
		/*
		LPSECURITY_ATTRIBUTES  lpThreadAttributes,
		SIZE_T                 dwStackSize,
		LPTHREAD_START_ROUTINE lpStartAddress,
		LPVOID                 lpParameter,
		DWORD                  dwCreationFlags,
		LPDWORD                lpThreadId
		*/
		local th
		if !th:=DllCall("Kernel32.dll\CreateThread"	,"Ptr",		lpThreadAttributes 
													,"Uptr",	dwStackSize        
													,"Ptr",		lpStartAddress		
													,"Ptr",		lpParameter		
													,"Uint",	dwCreationFlags    
													,"PtrP",	lpThreadId
													,"Ptr")		; Return type
			this.parentClass.exception("Thread initialise failed",[th],-2)
		return {hThread:th,threadId:lpThreadId}
	}
	resumeThread(hThread){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms685086(v=vs.85).aspx (ResumeThread function)
		
		local r:=DllCall("Kernel32.dll\ResumeThread", "Ptr", hThread, "Uint")
		if (r == 0xFFFFFFFF)
			this.exception("ResumeThread failed. Thread handle: " . hThread . ".",[r],-2)
		return r
	}
	terminateThread(hThread,dwExitCode:=1){
		; Url:
		;	 - https://msdn.microsoft.com/en-us/library/windows/desktop/ms686717(v=vs.85).aspx (TerminateThread function) 
		; Notes:
		;	TerminateThread is used to cause a thread to exit. When this occurs, the  target
		;	thread  has no chance to execute any user-mode code. DLLs attached to the thread
		;	are not notified that the thread is terminating. The system frees  the  thread's
		;	initial  stack.  Windows Server 2003 and Windows XP: The target thread's initial
		;	stack is not freed, causing a resource leak.
		;	TerminateThread is used to cause a thread to exit. When this occurs, the  target
		;	thread  has no chance to execute any user-mode code. DLLs attached to the thread
		;	are not notified that the thread is terminating. The system frees  the  thread's
		;	initial  stack.  
		;	Windows Server 2003 and Windows XP: The target thread's initial
		;	stack is not freed, causing a resource leak.
		static STILL_ACTIVE:=259
		if !hThread
			this.exception("TherminateThread failed, thread handle invalid.",,-2,"Warn")
		else if (dwExitCode==STILL_ACTIVE)
			this.exception("TherminateThread failed, bad exit code: STILL_ACTIVE=259.",,-2,"Warn")
		else if !DllCall("Kernel32.dll\TerminateThread", "PtrP", hThread, "Uint",  dwExitCode)		; If the function fails, the return value is zero
			this.exception("","","",-2)
		else
			this.closeHandle(hThread)
	}
	;<< Wait methods >>
	waitForMultipleObjects(nCount, lpHandles, bWaitAll:=true, dwMilliseconds:=0xFFFFFFFF){
		; Url:
		;	https://msdn.microsoft.com/en-us/library/windows/desktop/ms687025(v=vs.85).aspx (WaitForMultipleObjects function)
		/*
		DWORD  nCount,
		HANDLE *lpHandles,
		BOOL   bWaitAll,
		DWORD  dwMilliseconds
		*/
		static WAIT_OBJECT_0:=	0x00000000
		static WAIT_ABANDONED:=	0x00000080
		static WAIT_TIMEOUT:=	0x00000102
		static WAIT_FAILED:=	0xFFFFFFFF
		local r
		r:=DllCall("Kernel32.dll\WaitForMultipleObjects", "Uint", nCount, "Ptr", lpHandles, "Int", bWaitAll, "Uint", dwMilliseconds, "Uint")
		if (r == WAIT_FAILED)
			this.exception("WaitForMultipleObjects failed for " . nCount . " number of objects.",[r],-1)
		if (r == WAIT_ABANDONED)
			this.exception("WaitForMultipleObjects failed for " . nCount . " number of objects. Reason: Wait abandoned" ,[r],-2)
		return r
	}
	waitForSingleObject(hHandle,dwMilliseconds){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms687032(v=vs.85).aspx (WaitForSingleObject function)
		/*
		HANDLE hHandle,
		DWORD  dwMilliseconds
		*/
		static WAIT_OBJECT_0:=	0x00000000
		static WAIT_ABANDONED:=	0x00000080
		static WAIT_TIMEOUT:=	0x00000102
		static WAIT_FAILED:=	0xFFFFFFFF
		local r
		r:=DllCall("Kernel32.dll\WaitForSingleObject", "Ptr", hHandle, "Uint", dwMilliseconds, "Uint")
		if (r == WAIT_FAILED)
			this.exception("WaitForSingleObject failed for handle " . hHandle . ".",[r],-1)
		if (r == WAIT_ABANDONED)
			this.exception("WaitForSingleObject failed for handle " . hHandle . ". Reason: Wait abandoned" ,[r],-2)

		return r
	}
	waitOnAddress(Address,CompareAddress,AddressSize,dwMilliseconds){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/hh706898(v=vs.85).aspx (WaitOnAddress function)
		/*
		VOID   volatile *Address,
		PVOID           CompareAddress,
		SIZE_T          AddressSize,
		DWORD           dwMilliseconds
		*/
		; Note: TRUE if the wait succeeded. If the operation fails, the function returns
		; FALSE.  If  the  wait  fails,  call  GetLastError  to  obtain  extended   error
		; information.  In  particular,  if the operation times out, GetLastError returns
		; ERROR_TIMEOUT.
		
		static ERROR_TIMEOUT:=1460  ; This operation returned because the timeout period expired. (0x5B4)
		local r
		r:=DllCall("Kernel32.dll\WaitOnAddress", "Ptr", Address, "Ptr", CompareAddress, "Ptr", AddressSize, "Uint", dwMilliseconds)
		if (!r && A_LastError==ERROR_TIMEOUT)
			return false
		else if r
			return true
		this.exception("WaitOnAddress failed, Address: " Address ", CompareAddress: " CompareAddress ", AddressSize: " AddressSize,,-2) 
	}
	;<< Misc >>
	closeHandle(hObject){
		; Url:
		;	- http://msdn.microsoft.com/en-us/library/windows/desktop/ms724211%28v=vs.85%29.aspx (CloseHandle function)
		if !DllCall("Kernel32.dll\CloseHandle", "Ptr", hObject)
			this.exception("Close handle failed to close handle: " hObject,,-2)
	}
	createEvent(lpEventAttributes, bManualReset, bInitialState, lpName){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms682396(v=vs.85).aspx (CreateEvent function)
		; Note:
		;	- Use the CloseHandle function to close the handle. The system closes the handle automatically when the process terminates.
		;	  The event object is destroyed when its last handle has been closed.
		;
		/*
		LPSECURITY_ATTRIBUTES lpEventAttributes,
		BOOL                  bManualReset,
		BOOL                  bInitialState,
		LPCTSTR               lpName
		*/
		local handle
		if !(handle:=DllCall("Kernel32.dll\CreateEvent", "Ptr", lpEventAttributes, "Int", bManualReset, "Int", bInitialState, "Str", lpName, "Ptr"))		
			this.parentClass.exception("CreateEvent failed for name: " . lpName . ".",,-2)
		return handle
	}
	setEvent(hEvent){
		; Url:
		;	- https://msdn.microsoft.com/en-us/library/windows/desktop/ms686211(v=vs.85).aspx (SetEvent function)
		if !DllCall("Kernel32.dll\SetEvent", "Ptr", hEvent)
			this.parentClass.exception("SetEvent failed for handle: " hEvent,,-2)
		return
	}
}
