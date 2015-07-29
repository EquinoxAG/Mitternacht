%include "Morgenroetev1.inc"
INCLUDE "boot/multiboot.inc"
INCLUDE "graphics/vga_driver.inc"
INCLUDE "memory/physical_memory.inc"
INCLUDE "memory/virtual_memory.inc"
INCLUDE "heap/heap.inc"
INCLUDE "string/string.inc"
INCLUDE "ata/ata_driver.inc"

;The main function takes one argument
global kernelMain
kernelMain:
	CreateStack kernelSt

	mov qword[MbrStrucAddr], rdi

	secure_call LoadVGADriver()
	secure_call SetBackgroundAttribute( COLOR_BLACK )
	secure_call ClearScreen()
	secure_call SetForegroundAttribute( COLOR_WHITE )

	mov ebx, dword[ MbrStrucAddr ]
	mov edi, dword[ ebx + multiboot.mmap_addr ]
	mov esi, dword[ ebx + multiboot.mmap_length ]
	secure_call InitialiseMemoryManager( rdi, rsi )


	secure_call InitialiseVirtualMemory(BOOTUP_PML4_ADDR)

	secure_call InitialiseHeap( 0x200000 )

	secure_call InitialiseAtaDriver()

	DestroyStack kernelSt
	jmp $


DrawStr db 'Hallo Master File',0x0A,'Welt from kernel',CONSOLE_CHANGEFG(COLOR_RED),'String red background',0

section .bss
MbrStrucAddr resq 0

ImportAllMgrFunctions
