class pool {
	create(min,max){
		; Creates thread pool of min-max threads.
		; Initialises threadPoolEnvironment and cleanup group.
		
		; In the subsequent:
		; TP_POOL 				pptp	-	the thread pool
		; PTP_CALLBACK_ENVIRON 	pcbe	-	the thread pool callback environment
		; PTP_CLEANUP_GROUP 	ptpcg	-	the thread pool clean-up group
		
		this.pptp := createThreadPool()													; Create threadPool 					
		this.max:=max																	; Save min max
		this.min:=min                                                   				
		xlib.core.setThreadpoolThreadMaximum(this.pptp, max)							; Set max threads
		xlib.core.setThreadpoolThreadMinimum(this.pptp, min)							; Set min threads
		this.pcbe := xlib.core.initializeThreadpoolEnvironment()						; Initialises threadPoolEnvironment		
		this.ptpcg := xlib.core.createThreadpoolCleanupGroup()							; Create thread pool clean-up group
		xlib.core.setThreadpoolCallbackPool(this.pcbe, this.ptpp)						; Set the Pool (ptpp) member of thread cbe struct
		xlib.core.setThreadpoolCallbackCleanupGroup(this.pcbe, this.ptpcg, 0)			; Set the CleanupGroup (ptpcg) and the CleanupGroupCancelCallback (0) members of the cbe struct
		return
	}
}