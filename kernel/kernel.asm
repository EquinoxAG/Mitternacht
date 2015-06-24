%include "Morgenroete/Morgenroetev1.inc"

DefineCall kernelMain, 1, 'kernel.asm'



;The main function takes one argument
DeclareCall kernelMain, 1
	mov rax, Argument_0
	jmp $
EndFunction
