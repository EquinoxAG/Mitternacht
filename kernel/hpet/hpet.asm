%include "hpet/hpet.inc"
%include "acpi/acpi.inc"
%include "memory/virtual_memory.inc"
%include "apic/apic.inc"
%include "graphics/vga_driver.inc"

DeclareFunction SupplyHPETTable( hpet_reg_addr )
	mov qword[ HpetTableAddr ], Arg_hpet_reg_addr
EndFunction

DeclareFunction InitialiseHPET()
	mov rdi, qword[ HpetTableAddr ]
	test rdi, rdi
	jz .end

	mov rax, qword[ rdi + HPETDescriptionTable.base_addr_mid ]

	push rbx
	shl rax, 8
	shr rax, 8
	mov qword[ hpet_settings.hpet_reg_addr ], rax
	secure_call MapVirtToPhys( rax, rax, 0x1000, PAGE_READ_WRITE|PAGE_CACHE_TYPE_UC)

	mov rax, qword[ hpet_settings.hpet_reg_addr ]

	mov edx, dword[ rax + HPETRegisters.GeneralCapabilitys ]
	
	shr edx, 8
	and edx, 0x1F
	mov dword[ hpet_settings.num_timers ], edx


	mov ebx, dword[ rax + HPETRegisters.GeneralCapabilitys+4]
	xor edx, edx
	mov rax, (1000000000000000/1000)
	div rbx

	mov qword[ hpet_settings.ticks_1_ms ], rax
	pop rbx
	

	mov rax, qword[ hpet_settings.hpet_reg_addr ]

	mov rdx, qword[ rax + HPETRegisters.Timer0Config ]
	mov rcx, rdx
	
	shr edx, 32
	bsf edx, edx
	shl edx, 9
	or rcx, rdx
	shr edx, 9


	push rcx
	push rax
	secure_call MapIOAPICEntryToIRQ( rdx, 50 )
	secure_call SetIDTGate( 50,InterruptFires, 3 )
	pop rax
	pop rcx

	mov qword[ rax + HPETRegisters.MainCounterValue ], 0



	
	or rcx, ((1<<2)|(1<<6)|(1<<3))
	mov qword[ rax + HPETRegisters.Timer0Config ], rcx
	mov rdi, rax

	mov rax, qword[ hpet_settings.ticks_1_ms ]
	mov rbx, 1000
	mul rbx
	xor rdx, rdx
	mov qword[ rdi + HPETRegisters.Timer0Comp ], rax
	
	cli
	
	mov rax, qword[ rdi + HPETRegisters.GeneralConfiguration ]
	or rax, 1
	mov qword[ rdi + HPETRegisters.GeneralConfiguration ], rax

	fild qword[ dark ]
	fld1
	fdiv st1
	fst qword[ dark ]
	call ConvertToString


	jmp $

	

	.end:
EndFunction

;Convert IEE Floating point to string
ConvertToString:
	mov ecx, dword[ dark + 4 ]
	shr ecx, 20
	
	cmp ecx, 1023
	js .below1
	
	jmp $

	.below1:
		sub ecx, 1023
		not ecx
		add ecx, 1

		mov rax, 0x10000000000000
		mov rbx, qword[ dark ]
		and rbx, qword[ mask ]
		add rax, rbx
		jmp $

		xor rbx, rbx
		xor rdx, rdx
		
		bts rbx, rcx
		div rbx
		jmp $




	
	

InterruptFires:
	push rax
	secure_call DrawString({0x0A,"1 second passed"})
	secure_call sendEOI()
	pop rax
	iretq

HpetTableAddr dq 0

ticks dd 0
dark dq 3
mask dq 0xFFFFFFFFFFFFF

section .bss
hpet_settings:
	.hpet_reg_addr resq 1
	.flags resq 1
	.num_timers resq 1
	.ticks_1_ms resq 1
	.min_tick_count resq 1


ImportAllMgrFunctions
