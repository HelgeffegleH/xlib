; Compability:
;	Thread pool api is for windows vista or newer. (A few features are windows 7 or newer only.)
; Note:
; 	TP_IO currently unavailable.
;	
class poolbase {
	
	class cleanupObj {
		; Methods
		setCleanUpFunction(cleanUpFn){
			this.cleanUpFn:=cleanUpFn
		}
		cleanUp(p*){					; Must be implemented
			xlib.exception('Not implemented. Note: AHK "delays" throws from within __delete. This message may be delayed.')
		}
		; Meta functions
		__delete(){
			if this.cleanUpFn			; User defined clean up function.
				this.cleanUpFn.call(this)
			this.cleanUp()				; Class defined clean up function.
		}
		; Error
		; Yeilds an error for properties which can only be set once.
		error(key, value, gettable:=true){
			xlib.exception(this.__class " cannot assign " value " to " key ".`nKey is already associated with " (gettable? "value: " this[key] : "a value") ".",,-1)
		}
	}
		;<< TP_BASE >>
	class TP_BASE extends xlib.poolbase.cleanupObj {
		; Base class for structures:
		; * TP_POOL
		; * TP_CALLBACK_ENVIRON
		; * TP_CLEANUP_GROUP
		; * TP_BASE_CALLBACK	(Base)
		; 	- TP_WORK
		; 	- TP_TIMER
		; 	- TP_WAIT
		
		__new(params*){
			if !this.initFunc
				xlib.exception("Classes extending TP_BASE must specify an initFunc.")
			if !this[this.TPStructName] := this.initFunc(params*)						; Initialises the structure. Sets the TP property.
				xlib.exception("Initialising of the structure failed. Struct: " this.TPStructName ".")
		}
		getPointer(){
			return this.TP																; For clarity, method returns the stucture pointer
		}
		; Properties 
		static TPStructName := "TP" 
		TP {																			; PT_
			set{                                                                        ; can only be set once, + set to "" to destroy
				if value == "" && this._TP {											; Clear the property to destroy or close the structure
					if !this.closeFunc
						xlib.exception("Classes extending TP_BASE must specify a closeFunc.")
					this.closeFunc(this._TP)
					this._TP := ""
					return 
				} else if !this._TP {
					return this._TP := value											; This value can only be set once
				}
				this.error(this.TPStructName, value)
			} get{
				if !this._TP
					xlib.exception(this.TPStructName " has no value.")
				return this._TP
			}
		}
		
	}
		;	<< TP_POOL - Pool >>
		;	CloseThreadpool
		;	CreateThreadpool
		;	SetThreadpoolThreadMaximum
		;	SetThreadpoolThreadMinimum
		
	class TP_POOL extends xlib.poolbase.TP_BASE {
		static TPStructName := "pptp"					; Must be set
		initFunc := xlib.core.pool.createThreadPool		; Must be set
		closeFunc := xlib.core.pool.closeThreadpool     ; Must be set
		pptp {											; Invoke base property
			set {
				return this.TP := value
			} get {
				return this.TP
			}
		}
		; threadPool specific properties
		max{																			; Max threads - can only be set once
			set{
				if !this._max {
					this._max := value
					return xlib.core.pool.setThreadpoolThreadMaximum(this.pptp, value)
				}
				this.error("max", value)
			} get {
				return this._max
			}
		}
		min{																			; Min threads - can only be set once
			set{
				if !this._min {
					this._min := value
					return xlib.core.pool.setThreadpoolThreadMinimum(this.pptp, value)
				}
				this.error("min", value)
			} get {
				return this._min
			}
		}
		; Clean up
		cleanUp(p*){
			; Destroys the pool
			this.ptpp:="" 
		}
	}
		;	<< TP_CALLBACK_ENVIRON - Callback environment >>
		;	DestroyThreadpoolEnvironment
		;	InitializeThreadpoolEnvironment
		;	SetThreadpoolCallbackCleanupGroup
		;	SetThreadpoolCallbackLibrary
		;	SetThreadpoolCallbackPool
		;	SetThreadpoolCallbackPriority
		;	SetThreadpoolCallbackRunsLong	(not used) ;<< note; should be added >>
	class TP_CALLBACK_ENVIRON extends xlib.poolbase.TP_BASE {
		; Compability:
		;	The priority property is for win7 or newer only.
		
