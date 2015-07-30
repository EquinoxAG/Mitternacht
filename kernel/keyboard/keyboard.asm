%include "keyboard/keyboard.inc"
INCLUDE "graphics/vga_driver.inc"

asciiNonShift db NULL, ESC, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', BACKSPACE,\
TAB, 'q', 'w',   'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',   '[', ']', ENTER, 0,\
'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\\',\
'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0,\
KF1, KF2, KF3, KF4, KF5, KF6, KF7, KF8, KF9, KF10, 0, 0,\
KHOME, KUP, KPGUP,'-', KLEFT, '5', KRIGHT, '+', KEND, KDOWN, KPGDN, KINS, KDEL, 0, 0, 0, KF11, KF12


asciiShift db NULL, ESC, '!', '"', '§', '$', '%', '&', '/', '(', ')', '=', '?', '`', BACKSPACE,\
TAB, 'Q', 'W',   'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',   '{', '}', ENTER, 0,\
'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, '|',\
'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0,\
KF1,   KF2, KF3, KF4, KF5, KF6, KF7, KF8, KF9, KF10, 0, 0,\
KHOME, KUP, KPGUP, '-', KLEFT, '5',   KRIGHT, '+', KEND, KDOWN, KPGDN, KINS, KDEL, 0, 0, 0, KF11, KF12



DeclareFunction Getline()
	mov rbx, KeyboardBuffer

	xor rax, rax
	.wait:
		in al, 0x64
		test al, 1
		jz .wait
		in al, 0x60
		test al, 0x80
		jnz .wait

		add rax, asciiNonShift
		mov al, byte[ rax ]
		and eax, 0xFF

		cmp al, ENTER
		jz .done

		mov byte[ rbx ], al
		add rbx, 1

		secure_call DrawCharacter( rax )
		xor rax, rax
		jmp .wait
	.done:
		mov byte[ rbx ], 0
		mov rax, KeyboardBuffer
EndFunction

DeclareFunction WaitForEnter()

	secure_call DrawString({0x0A,"Please press enter to continue...",0x0A})

	.wait:
		in al, 0x64
		test al, 1
		jz .wait
		in al, 0x60
		test al, 0x80
		jnz .wait


		cmp al, 0x1C
		jz .done
		
		add rax, asciiNonShift
		mov al, byte[ rax ]
		and eax, 0xFF
		secure_call DrawCharacter( rax )
		xor rax, rax
		jmp .wait

	.done:
EndFunction

ImportAllMgrFunctions

section .bss
KeyboardBuffer resb 64
