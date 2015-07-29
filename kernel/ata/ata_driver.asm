%include "ata/ata_driver.inc"
INCLUDE "graphics/vga_driver.inc"

DeclareFunction InitialiseAtaDriver()
	mov dx, (ATA_BUS0+ATA_IO_HEAD)
	mov al, 0xA0
	out dx, al

	mov dx, (ATA_BUS0+ATA_IO_SECCOUNT)
	xor al, al
	out dx, al

	add dx, 1
	out dx, al

	add dx, 1
	out dx, al

	add dx, 1
	out dx, al

	mov al, 0xEC
	mov dx, (ATA_BUS0+ATA_IO_CMD)
	out dx, al


	.again:
		in al, dx
		or al, al
		jz .no_Dev

		test al, 0x80
		jnz .again
		
		test al, 1
		jnz .no_Dev

		test al, 8
		jz .again

		mov dx, (ATA_BUS0+ATA_IO_DATA)
		mov edi, DataIoDev
		mov ecx, 256
		rep insw

		xor rax, rax
		mov edi, DataIoDev+54

		mov byte[ edi + 40 ], 0
		
		secure_call DrawString( rdi )
		jmp $


	.no_Dev:
		mov rax, 0x13224325
		jmp $
	

EndFunction

section .bss
DataIoDev resw 256

ImportAllMgrFunctions