		; Base properties
		static TPStructName := "pcbe"												; Must be set
		initFunc := xlib.core.pool.initializeThreadpoolEnvironment					; Must be set
		closeFunc := xlib.core.pool.destroyThreadpoolEnvironment    				; Must be set
		pcbe {																		; Invoke base property
			set {
				return this.TP := value
			} get {
				return this.TP
			}
		}
		; Callback environment specific properties
		callbackLibrary{
			set{
				xlib.core.pool.setThreadpoolCallbackLibrary(this.pcbe, value)		; value = (void*) mod
				return value
			}
		}
		pool {																		; The associated pool - can only be set once
			set{                                                        			
				if !this.poolIsSet {                                    			
					xlib.core.pool.setThreadpoolCallbackPool(this.pcbe, value)		; value = ptpp
					this.poolIsSet:=true
					return value
				}
				this.error("pool", value, 0)
			}
		}
		pfng:=0                                                         			; PTP_CLEANUP_GROUP                 ptpcg,
		cleanUpGroup[pfng:=0] {                                         			; PTP_CLEANUP_GROUP_CANCEL_CALLBACK pfng
			set {
				this.ptpcg := value
				this.pfng := pfng
				xlib.core.pool.setThreadpoolCallbackCleanupGroup(this.pcbe, this.ptpcg, pfng)	; Note: The function doesn't return a value.
				return this.cleanUpGroup
			} get {
				return {ptpcg:this.ptpcg, pfng:this.pfng}
			}
		}
		priority {
			; Valid values:
			; 0,1,2
			;
			; Minimum OS is windows 7.
			; Throws error on windows vista. 
			/*
				TP_CALLBACK_PRIORITY_HIGH 		(0)	The callback should run at high priority.
				TP_CALLBACK_PRIORITY_LOW 		(1)	The callback should run at low priority.
				TP_CALLBACK_PRIORITY_NORMAL 	(2)	The callback should run at normal priority.
				TP_CALLBACK_PRIORITY_INVALID	(3)	invalid
			*/
			set{
				xlib.core.pool.setThreadpoolCallbackPriority(value)					; Note: The function doesn't return a value. The function throws on invalid input.
				return this._priority := value                                  	; The function throws on invalid input.
			} get {                                                             	; The function also confirms that the OS supports the function. Throws if not supported.
				return this._priority                                           	
			}                                                                   	
		} 
		; Clean up
		cleanUp(){
			this.pcbe:="" ; destroys the callback environment
		}
	}                                                                           	
		;	<< TP_CLEANUP_GROUP - Clean-up group >>
		;	CloseThreadpoolCleanupGroup
		;	CloseThreadpoolCleanupGroupMembers
		;	CreateThreadpoolCleanupGroup                                                                           	
	class TP_CLEANUP_GROUP extends xlib.poolbase.TP_BASE {                   	
		
		; Base properties
		static TPStructName := "ptpcg"									; Must be set
		initFunc := xlib.core.pool.createThreadpoolCleanupGroup			; Must be set
		closeFunc := xlib.core.pool.closeThreadpoolCleanupGroup	    	; Must be set
		ptpcg {															; Invoke base property
			set {
				return this.TP := value
			} get {
				return this.TP
			}
		}
		; callback environment specific methods and properties
		
		; Methods
		
		waitClose(fCancelPendingCallbacks:=true, pvCleanupContext:=0){
			; Parameters
			; 
			; ptpcg [in, out] A TP_CLEANUP_GROUP structure that defines the cleanup group. The
			; 	CreateThreadpoolCleanupGroup     function      returns      this      structure.
			; 
			; fCancelPendingCallbacks  [in]  If  this  parameter is TRUE, the function cancels
			; 	outstanding callbacks that have not yet started. If this parameter is FALSE, the
			; 	function waits for outstanding callback functions to complete.  
			;
			; pvCleanupContext, The application-defined data to pass to the application's
			; 	cleanup group callback function. You can specify the callback function when  you
			; 	call SetThreadpoolCallbackCleanupGroup.
			;
			xlib.core.pool.closeThreadpoolCleanupGroupMembers(this.ptpcg, fCancelPendingCallbacks, pvCleanupContext)
		}
		close(pvCleanupContext:=0){
			this.waitClose(false, pvCleanupContext)
		}
		; Clean up
		onExit := "waitAll"												; Consider how to set this or which default to use.		;<< note waitAll >>
		cleanUp(){					
			if this.onExit == "waitAll"					
				this.waitClose()										; Waits for all callbacks
			else if this.onExit == "waitRunning"					
				this.close()											; Cancels outstanding and waits for running
			this.ptpcg:=""												; destroys the callback environment
		}
	}

