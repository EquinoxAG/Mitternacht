%include "Morgenroetev1.inc"
INCLUDE "string/string.inc"


DeclareFunction KString::StrConstructor()
	mov_ts dword[ (Arg_this->KString).length ], 0
	mov_ts byte[ (Arg_this->KString).data ], 0
EndFunction

DeclareFunction KString::c_str()
	mov rax, rdi
	add rax, KString.data
EndFunction


DeclareFunction KString::append_str( app_str )
	mov rdx, Arg_this
	mov rcx, qword[ rdi ]
	add rdi, KString.data
	add rdi, rcx

	.copy_str:
		mov al, byte[ rsi ]
		test al, al
		jz .done

		mov byte[ rdi ], al
		add rsi, 1
		add rdi, 1

		add rcx, 1
		cmp rcx, (KString_size-9)
		js .copy_str
		xor al, al
	.done:
		mov byte[ rdi ], al
		mov qword[ rdx ], rcx
EndFunction

DeclareFunction KString::append_int( ival )
	sub rsp, 40
	mov rax, Arg_ival
	mov r8, Arg_this
	
	mov rdi, rsp
	add rdi, 38
	mov byte[ rdi ], 0
	sub rdi, 1

	mov rsi, r8
	mov ebx, 10
	xor edx, edx
	add rsi, KString.data
	
	mov ecx, 1	; 0 will always get transfered

	.LoopedOutput:
		div rbx
		add dl, 48
		mov byte[ rdi ], dl
		sub rdi, 1
		add ecx, 1
		xor rdx, rdx
		test rax, rax
		jnz .LoopedOutput

		add rdi, 1
		add rsi, qword[ r8 + KString.length ]
		xchg rdi, rsi
		sub ecx, 1
		add qword[ r8 + KString.length ], rcx
		add ecx, 1
		rep movsb
	
	add rsp, 40
EndFunction

DeclareFunction KString::nline()
	

EndFunction

DeclareFunction KString::append_inth( ival )
	mov rax, Arg_ival
	mov rdx, Arg_ival
	mov rsi, Arg_this
	mov r8, Arg_this
	add rsi, KString.data
	add rsi, qword[ r8 + KString.length ]
	mov byte[ rsi ], '0'
	mov byte[ rsi +1 ], 'x'
	add rsi, 2

	mov cl, 60
	.stLoop:
		shr rax, cl
		and al, 0x0F

		cmp al, 10
		jae .hex

		add al, 48
		jmp .cont
	.hex:
		add al, 55

	.cont:
		mov byte[ rsi ], al
		add rsi, 1
		mov rax, rdx
		sub cl, 4
		jns .stLoop
	
		mov byte[ rsi ], 0
EndFunction

ImportAllMgrFunctions
