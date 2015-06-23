struc multiboot
	.flags resd 1
	.mem_lower resd 1
	.mem_upper resd 1
	.bootdevice resd 1
	.commandline resd 1
	.mod_count resd 1
	.mod_addr resd 1
	.sys resd 4
	.mmap_length resd 1
	.mmap_addr resd 1
	.drives_length resd 1
	.drives_addr resd 1
	.config_table resd 1
	.bootloader_name resd 1
	.apm_table resd 1
	.vbe_ctrl_info resd 1
	.vbe_mode_info resd 1
	.vbe_mode resw 1
	.vbe_interface_seg resw 1
	.vbe_interface_off resw 1
	.vbe_interface_len resw 1
endstruc


%define MultibootStrucAddr 0x500 ;Address at which the multiootstructure will be relocated to or written by the self written bootloader to
%define MemMapAddr 0x600 ;Relocates the MemMap to address 0x600 or if the bootloader from PerfOS is used create it at that address