	; A Callback object needs to define a callback function, with optional  parameters
	; and specify its callback environment. Optional, specify script callback function
	; or compiled function.
	;<< TP_BASE_CALLBACK >>
	class TP_BASE_CALLBACK extends xlib.poolbase.TP_BASE {
		; Base class for callback structures:
		; TP_WORK
		; TP_TIMER
		; TP_WAIT
		__new(callback, params:=0, pcbe:=0){
			base.__new(callback,params,pcbe)							; calls initFunc, which must be impemented.
			this.pv := params											; Store callback parameters.
			this.pcbe := pcbe											; Store callback environment pointer.
		}
		wait(fCancelPendingCallbacks:=false){							; A func object, waitFunc, must be specified.
			; Waits for the callback to finish, optionally cancels it if it hasn't started, use cancel() for clarity.
			if !this.waitFunc
				xlib.exception("Error in " A_ThisFunc ". A wait function must be defined.")
			this.waitFunc(this.TP, fCancelPendingCallbacks)
		}
		cancel(){
			; Cancels the callback if it hasn't started
			this.wait(true) ; True means cancel
		}
		submit(p*){
			xlib.exception("Error in " A_ThisFunc ". A submit function must be defined.")
		}
		registerScriptCallback(scriptFunc){								; Register a script function to be called when the callback returns
		}
		getParams(){
			; Returns the parameter pointer for the work callback
			return this.pv
		}
		; Properties
		pv {															; Pointer to parameters to pass to the work callback. Can only be set once.
			set {														; Note: You can change what the pointer points to, but the pointer is set only once.
				if !this._pv											; Note: When changing what the pointer points to, ensure no thread is using its contents.
					return this._pv := value
				this.error("pv", value)
			} get {
				return this._pv
			}
		}
		cleanUp(){
			this.TP := ""												; closes the callback object. calls closeFunc, which must be impemented.
		}
	}

		;	<< TP_WORK - Work >>
		;	CloseThreadpoolWork
		;	CreateThreadpoolWork
		;	SubmitThreadpoolWork
		;	TrySubmitThreadpoolCallback (not used)
		;	WaitForThreadpoolWorkCallbacks
	class TP_WORK extends xlib.poolbase.TP_BASE_CALLBACK { 
		; Base methods which must be implemented
		
		initFunc	:= xlib.core.pool.createThreadpoolWork
		closeFunc	:= xlib.core.pool.closeThreadpoolWork
		waitFunc	:= xlib.core.pool.waitForThreadpoolWorkCallbacks			; Define waitFunc, used by base.cancel() and base.wait()
		
		; Work specific methods
		
		submit(){																; Submits the work.
			xlib.core.pool.submitThreadpoolWork(this.pwk)
			; Set isOutstanding := true
			; Handle callback
			; ...
		}

		; Properties
		
		static TPStructName := "pwk"
		pwk {																	; work pointer, invokes base property
			set {
				return this.TP := value
			} get {
				return this.TP
			}
		}
			
	}
		;	<< Timer >>
		;	CloseThreadpoolTimer
		;	CreateThreadpoolTimer
		;	IsThreadpoolTimerSet
		;	SetThreadpoolTimer
		;	WaitForThreadpoolTimerCallbacks
	class TP_TIMER extends xlib.poolbase.TP_BASE_CALLBACK {

		; Base methods which must be implemented

		initFunc	:= xlib.core.pool.createThreadpoolTimer
		closeFunc	:= xlib.core.pool.closeThreadpoolTimer
		waitFunc	:= xlib.core.pool.waitForThreadpoolTimerCallbacks		; Define waitFunc, used by base.cancel() and base.wait()
		submit(p*){
			this.setTimer(p*)
		}
		; Timer specific methods
		
		setTimer(pftDueTime, msPeriod, msWindowLength){
			xlib.core.pool.setThreadpoolTimer(this.pti, pftDueTime, msPeriod, msWindowLength)
		}
		isTimerSet(){
			; returns true if timer is set, otherwise false.
			return xlib.core.pool.isThreadpoolTimerSet(this.pti)
		}
		
		; Properties
		
		static TPStructName := "pti"						
		pti {															; timer pointer, invokes base property
			set {
				return this.TP := value
			} get {
				return this.TP
			}
		}
	}
		;	<< Synch >>
		;	CloseThreadpoolWait
		;	CreateThreadpoolWait
		;	SetThreadpoolWait
		;	WaitForThreadpoolWaitCallbacks
	class TP_WAIT extends xlib.poolbase.TP_BASE_CALLBACK {
		; Base methods which must be implemented
		initFunc	:= xlib.core.pool.CreateThreadpoolWait
		closeFunc	:= xlib.core.pool.CloseThreadpoolWait
		waitFunc	:= xlib.core.pool.WaitForThreadpoolWaitCallbacks	; Define waitFunc, used by base.cancel() and base.wait()
		submit(p*){
			this.SetThreadpoolWait(p*)
		}
		; wait specific methods
		setThreadpoolWait(h:=0, pftTimeout:=0){
			return xlib.core.pool.setThreadpoolWait(this.pwa, h, pftTimeout)
		}
		
		; Properties
		
		static TPStructName := "pwa"									
		pwa {															; wait pointer, invokes base property
			set {
				return this.TP := value
			} get {
				return this.TP
			}
		}
	}
}