%include "Morgenroetev1.inc"
INCLUDE "memory/physical_memory.inc"
INCLUDE "memory/virtual_memory.inc"
INCLUDE "string/string.inc"
INCLUDE "graphics/vga_driver.inc"

extern kernel_start
extern kernel_end

;----------------------------------------------------------------------------------
;Initialises the memory bitmap as well as reserving the reserved areas of memory
;---------------------------------------------------------------------------------
DeclareFunction InitialiseMemoryManager( memoryMap, memoryMapLength )
	mov qword[ physical_memory_manager.e820_addr ], Arg_memoryMap
	mov qword[ physical_memory_manager.e820_size ], Arg_memoryMapLength

	mov rcx, Arg_memoryMapLength			;Load the length of the E820 memory map
	xor rsi, rsi					;Maximal memory address is zero at the beginning
	mov r8, rcx					;Backup the length of the E820 memory map

	mov rax, Arg_memoryMap				; Backup the address of the E820 memory map

	;This loop should calculate the maximal address of memory in this system
	.calculateMaxAddress:
		mov_ts rdx, qword[ (rdi->MemoryMap).base_address ]	;Load the base address
		cmp rdx, rsi						;greater than the old highest base addres? No the select next entry
		js .next_addr

		mov rsi, rdx						;Else load the new highest base address
		mov rbx, rdi						;Load the entry address of the highest base address

	.next_addr:
		mov r15d, edi						;Select last entry
		sub ecx, dword[ rdi + MemoryMap.entry_length ]		;Subtract the inspected bytes
		add edi, dword[ rdi + MemoryMap.entry_length ]		;Select the next entry
		add edi, 4						;The MemoryMap.entry_length field only specifies the length of the structure without itself
		sub ecx, 4						;Therefore 4 bytes more must be substracted and added
		jnz .calculateMaxAddress

	mov rdx, rax							;Load the address of the memory map
	mov_ts rax, qword[ (rbx->MemoryMap).base_address ]		;Load the highest base address
	add rax, qword[ rbx + MemoryMap.length ]			;Calculate the highest accessible address in the system
	shr rax, (MEM_PAGE_SIZE_SHR)					;Calculate the number of pages that must be created to describe the system memory
	mov rcx, rax							;Backup the number of pages, to make them all unusable at the beginning
	shl rax, (BYTES_PER_PAGE_SHL)					;Calculate the bitmap size out of the number of pages
	mov rsi, kernel_end						;Calculate the bitmap start, it starts after the next available 32-byte aligned address after the kernel_end
	add rsi, 32							;Make the address 32 byte aligned
	and si, 0xFFE0
	mov dword[ physical_memory_manager.mmap_beg ], esi		;Store the memory map begin
	add rax, rsi							;Calculate the memory map end
	mov dword[ physical_memory_manager.mmap_end ], eax		;Store the memory map end
	mov qword[ physical_memory_manager.free_memory ], 0		;No free memory till now

	.FillTable:
		mov_ts dword[ (rsi->InternMemoryMap).type ], MEM_UNUSABLE	;At the beginning all memory is unusable
		mov_ts dword[ (rsi->InternMemoryMap).next ], Msg_blocked_mem	;Every memory chunk gets the message, that the memory is unusable
		add esi, InternMemoryMap_size					;Select next entry
		sub ecx, 1					;		;ecx holds the number of pages, every time one page descriptor was written, there is one page less to write to
		jnz .FillTable

	mov rdx, r15
	mov rbx, rdx							;Reload the memory map address
	mov rcx, r8							;Reload the memory map length


	;Freeing all memory which is defined by the memory Map E820 as free
	.startBlockingRanges:
		cmp dword[ rbx + MemoryMap.type ], 1		;Free memory?
		jz .free_memory_ranges				;Yes free the memory

	.selectNextBlock:					;Okay select next entry
		sub ecx, dword[ rbx + MemoryMap.entry_length ]
		sub ebx, dword[ rbx + MemoryMap.entry_length ]
		sub rbx, 4
		sub rcx, 4
		jnz .startBlockingRanges

		jmp .done		;All entrys worked up return to callee

		.free_memory_ranges:
			mov_ts rdi, qword[ (rbx->MemoryMap).base_address ]	;Load the base address
			shr rdi, (MEM_PAGE_SIZE_SHR)				;Calculate off of the base address the page number
			mov_ts rax, qword[ (rbx->MemoryMap).length ]		;Load the length of the entry
			shl edi, (BYTES_PER_PAGE_SHL)				;Calculate the actual offset in the memory map off of the page number
			add edi, dword[ physical_memory_manager.mmap_beg ]	;Calculate the absolute address of the memory map entry to start with
			shr rax, (MEM_PAGE_SIZE_SHR)				;Calculate the number of pages to free

			mov rdx, rax
			shl rdx, 3
			sub rdx, InternMemoryMap_size
			add edi, edx


			test eax, eax
			jz .selectNextBlock					;Select next block if no pages to free

		.make_free:
			mov esi, dword[ physical_memory_manager.first_entry ]		;The next entry
			mov_ts dword[ (edi->InternMemoryMap).next ], esi		;The next entry of the current free block is the last first free block
			mov_ts dword[ (edi->InternMemoryMap).type ], MEM_FREE		;memory is free
			mov dword[ physical_memory_manager.first_entry ], edi		;The next first entry of the memory map is the current one

			sub edi, InternMemoryMap_size					;Select next memory map entry addr
			add qword[ physical_memory_manager.free_memory ], MEM_PAGE_SIZE	;Calculate amount of free memory
			sub eax, 1							;Check if there are more pages to free
			jnz .make_free
			jmp .selectNextBlock
	.done:


		;Block the first memory page, it contains the BIOS interrupt table as well as some important data
		xor edi, edi
		mov esi, MEM_PAGE_SIZE
		secure_call BlockFreeMemoryRange( rdi, rsi )

		;The memory map is set up by now and should work properly, therefore block important memory ranges
		mov edi, kernel_start
		mov esi, dword[ physical_memory_manager.mmap_end ]
		sub esi, edi
		secure_call BlockFreeMemoryRange(rdi, rsi)	;Block the kernel code and the bitmap

		;Block the address wehere the paging structs reside as well as 1 MB for the stack
		mov edi, 0x500000
		mov esi, 0x500000
		secure_call BlockFreeMemoryRange( rdi, rsi)
