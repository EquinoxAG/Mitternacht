%ifndef _ACPI_KERNEL_INC_
%define _ACPI_KERNEL_INC_

%include "Morgenroetev1.inc"

interface_open RootSystemDescriptionPointer
	add signature, qword
	add checksum, byte
	add oem_first, dword
	add oem_sec, word
	add revision, byte
	add rsdt_addr, dword
interface_close

interface_open RootSystemDescriptionPointer20
	DeriveInterface RootSystemDescriptionPointer
	add length, dword
	add xsdt_addr, qword
	add ext_check, byte
	add padd_0, word
	add padd_1, byte
interface_close

interface_open ACPISystemDescriptorTableHeader
	add signature, dword
	add length, dword
	add revision, byte
	add checksum, byte
	add oem_id0, dword
	add oem_id1, word
	add oem_table_id, qword
	add oem_rev, dword
	add creator_id, dword
	add creator_rev, dword
interface_close

interface_open eXtendedSDT
	DeriveInterface ACPISystemDescriptorTableHeader
	add ptr_start, qword
interface_close

interface_open rootSDT
	DeriveInterface ACPISystemDescriptorTableHeader
	add ptr_start, dword
interface_close

interface_open MultipleApicDescTable
	DeriveInterface ACPISystemDescriptorTableHeader
	add local_apic_addr, dword
	add flags, dword
	add var_length_entrys, byte
interface_close




DefineFunction InitialiseACPI, 0

%define RSDP_Signature 'RSD PTR '
%define XSDT_Signature 'XSDT'
%define RSDT_Signature 'RSDT'
%define MADT_Signature 'APIC'

%endif
