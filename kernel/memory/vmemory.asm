%include "Morgenroetev1.inc"
INCLUDE "memory/virtual_memory.inc"


interface_open FreemapHead
	add nextHead, qword
	add size, qword
interface_close

interface_open FreemapEntry
	add VirtAddr, qword
	add size, qword
interface_close

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
		jmp $

	.end_function:
		mov qword[ virtual_memory_driver.efer_nxe_bit ], 0

		mov eax, 0x80000001
		cpuid
		test edx, (1<<20)
		jz .no_nxe

		mov ecx, 0xC0000080
		rdmsr
		or eax, (1<<11)
		wrmsr
		
		mov rax, 1
		ror rax, 1
		mov qword[ virtual_memory_driver.efer_nxe_bit ], rax

		.no_nxe:


		mov rdi, BOOTUP_FIRST_USABLE_ADDR
		mov rcx,  (0xA00000-(BOOTUP_FIRST_USABLE_ADDR+0x1000))	;Cause the first 10 MB were mapped

		mov qword[ virtual_memory_driver.first_freemap_head ], rdi
		mov qword[ rdi + FreemapHead.nextHead ], 0
		mov qword[ rdi + FreemapHead.size ], (0x1000-16)
		mov qword[ rdi + 16 + FreemapEntry.VirtAddr ], 0xA00000
		mov eax, 0xFFFFFFFF
		shl rax, 16

		mov qword[ rdi + 16 + FreemapEntry.size ], rax
		

		add rdi, 0x1000
		mov qword[ virtual_memory_driver.mem_pool ], rdi
		
		mov rax, rdi
		.MapAllMem:
			add rax, 0x1000
			mov qword[ rdi ], rax
			
			mov rdi, rax

			sub rcx, 0x1000
			jnz .MapAllMem

			sub rdi, 0x1000
			mov qword[ rdi ], 0
EndFunction


;rdi = addr of the entry, rsi = phys addr, r12 = flags of the page
CreatePagePat2MB:
	and esi, 0xFFE00000
	
	mov si, r12w
	and si, 0x0003		;Set up PAT bits
	shl si, 3

	test r12d, 0x4
	jz .noHigh

	or esi, (1<<12)
.noHigh:	
	or rsi, 0x81		;Page is present and size bit is set

	test r12d, (PAGE_READ_WRITE|PAGE_READ_WRITE_EXECUTE)
	jz .not_writable

	or rsi, 2		;Make page writable

.not_writable:
	test r12d, PAGE_USR_ACCESS
	jz .no_usr_access

	or rsi, 4		;Enable User access

.no_usr_access:
	test r12d, PAGE_READ_WRITE_EXECUTE
	jnz .write_page

	or rsi, qword[ virtual_memory_driver.efer_nxe_bit ]

.write_page:
	mov qword[ rdi ], rsi
	ret

CreatePagePat4KB:
	and esi, 0xFFFFF000

	mov ax, r12w
	shl ax, 3
	or si, ax

	test r12d, 0x4
	jz CreatePagePat2MB.noHigh

	or esi, (1<<7)
	jmp CreatePagePat2MB.noHigh






DeclareFunction ReserveVirtMemRange( size )
	mov rax, Arg_size
	test ax, 0xFFF
	jz .startSearch

	add eax, 0x1000
	and ax, 0xF000

	.startSearch:
	mov rdi, qword[ virtual_memory_driver.first_freemap_head ]
	mov rcx, qword[ rdi + FreemapHead.size ]
	mov rsi, rdi

	.SearchVirtRange:
		add rdi, 16
		cmp qword[ rdi + FreemapEntry.size ], rax
		js .selectNextEntry

		mov rsi, qword[ rdi + FreemapEntry.VirtAddr ]
		add qword[ rdi + FreemapEntry.VirtAddr ], rax
		sub qword[ rdi + FreemapEntry.size ], rax
		
		mov rax, rsi
		jmp .done

	.selectNextEntry:
		add rdi, FreemapEntry_size
		sub rcx, FreemapEntry_size
		jnz .SearchVirtRange

		mov rdi, qword[ rsi + FreemapHead.nextHead ]
		mov rcx, qword[ rdi + FreemapHead.size ]

		test rdi, rdi
		jnz .SearchVirtRange
	.fatal:
		hlt
		jmp $

	.done:

EndFunction