EndFunction


;Prints the E820 memory Map given from the bootloader
DeclareFunction PrintMemoryMapE820()

	;Load the address of the memory map and the size
	mov ebx, dword[ physical_memory_manager.e820_addr ]
	mov r15d, dword[ physical_memory_manager.e820_size ]

	;Make space for the string buffer
	ReserveStackSpace HeaderStr, KString1024	;Allocate a string with a buffer of 1024 bytes
	UpdateStackPtr

	;Printing the given E820 memory map!
	secure_call HeaderStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE),0x0A, "Printing E820: memory map!" })

	.PrintMap:
		secure_call HeaderStr.append_str( {0x0A,"Base Address: ",CONSOLE_CHANGEFG(COLOR_RED)} )

		mov_ts rax, qword[ (rbx->MemoryMap).base_address ]	;Load the base address
		secure_call HeaderStr.append_inth( rax )		;Append the base address to the HeaderStr

		secure_call HeaderStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE)," | Length: ",CONSOLE_CHANGEFG(COLOR_RED)} )
		mov_ts rax, qword[ (rbx->MemoryMap).length ]
		secure_call HeaderStr.append_inth( rax )

		mov_ts eax, dword[ (rbx->MemoryMap).type ]
		cmp eax, 1
		jnz .reserved

		secure_call HeaderStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE)," | Free Memory"} )

		jmp .selectNext
		.reserved:
			cmp eax, 3
			jns .acpi_shit
			secure_call HeaderStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE)," | Reserved Memory"} )
			jmp .selectNext
		.acpi_shit:
			secure_call HeaderStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE), " | ACPI Reclaimable"})

		.selectNext:

		sub r15d, dword[ rbx + MemoryMap.entry_length]
		add ebx, dword[ rbx + MemoryMap.entry_length ]
		add ebx, 4
		sub r15d, 4
		ja .PrintMap


	secure_call HeaderStr.c_str()
	secure_call DrawString( rax )
EndFunction


