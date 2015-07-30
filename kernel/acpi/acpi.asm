%include "acpi/acpi.inc"
INCLUDE "graphics/vga_driver.inc"
INCLUDE "string/string.inc"
INCLUDE "memory/virtual_memory.inc"

DeclareFunction InitialiseACPI()
	mov edi, WhokayDokay

	ReserveStackSpace CurrStr, KString1024
	UpdateStackPtr
	movzx edi, word[ 0x40E ]
	
	mov ecx, 0x1000		;Search in the first KB

	mov rax, RSDP_Signature
	
	.SearchForRSDP:
		cmp qword[ edi ], rax
		jz .found

		add edi, 16
		sub ecx, 16
		jnz .SearchForRSDP

		cmp edi, 0x100000
		jz Errors.no_acpi

		mov edi, 0xE0000
		mov ecx, 0x20000
		jmp .SearchForRSDP


	.found:
		mov qword[ RootSystemDescPtr ], rdi
		
		cmp byte[ edi + RootSystemDescriptionPointer.revision ], 0
		jz .acpi_1

		mov esi, dword[ edi + RootSystemDescriptionPointer20.length ]
		call ValidateChecksum
		jc Errors.wrong_checksum

		mov rax, qword[ edi + RootSystemDescriptionPointer20.xsdt_addr ]
		mov qword[ SystemDescriptorTable ], rax 
		mov qword[ ACPIPtrSize ], 8

		secure_call DrawString( {0x0A, "Parsed ACPI Tables, 64-bit XSDT ACPI Rev 2+"})
		jmp .end

	.acpi_1:
		mov esi, RootSystemDescriptionPointer_size
		
		call ValidateChecksum
		jc Errors.wrong_checksum

		mov eax, dword[ edi + RootSystemDescriptionPointer.rsdt_addr ]
		mov dword[ SystemDescriptorTable ], eax
		mov qword[ ACPIPtrSize ], 4

		secure_call DrawString( {0x0A, "Parsed ACPI Tables, 32-bit RSDT ACPI Rev 1"})
	.end:
	
	.StartParsingDescTable:
		secure_call CurrStr.append_str( {0x0A, "XSDT/RSDP Address: "})
		mov rbx, qword[ SystemDescriptorTable ]
		secure_call CurrStr.append_inth( rbx )
		secure_call CurrStr.c_str()
		secure_call DrawString( rax )
		
		mov rbx, qword[ SystemDescriptorTable ]
		secure_call MapVirtToPhys( rbx, rbx, 0x1000, PAGE_READ_WRITE_EXECUTE|PAGE_CACHE_TYPE_WT)

		mov r15d, dword[ rbx + ACPISystemDescriptorTableHeader.length ]
		sub r15d, ACPISystemDescriptorTableHeader_size
		add rbx, eXtendedSDT.ptr_start
		jmp $

EndFunction

Errors:
	.no_acpi:
		secure_call DrawString({0x0A,CONSOLE_CHANGEFG(COLOR_BRIGHTRED),"No acpi available"})
		jmp $
	.wrong_checksum:
		secure_call DrawString({0x0A, CONSOLE_CHANGEFG(COLOR_BRIGHTRED),"Wrong checksum in acpi table"})
		jmp $
	


;edi = address, esi = length
ValidateChecksum:
	push rdi
	mov al, byte[ edi ]
	
	add edi, 1
	sub esi, 1

	.Validate:
		add al, byte[ edi ]
		add edi, 1
		sub esi, 1
		jnz .Validate

		test al, al
		jnz .failed

		pop rdi
		clc
		ret
	.failed:
		pop rdi
		stc
		ret

ImportAllMgrFunctions

WhokayDokay db 'Ya molo',0
section .bss
RootSystemDescPtr resq 1
SystemDescriptorTable resq 1
ACPIPtrSize resq 1
