%include "Morgenroetev1.inc"

;Define VGA_DRIVER to not define GraphicDriverInterface at the same time as extern and as global
%define VGA_DRIVER

;Inlcude vga_driver overwriting the file macro
INCLUDE "graphics/vga_driver.inc"


;Holds the physical information about which graphic driver is loaded at the moment
global GraphicDriverInterface
GraphicDriverInterface:
	times (IGraphicDriver_size/8) dq DummyFunction


;Every function defined in IGraphicDriver points to this DummyFunction first
DummyFunction:
	mov rax, 0x123456
	mov rbx, 0x7FDAA
	jmp $

A_character db 0x3C, 0x66, 0xC0, 0xC0, 0xCE, 0x66, 0x3A, 0x00



;Load VGADriver functions into the global interface function
DeclareFunction LoadVGADriver
	mov qword[ GraphicDriverInterface + IGraphicDriver.clearScreen ], ClearScreen
	
	mov rdi, graphic_720x480x16
	call write_vga_regs


	mov cl, 0
	call set_plane
	call ClearScreen

	mov cl, 1
	call set_plane
	call ClearScreen

	mov cl, 2
	call set_plane
	call ClearScreen

	mov cl, 3
	call set_plane
	call ClearScreen

	mov cl, 1
	call set_plane

	mov r8, 0

	mov rdi, 0xA0000
	mov esi, 0
	
.PlotBefore:
	mov bl, 0xFF
	mov cl, 0
	.PlotAgain:
		mov al, byte[esi+A_character]
		and bl, al
		not al
		and cl, al
		or bl, cl
		mov byte[ edi ], bl
		add edi, (720/8)
	mov bl, 0xFF
	mov cl, 0

	add esi, 1
	cmp esi, 8
	jnz .PlotAgain

	mov esi, 0
	mov edi, 0xA0001
	add r8, 1
	cmp r8, 2
	jnz .PlotBefore
	
	jmp $
EndFunction

;Declare a function which will 
DeclareFunction ClearScreen, Color
	xor eax, eax
	mov rdi, 0xA0000
	mov rcx, (720*480/8)
	rep stosb
EndFunction

%macro outportb 2
	%if %1 > 0xFF
		mov dx, %1
		mov al, %2
		out dx, al
	%else
		mov al, %2
		out %1, al
	%endif
%endmacro

%macro inportb 1
	%if %1 > 0xFF
		mov dx, %1
		in al, dx
	%else
		in al, %1
	%endif
%endmacro

;edi = mode dump
write_vga_regs:
	outportb VGA_MISC_WRITE, byte[ edi ]
	add edi, 1

	xor cx, cx

	.loop0:
		outportb VGA_SEQ_INDEX, cl
		outportb VGA_SEQ_DATA, byte[ edi ]
		add edi, 1
		add cx, 1
		cmp cx, VGA_NUM_SEQ_REGS
		jnz .loop0

	outportb VGA_CRTC_INDEX, 0x03

	inportb VGA_CRTC_DATA
	or al, 0x80
	outportb VGA_CRTC_DATA, al
	outportb VGA_CRTC_INDEX, 0x11
	inportb VGA_CRTC_DATA
	and al, ~0x80
	outportb VGA_CRTC_DATA, al

	or byte[edi+0x03], 0x80
	and byte[edi+0x11], ~0x80

	xor cx, cx

	.loop1:
		outportb VGA_CRTC_INDEX, cl
		outportb VGA_CRTC_DATA, byte[ edi ]
		add edi, 1
		add cx, 1
		cmp cx, VGA_NUM_CRTC_REGS
		jnz .loop1

	xor cx, cx

	.loop2:
		outportb VGA_GC_INDEX, cl
		outportb VGA_GC_DATA, byte[ edi ]
		add edi, 1
		add cx, 1
		cmp cx, VGA_NUM_GC_REGS
		jnz .loop2

	xor cx, cx

	.loop3:
		inportb VGA_INSTAT_READ
		outportb VGA_AC_INDEX, cl
		outportb VGA_AC_WRITE, byte[ edi ]
		add edi, 1
		add cx, 1
		cmp cx, VGA_NUM_AC_REGS
		jnz .loop3


	inportb VGA_INSTAT_READ
	outportb VGA_AC_INDEX, 0x20
	ret

;cl = number of plane
set_plane:
	mov bl, 1
	and cl, 3
	shl bl, cl

	outportb VGA_GC_INDEX, 4
	outportb VGA_GC_DATA, cl

	outportb VGA_SEQ_INDEX, 2
	outportb VGA_SEQ_DATA, bl

	ret



graphic_720x480x16:
	.misc db 0xE7
	.seq db 0x03, 0x01, 0x08, 0x00, 0x06
	.crtc db 0x6B, 0x59, 0x5A, 0x82, 0x60, 0x8D, 0x0B, 0x3E,0x00, 0x40, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00,0xEA, 0x0C, 0xDF, 0x2D, 0x08, 0xE8, 0x05, 0xE3,0xFF
	.gc db 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x05, 0x0F,0xFF
	.ac db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,0x01, 0x00, 0x0F, 0x00, 0x00

