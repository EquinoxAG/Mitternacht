struc MPConfigTable
	.signature resd 1
	.base_length resw 1
	.sv_signature resb 1
	.checksum resb 1
	.oem_str resq 1
	.product_id resd 3
	.oem_table_ptr resd 1
	.oem_table_size resw 1
	.entry_count resw 1
	.lapic_addr resd 1
	.extended_table_length resw 1
	.extended_checksum resb 1
	.reserved resb 1
	.entry_begin resb 1
endstruc


%define MPCONFIG_PROCESSOR_SIG 0
struc MPConfigEntryProcessor
	.signature resb 1
	.lapic_id resb 1
	.lapic_ver resb 1
	.cpu_flags resb 1
	.cpu_signature resd 1
	.flags resd 1
	.reserved resd 2
endstruc

%define MPCONFIG_BUS_SIG 1
struc MPConfigEntryBus
	.signature resb 1
	.bus_id resb 1
	.bus_string resb 6
endstruc

%define MPCONFIG_IOAPIC_SIG 2
struc MPConfigEntryIOApic
	.signature resb 1
	.id resb 1
	.ver resb 1
	.flags resb 1
	.address resd 1	
endstruc



struc FloatingPointTable
	.signature resd 1
	.mp_config_addr resd 1
	.length resb 1
	.spec_rev resb 1
	.checksum resb 1
	.feature1 resb 1
	.feature25 resd 1
endstruc
