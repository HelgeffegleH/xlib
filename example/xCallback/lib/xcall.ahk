class xcall extends xlib.callback {
	
	__new(fn, decl*){
		base.__new(fn, decl*)									; initialises this.bin
		this.handler := new xlib.ui.threadHandler()				;
		this.autoCleanUp( true )
	}
	autoCleanUp(bool := true){
		this.autoRelease := bool
		return this.handler.autoReleaseAllCallbackStructs( bool )		; automatic clean up if bool is true.
	}
	outstandingCallbacks := []
	nCallbacksRunning := 0
	call(callback, p*){
		; callback, udf script callback.	(Free variable, see callbackRouter below)
		; p, parameters for the worker function.
		; 
		local
		global xlib
		; Note, multi-expression line(s)
		pvid 	 := this.setupCall(p*)	; pvid: [pv, callId], pv is of type 'struct'
		, pv 	 := pvid.1	;	free variable
		, callId := pvid.2  ;	-- '' --
		
		; setup callback free variables for callbackRouter (closure)
		; Avoids bindnig 'this'
		rt 		:= this.rt										; return type
		, o 	:= this.o										; offset array, offsets for each parameter
		, decl	:= this.decl									; declaration array
		scriptCallback := func('callbackRouter')				; Script callback, calls udf callback function.
		
		callbackNumber := this.handler.registerTaskCallback(	; Register the task
																;
																this.bin,												; Work function
																pv.pointer,												; Parameters
																scriptCallback,
																false													; Do not start
															)
		this.outstandingCallbacks[ callbackNumber ] := this.autoRelease ? true : pv
		, this.nCallbacksRunning++
		, this.handler.startTask( callbackNumber )																		; Start
		return callbackNumber
		;
		;	Callback closure
		;
		callbackRouter( callbackNumber, task ){ ; callbackNumber and task is passed by the thread handler. task == this.handler
			; This function is the scriptCallback called by threadHandler.callbackReciever, when it returns it releases the callback struct 
			; which has the last reference to this closure, hence 'pv' is released and its clean up function is called. It releases the return address and the parameter list.
			; Note, one line
			ret := numget( pv.get('ret'), rt )
			, resObj := xlib.callback.createResObj(pv.get('params'), o, decl, ret, pv.nMembers)	; Create a result object.
			, callback.call(resObj) ; callback is a parameter of the outer function.
		}
	}
}