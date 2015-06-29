%include "Morgenroetev1.inc"
INCLUDE "memory/physical_memory.inc"

extern kernel_start
extern kernel_end

;----------------------------------------------------------------------------------
;Initialises the memory bitmap as well as reserving the reserved areas of memory
;---------------------------------------------------------------------------------
DeclareFunction InitialiseMemoryManager, memoryMap, memoryMapLength
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

	mov rbx, rdx							;Reload the memory map address
	mov rcx, r8							;Reload the memory map length

	;Freeing all memory which is defined by the memory Map E820 as free
	.startBlockingRanges:
		cmp dword[ rbx + MemoryMap.type ], 1		;Free memory?
		jz .free_memory_ranges				;Yes free the memory

	.selectNextBlock:					;Okay select next entry
		sub ecx, dword[ rbx + MemoryMap.entry_length ]
		add ebx, dword[ rbx + MemoryMap.entry_length ]
		add rbx, 4
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

			test eax, eax
			jz .selectNextBlock					;Select next block if no pages to free

		.make_free:
			mov esi, dword[ physical_memory_manager.first_entry ]		;The next entry
			mov_ts dword[ (edi->InternMemoryMap).next ], esi		;The next entry of the current free block is the last first free block
			mov_ts dword[ (edi->InternMemoryMap).type ], MEM_FREE		;memory is free
			mov dword[ physical_memory_manager.first_entry ], edi		;The next first entry of the memory map is the current one
			add edi, InternMemoryMap_size					;Select next memory map entry addr
			add qword[ physical_memory_manager.free_memory ], MEM_PAGE_SIZE	;Calculate amount of free memory
			sub eax, 1							;Check if there are more pages to free
			jnz .make_free
			jmp .selectNextBlock
	.done:
		;The memory map is set up by now and should work properly, therefore block important memory ranges
		mov edi, kernel_start
		mov esi, dword[ physical_memory_manager.mmap_end ]
		sub esi, edi
		secure_call BlockFreeMemoryRange,rdi, rsi, Msg_kernel_resides	;Block the kernel code and the bitmap
EndFunction

;Checks if the specified memory range is completely free
DeclareFunction IsFreeMemoryRange, PhysMemStart, PhysMemLength
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
		cmp dword[ edi + InternMemoryMap.type ], 0
		jnz .failed
		add edi, InternMemoryMap_size
		sub esi, 1
		jnz .startDeterminating
		xor eax, eax
		jmp .endFunc
	.failed:
		mov eax, dword[ edi + InternMemoryMap.next ]
	.endFunc:
EndFunction

DeclareFunction BlockFreeMemoryRange, PhysMemStart, PhysMemSize, Message
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
		mov rdx, Arg_Message
		mov dword[ edi + InternMemoryMap.next ], edx
		mov dword[ edi + InternMemoryMap.type ], MEM_RESERVED
		add edi, InternMemoryMap_size
		sub esi, 1
		jnz .startBlocking
EndFunction

Msg_kernel_resides db 'Kernel code and memory bitmap',0
Msg_blocked_mem db 'Unusable memory',0
section .bss
physical_memory_manager:
	.mmap_beg resd 1
	.mmap_end resd 1
	.first_entry resd 1
	.free_memory resq 1
