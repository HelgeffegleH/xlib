; Primitive struct class.
; Specify size, eg, myStruct:= new struct(16)
; then build struct:
;					myStruct.build(	 ["type",value[,"memberName"]]
;									,["Uint",37, "theNumber"]
;									,["Ptr",0,"opt_ptr"])
;									,["pad",A_PtrSize=4?0:4]
;									,["Ptr",x, "thePointer"])
; Types are the usual numput/dllcall types, "ptr", "int" .... and "pad", to pad value bytes. Note: not "str". Todo, add type = "strbuf"
; Change member values, myStruct.Set("memberName", value)
; Retrieve member values, value := myStruct.Get("memberName")
; Free memory, myStruct:="" (if last reference is freed.)
;
class struct{
	static parentClass:=xlib
	members:=[]
	nMembers:=0
	__new(size,name:=""){
		this.name:=name ; Only for db purposes, you'll get the name in the error msg.
		this.ptr:=this.parentClass.mem.globalAlloc(size)
		this.maxSize:=size
		this.offset:=0		
	}
	build(members*){
		; members is an array of member arrays, [type,val,membername:=""]
		local k, member
		for k, member in members
			this.add(member*)
	}
	add(type,val,memberName:=""){
		local size, typeObj,size
		if (type="pad"){
			this.offset+=val
			return
		}
		++this.nMembers
		size:=this.parentClass.type.sizeOf(type)
		this.offset+=size	; Add to offset for error check
		
		memberName:= memberName!="" ? memberName : this.nMembers
		typeObj := new this.parentClass[type](val, this.ptr+this.offset-size)	; Subtract size because size was already added for error check.
		
		this.members[memberName]:={offset:this.offset, typeObj:typeObj}
		
		return
	}
	get(memberName){
		local value
		local member:=this.members[memberName]
		if !member
			this.parentClass.exception("Struct " this.name " has no member " memberName ".",,-2)
		return member.typeObj.val
	}
	set(memberName,value){
		local member:=this.members[memberName]
		if !member
			this.parentClass.exception("Struct " this.name " has no member " memberName ".",,-2)
		member.typeObj.val:=value
		return 
	}
	offset{
		set{
			if (this.o="")
				this.o:=0
			if (value>this.maxSize)
				this.parentClass.exception("struct " this.name " has exceeded maximum size " this.maxSize " by " value-this.maxSize " bytes.",,-3)
			return this.o:=value
		} get {
			return this.o
		}
	}
	pointer{
		set{
			this.parentClass.exception("Access denied.",,-3)
		} get {
			return this.ptr
		}
	}
	__Delete(){
		this.parentClass.mem.globalFree(this.ptr)
	}
}