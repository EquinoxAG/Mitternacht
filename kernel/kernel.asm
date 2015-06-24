%include "Morgenroetev1.inc"
INCLUDE "boot/multiboot.inc"
INCLUDE "graphics/vga_driver.inc"

DefineFunction kernelMain, 1, 'kernel.asm'

;The main function takes one argument
DeclareFunction kernelMain, MbrStrucAddr
	mov rax, Arg_MbrStrucAddr

	mov_ts edi, dword[ (rax->multibootSup).mmap_addr ]

	secure_call LoadVGADriver
	secure_call ClearScreen, 0x4F
	jmp $
EndFunction
