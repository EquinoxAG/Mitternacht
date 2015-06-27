%include "Morgenroetev1.inc"
INCLUDE "boot/multiboot.inc"
INCLUDE "graphics/vga_driver.inc"

DefineFunction kernelMain, 1, 'kernel.asm'

;The main function takes one argument
DeclareFunction kernelMain, MbrStrucAddr
	mov rax, Arg_MbrStrucAddr

	mov_ts edi, dword[ (rax->multibootSup).mmap_addr ]

	secure_call LoadVGADriver
	secure_call SetBackgroundAttribute,COLOR_BLUE
	secure_call ClearScreen
	secure_call SetBackgroundAttribute, COLOR_RED
	secure_call SetForegroundAttribute, COLOR_BLACK
	secure_call DrawString, DrawStr
	jmp $
EndFunction


DrawStr db 'Hallo Welt from kernel: Very very very long long long string in your neighbarhood, even longer string',0
