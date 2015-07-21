%include "Morgenroetev1.inc"
INCLUDE "heap/heap.inc"
INCLUDE "memory/physical_memory.inc"
INCLUDE "memory/virtual_memory.inc"
INCLUDE "string/string.inc"
INCLUDE "graphics/vga_driver.inc"

DeclareFunction InitialiseHeap( size )
	mov rbx, Arg_size

	test ebx, MEM_PAGE_MASK
	jz .alignedPage

	and ebx, ~MEM_PAGE_MASK
	add ebx, MEM_PAGE_SIZE
	
	.alignedPage:

	mov dword[ HeapSettings.size ], ebx

	secure_call AllocateMemory( rbx, PAGE_READ_WRITE|PAGE_CACHE_TYPE_WT )
	mov dword[ HeapSettings.PhysicalAddr ], eax
	mov edi, eax
	mov dword[ eax + HeapInfoBlock.next ], 0
	add edi, ebx

	sub ebx, HeapInfoBlock_size

	mov dword[ eax + HeapInfoBlock.size ], ebx
	mov dword[ eax + HeapInfoBlock.alloc_reason ], FREE_BLOCK

	mov dword[ HeapSettings.PhysicalAddrEnd ], edi

	mov dword[ HeapSettings.first_entry ], eax
EndFunction

DeclareFunction malloc( size, DescStr )
	mov r8, Arg_DescStr
	mov rcx, Arg_size
	mov edi, dword[ HeapSettings.first_entry ]
	add ecx, HeapInfoBlock_size

	.StartTraverse:
		mov edx, dword[ edi + HeapInfoBlock.size ]

		cmp edx, ecx
		jns .block_access

	.loadNextBlock:
		mov edi, dword[ edi + HeapInfoBlock.next ]
		test edi, edi
		jnz .StartTraverse
		jmp FatalError

	.block_access:
		mov eax, edx
	.block_access_no_eax:
		sub edx, ecx
		lock cmpxchg dword[ edi + HeapInfoBlock.size ], edx
		jz .found_block
		;okay failed to lock the block, eax holds the new size of the block
		;Still big enough?
		cmp eax, ecx
		js .loadNextBlock
		;Okay block is still big enough
		mov edx, eax
		;Therefore try the lock again!
		jmp .block_access_no_eax

;Locked the block, just split it now
	.found_block:
		;Calculate the end of the memory block
		add edi, edx
		add edi, HeapInfoBlock_size

		sub ecx, HeapInfoBlock_size

		mov esi, DefaultMemUsage
		test r8d, r8d
		cmovz r8d, esi

		mov dword[ edi + HeapInfoBlock.alloc_reason ], r8d	;Save the decription for what the memory will be use
		mov eax, edi
		mov dword[ edi + HeapInfoBlock.size ], ecx
		add eax, HeapInfoBlock_size
EndFunction

DeclareFunction PrintMemoryMap()
	sub rsp, 2000
	mov rdx, rsp
	ReserveStackSpace MemMapStr, KString, rdx, 2000
	UpdateStackPtr

	xor r15, r15
	mov ebx, dword[ HeapSettings.PhysicalAddr ]
	secure_call MemMapStr.append_str( {0x0A,"Memory map of the heap!"} )
	.PrintMemMap:
		secure_call MemMapStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE),0x0A,"Base addr: ", CONSOLE_CHANGEFG(COLOR_BROWN)} )
		mov eax, ebx
		add eax, HeapInfoBlock_size
		secure_call MemMapStr.append_inth( rax )
		secure_call MemMapStr.append_str( {CONSOLE_CHANGEFG( COLOR_WHITE), " | Length: ", CONSOLE_CHANGEFG(COLOR_BROWN)})
		mov eax, dword[ ebx + HeapInfoBlock.size ]
		secure_call MemMapStr.append_inth( rax )
		
		mov eax, dword[ ebx + HeapInfoBlock.alloc_reason ]
		test eax, eax
		jnz .str
		
		secure_call MemMapStr.append_str( {CONSOLE_CHANGEFG(COLOR_WHITE), " | Usage: ", CONSOLE_CHANGEFG(COLOR_BROWN),"Free memory"})
		jmp .selectNext

		.str:
			push rax
			secure_call MemMapStr.append_str({CONSOLE_CHANGEFG(COLOR_WHITE), " | Usage: ", CONSOLE_CHANGEFG(COLOR_BROWN)})
			pop rax
			secure_call MemMapStr.append_str( rax )

	
		.selectNext:
			add ebx, dword[ ebx + HeapInfoBlock.size ]
			add ebx, HeapInfoBlock_size

			cmp ebx, dword[ HeapSettings.PhysicalAddrEnd ]
			jnz .PrintMemMap

		secure_call MemMapStr.c_str()
		secure_call DrawString(rax)
EndFunction

FatalError:
	jmp $

DeclareFunction free(addr)
	sub Arg_addr, HeapInfoBlock_size
	mov dword[ Arg_addr + HeapInfoBlock.alloc_reason ], 0

	mov esi, dword[ HeapSettings.first_entry ]

	.TryAgain:
		mov eax, esi
		mov dword[ Arg_addr + HeapInfoBlock.next ], eax
		mov rsi, Arg_addr

		lock cmpxchg dword[ HeapSettings.first_entry ], esi
		jnz .TryAgain

EndFunction

CleanupHeapMutex dd 0
CleaFreeList dd 0
DeclareFunction CleanupHeap()
	mov al, 1
	xchg byte[ CleanupHeap ], al
	test al, al
	jnz .end

	mov edi, dword[ HeapSettings.first_entry ]

	.end:
EndFunction

DefaultMemUsage db 'Not specified',0
ImportAllMgrFunctions
section .bss
HeapSettings:
	.PhysicalAddr resd 1
	.PhysicalAddrEnd resd 1
	.size resd 1
	.first_entry resd 1