DeclareFunction AllocateMemory( size, flags )
	ReserveStackSpace MemFlags, qword
	ReserveStackSpace VMemAddr, qword
	ReserveStackSpace rbx_backup, qword
	UpdateStackPtr

	mov_ts qword[ rbx_backup ], rbx
	mov r15, Arg_size
	mov_ts qword[ MemFlags ], Arg_flags

	secure_call ReserveVirtMemRange( r15 )

	mov_ts qword[ VMemAddr ], rax
	mov rbx, rax


	mov edi, dword[ physical_memory_manager.first_entry ]
	xor rcx, rcx

	.StartMapping:
		mov eax, dword[ edi + InternMemoryMap.next ]
		mov dword[ physical_memory_manager.first_entry ], eax
	
		cmp dword[ edi + InternMemoryMap.type ], MEM_FREE
		jnz .selectNext

		mov dword[ edi + InternMemoryMap.type ], MEM_RESERVED

		sub edi, dword[ physical_memory_manager.mmap_beg ]
		shl edi, (MEM_PAGE_SIZE_SHR-BYTES_PER_PAGE_SHL)
		

		push rax
		mov rax, rdi
		
		secure_call MapVirtToPhys( rbx, rax, MEM_PAGE_SIZE, qword[ MemFlags ] ) 

		pop rax


		sub r15, MEM_PAGE_SIZE
		jbe .done

		add rbx, MEM_PAGE_SIZE

		.selectNext:
			or eax, eax
			jz .fatal_no_mem

			mov edi, eax
			jmp .StartMapping

		.fatal_no_mem:
			mov rcx, 0xFAD
			jmp $

	.done:
		mov_ts rax, qword[ VMemAddr ]
		mov_ts rbx, qword[ rbx_backup ]
EndFunction

;Checks if the specified memory range is completely free
DeclareFunction IsFreeMemoryRange(PhysMemStart, PhysMemLength)
	test Arg_PhysMemLength, MEM_PAGE_MASK
	jz .startSearching

	add Arg_PhysMemLength, MEM_PAGE_SIZE
	and esi, ~MEM_PAGE_MASK

	.startSearching:
		shr rdi, (MEM_PAGE_SIZE_SHR)
		shr esi, (MEM_PAGE_SIZE_SHR)
		shl edi, (BYTES_PER_PAGE_SHL)
		add edi, dword[ physical_memory_manager.mmap_beg ]
	.startDeterminating:
		cmp dword[ edi + InternMemoryMap.type ], MEM_FREE
		jnz .failed
		add edi, InternMemoryMap_size
		sub esi, 1
		jnz .startDeterminating
		xor eax, eax
		jmp .endFunc
	.failed:
		mov eax, dword[ edi + InternMemoryMap.next ]
		cmp byte[ edi + InternMemoryMap.type ], MEM_UNUSABLE
		jnz .endFunc
		mov eax, Msg_blocked_mem
	.endFunc:
EndFunction

DeclareFunction BlockFreeMemoryRange( PhysMemStart, PhysMemSize)
	test Arg_PhysMemSize, MEM_PAGE_MASK
	jz .startBlock

	add Arg_PhysMemSize, MEM_PAGE_SIZE
	and esi, ~MEM_PAGE_MASK

	.startBlock:
		shr rdi, (MEM_PAGE_SIZE_SHR)
		shr esi, (MEM_PAGE_SIZE_SHR)
		shl edi, BYTES_PER_PAGE_SHL
		add edi, dword[ physical_memory_manager.mmap_beg ]

	.startBlocking:
		cmp dword[ edi + InternMemoryMap.type ], 0
		jnz .no_change
			sub qword[ physical_memory_manager.free_memory ], MEM_PAGE_SIZE
		.no_change:
		mov dword[ edi + InternMemoryMap.type ], MEM_UNUSABLE
		add edi, InternMemoryMap_size
		sub esi, 1
		jnz .startBlocking
EndFunction

Msg_blocked_mem db 'Unusable memory',0

ImportAllMgrFunctions
section .bss
physical_memory_manager:
	.e820_addr resd 1
	.e820_size resd 1
	.mmap_beg resd 1
	.mmap_end resd 1
	.first_entry resd 1
	.last_entry resd 1
	.free_memory resq 1
