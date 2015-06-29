%include "Morgenroetev1.inc"
INCLUDE "memory/virtual_memory.inc"


DeclareFunction InitialiseVirtualMemory, PML4_addr
	mov qword[ virtual_memory_driver.pml4_addr ], Arg_PML4_addr
	mov eax, 1
	cpuid
	test edx, (1<<16)
	jz .no_pat


	mov eax, (PAT_MEM_TYPE_UC<<24)|(PAT_MEM_TYPE_UCWEAK<<16)|(PAT_MEM_TYPE_WT<<8)|(PAT_MEM_TYPE_WB)
	mov edx, (PAT_MEM_TYPE_WC<<24)|(PAT_MEM_TYPE_WP<<16)|(PAT_MEM_TYPE_WT<<8)|(PAT_MEM_TYPE_WB)
	mov ecx, IA32_PAT_MSR
	wrmsr		;Load the pat table

	mov qword[ virtual_memory_driver.capabilitys ], 1

	jmp .end_function

	.no_pat:
		mov qword[ virtual_memory_driver.capabilitys ], 0

	.end_function:
EndFunction


section .bss
virtual_memory_driver:
	.capabilitys resq 1
	.pml4_addr resq 1