DeclareFunction MapVirtToPhys( VirtMemAddr, PhysMemAddr, Length, Flags )
	push r15
	mov r15, Arg_VirtMemAddr
	mov r14, Arg_PhysMemAddr
	mov r13, Arg_Length
	mov r12, Arg_Flags

	and r15d, 0xFFFFF000
	
	test r14d, 0xFFF
	jz .no_pad
		add r13, 0x1000
	.no_pad:
		and r14d, 0xFFFFF000



	mov r11, r15
	mov r10, r15
	mov r9, r15
	mov r8, r15
	pop r15
	shr r11, 36
	shr r10, 27
	shr r9, 18
	shr r8, 9
	and r11d, 0xFF8
	and r10d, 0xFF8
	and r9d, 0xFF8
	and r8d, 0xFF8


	.ReenterAddressCalculation:

	mov rdi, qword[ virtual_memory_driver.pml4_addr ]

	add rdi, r11		;Calculate the offset in the PML4 Table
	test byte[ rdi ], 1	;Is PML4 entry active?
	jz .CreateNewPML4Entry
	mov rdi, qword[ rdi ]


	and di, 0xF000

	.HasActivePML4:

		add rdi, r10

		test byte[ rdi ], 1
		jz .CreateNewPDPTE


		mov rdi, qword[ rdi ]
		and di, 0xF000
	.HasActivePDPTE:
		add rdi, r9

		test r14d, 0x1FFFFF
		jz .GranCheck

	.Prepare4KB:
		test byte[ rdi ], 1
		jz .CreateNewPDPT

		test byte[ rdi ], (1<<7)
		jnz .CreateNewPDPT


		mov rdi, qword[ rdi ]
		and di, 0xF000

	.HasActivePDPT:
		add rdi, r8
		jmp .Map4KBs

	.GranCheck:
		cmp r13, 0x200000
		jns .MapVirtToPhys

		cmp r13, 0x1000
		js .done
		jmp .Prepare4KB

	.MapVirtToPhys:
		test byte[ rdi ], 1
		jz .perfectMap
		
		test byte[ rdi ], (1<<7)
		jnz .perfectMap

		mov rax, qword[ rdi ]
		and ax, 0xF000
		mov rsi, qword[ virtual_memory_driver.mem_pool ]
		mov qword[ rax ], rsi
		mov qword[ virtual_memory_driver.mem_pool ], rax

	.perfectMap:

		mov rsi, r14
		call CreatePagePat2MB

		sub r13, 0x200000
		add r14, 0x200000

	.CalculateNew2MB:
		add r9, 8
		cmp r9, 0x1000
		jz .CalculateNewAddr

		add rdi, 8
		jmp .GranCheck



	.CalculateNewAddr:
		xor r9, r9
		add r10, 8

		cmp r10, 0x1000
		jz .CalculateNewPML4
		add r10, 8
		jmp .ReenterAddressCalculation

	.CalculateNewPML4:
		xor r10, r10
		add r11, 8
		jmp .ReenterAddressCalculation




	.Map4KBs:
		cmp r13, 0x1000
		js .done

		.Map4KBPage:
			mov rsi, r14
			call CreatePagePat4KB

			sub r13, 0x1000
			add r14, 0x1000


			add r8, 8
			add rdi, 8

			cmp r8, 0x1000
			jnz .Map4KBs

			xor r8, r8

			add r9, 8
			cmp r9, 0x1000
			jnz .ReenterAddressCalculation
			jmp .CalculateNewAddr



	.CreateNewPML4Entry:
		push .HasActivePML4
	
	.CreateDirectory:
		mov rcx, qword[ virtual_memory_driver.mem_size ]
		mov rsi, qword[ virtual_memory_driver.mem_pool ]
		mov rax, qword[ rsi ]
		sub rcx, 0x1000
		mov qword[ virtual_memory_driver.mem_pool ], rax
		mov qword[ virtual_memory_driver.mem_size ], rcx

		or rsi, 1|2|4		;Page present, allow writing in 512GB-Section, Allow User access
		mov qword[ rdi ], rsi
		mov rdi, rsi
		and di, 0xF000
		ret

	.CreateNewPDPTE:
		push .HasActivePDPTE
		jmp .CreateDirectory

	.CreateNewPDPT:
		push .HasActivePDPT
		jmp .CreateDirectory


	.done:
		mov rax, qword[ virtual_memory_driver.pml4_addr ]
		mov cr3, rax
EndFunction




section .bss
virtual_memory_driver:
	.capabilitys resq 1
	.pml4_addr resq 1
	.mem_pool resq 1
	.mem_size resq 1
	.efer_nxe_bit resq 1
	.first_freemap_head resq 1
