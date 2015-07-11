%include "Morgenroetev1.inc"
INCLUDE "memory/virtual_memory.inc"

bitmap_open PageMapLevel4
	add present, 1
	add writeable, 1
	add useraccessable, 1
	add wt_caching, 1
	add no_caching, 1
	add dirty, 1
	add ignored, 1
	add reserved, 1
	add ignored2, 4
	add phys_addr, 50
	add not_executable, 1
bitmap_close

bitmap_open PageDirectoryPointerTable
	add present, 1
	add writeable, 1
	add useraccessable, 1
	add wt_caching, 1
	add no_caching, 1
	add dirty, 1
	add size_1gb_page, 1
	add global_page, 1
	add ignored, 3
	add pat, 1
	add phys_addr, 50
	add not_executable, 1
bitmap_close

bitmap_open PageDirectoryEntry
	add present, 1
	add writeable, 1
	add useraccessable, 1
	add wt_caching, 1
	add no_caching, 1
	add dirty, 1
	add size_2MB_page, 1
	add global_page, 1
	add ignored, 3
	add pat, 1
	add phys_addr, 50
	add not_executable, 1
bitmap_close

bitmap_open PageTableEntry
	add present, 1
	add writeable, 1
	add useraccessable, 1
	add wt_caching, 1
	add no_caching, 1
	add dirty, 1
	add pat, 1
	add global_page, 1
	add ignored, 3
	add phys_addr, 51
	add not_executable, 1
bitmap_close


DeclareFunction InitialiseVirtualMemory( PML4_addr )
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
		mov qword[ virtual_memory_driver.mem_pool ], BOOTUP_FIRST_USABLE_ADDR
		mov qword[ virtual_memory_driver.mem_size ], (0xA00000-BOOTUP_FIRST_USABLE_ADDR)	;Cause the first 10 MB were mapped
EndFunction



DeclareFunction MapPhysMem( MemSize, Flags )
	mov rcx, Arg_MemSize
	mov r8, Arg_Flags

	xor rax, rax

	mov rdi, qword[ virtual_memory_driver.pml4_addr ]
	mov r15, rdi
	add r15, 0x1000


	.CirculateThroughPML4:
		mov rsi, qword[ rdi ]
		test si, 1
		jz .selectNextPML4

		and rsi, PageMapLevel4.phys_addr.get(MGR_BMP_MASK)
		mov r14, rsi
		add r14, 0x1000


		.CirculateThroughPDPT:
			mov r9, qword[ rsi ]
			test r9d, 1
			jz .selectNextPDPT

			and r9, PageDirectoryPointerTable.phys_addr.get(MGR_BMP_MASK)
			mov r13, r9
			add r13, 0x1000

			.CirculateThroughPDT:
				mov r10, qword[ r9 ]
				test r10d, 1
				jz .selectNextPDT

			

			.selectNextPDT:
				add r9, 8
				cmp r9, r13
				jnz .CirculateThroughPDT



		.selectNextPDPT:
			add rsi, 8
			cmp r14, rsi
			jnz .CirculateThroughPDPT


	.selectNextPML4:
		add rdi, 8
		cmp r15, rdi
		jnz .CirculateThroughPML4

		mov rbx, 0xCA00
		jmp $

EndFunction

section .bss
virtual_memory_driver:
	.capabilitys resq 1
	.pml4_addr resq 1
	.mem_pool resq 1
	.mem_size resq 1
