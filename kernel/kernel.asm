%include "Morgenroetev1.inc"
INCLUDE "boot/multiboot.inc"
INCLUDE "graphics/vga_driver.inc"
INCLUDE "memory/physical_memory.inc"
INCLUDE "memory/virtual_memory.inc"

DefineFunction kernelMain, 1, 'kernel.asm'

;The main function takes one argument
DeclareFunction kernelMain, MbrStrucAddr
	mov qword[MbrStrucAddr], Arg_MbrStrucAddr

	secure_call LoadVGADriver
	secure_call SetBackgroundAttribute,COLOR_BLACK
	secure_call ClearScreen
	secure_call SetForegroundAttribute, COLOR_WHITE
	secure_call DrawString, DrawStr

	mov ebx, dword[ MbrStrucAddr ]
	mov edi, dword[ ebx + multiboot.mmap_addr ]
	mov esi, dword[ ebx + multiboot.mmap_length ]
	secure_call InitialiseMemoryManager, rdi, rsi
	secure_call IsFreeMemoryRange, 0x0, 0x1000
	secure_call InitialiseVirtualMemory, BOOTUP_PML4_ADDR
	jmp $
EndFunction

DrawStr db 'Hallo',0x0A,'Welt from kernel: Very very very long long long string in your neighbarhood, even longer string',0

section .bss
MbrStrucAddr resq 0
