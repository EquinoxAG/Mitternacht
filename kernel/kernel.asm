%include "Morgenroetev1.inc"
INCLUDE "boot/multiboot.inc"
INCLUDE "graphics/vga_driver.inc"
INCLUDE "memory/physical_memory.inc"
INCLUDE "memory/virtual_memory.inc"
INCLUDE "heap/heap.inc"
INCLUDE "string/string.inc"
INCLUDE "ata/ata_driver.inc"
INCLUDE "acpi/acpi.inc"
INCLUDE "keyboard/keyboard.inc"
INCLUDE "apic/apic.inc"
INCLUDE "exception/exception.inc"
INCLUDE "hpet/hpet.inc"

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


	secure_call PrintPhysicalMemMap()

	secure_call InitialiseACPI()
	
	secure_call InitialiseAPIC()

	secure_call InitialiseHPET()

	DestroyStack kernelSt
	jmp $


section .bss
MbrStrucAddr resq 0

ImportAllMgrFunctions
