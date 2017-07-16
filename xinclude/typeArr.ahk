class typeArr {
	;<<typeArr>>
	; To do, improve, eg, expand, delete, insertat, improve mute
	;
	; n, number of elements
	; mute, suppress errors on true
	; type, type of the elements. Can be any of the regular "NumPut"-types, eg, "Uint", "Char"...
	; sizeOfType, the size in byte of the specified type, eg, Int -> 4
	;
	static parentClass:=xlib
	len:=0	; Number of elements in the array
	__new(n,mute,type:="Ptr",sizeOfType:=0){ ; Mute as second param for now, beacuse of type,sizeOfType is convenient to leave out.
		if !sizeOfType
			sizeOfType:=A_PtrSize			; Default size is A_PtrSize
		this.maxLen:=n						
		this.type:=type						
		this.size:=sizeOfType
		this.totalSize:=n*sizeOfType		; Total size of the array.
		this.mute:=mute
		this.ptr:=this.tryB("GlobalAlloc",this.totalSize)
		
	}
	push(ptr){
		if this.outOfBounds(this.len+1,1,this.maxLen)
			this.tryB("exception", this.__Class . " failed @ push(), reason: Out of bounds, got: " . this.len+1 . ", expected value in range: [" . 1 . "," . this.maxLen "].",,-1,"Warn", "Exit")
		++this.len
		NumPut(ptr, this.ptr, (this.len-1)*this.size, this.type)
		
		return this.len
	}
	get(ind){
		; Get the value at ind.
		if this.outOfBounds(ind,1,this.len)
			this.tryB("exception", this.__Class . " failed @ get(), reason: Out of bounds, got: " ind ", expected value in range: [" 1 "," this.len "].",,-1,"Warn", "Exit")
		return NumGet(this.ptr,(ind-1)*this.size,this.type)
	}
	getValPtr(ind){
		; Get the pointer to the value at ind.
		if this.outOfBounds(ind,1,this.maxLen)
			this.tryB("exception", this.__Class . " failed @ getValPtr(), reason: Out of bounds, got: " ind ", expected value in range: [" 1 "," this.maxLen "].",,-1,"Warn", "Exit")
		return this.getArrPtr()+this.size*(ind-1)
	}
	getArrPtr(){
		return this.ptr
	}
	getLength(){
		return this.len
	}
	outOfBounds(x,lb,ub){
		return x<lb || x>ub
	}
	tryB(k,v*){
		; For handling mute, without needing to have a reference  to  the  object  which
		; initialised the array (if any).
		local err,r,ref
		try {
			r:=(this.parentClass)[k](v*)
		} catch err {
			if this.mute
				exit
			throw err
		}
		return r
	}
	__Delete(){
		this.tryB("GlobalFree",this.ptr)
	}
	
	_NewEnum(){
		return new this.parentClass.typeArr.Enum(this)
	}
	class Enum{
		; Enum class for for-looping the ptrArr
		__new(ref){
			this.ref:=ref
			this.ind:=0
		}
		next(byref k,byref v){
			if ((++this.ind)>this.ref.getLength())
				return 0
			k:=this.ind
			v:=this.ref.get(k)
			return 1
		}
	}
}   