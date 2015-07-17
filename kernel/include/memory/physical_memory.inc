%ifndef _PHYSICAL_MEMORY_MASTER_FILE_
%define _PHYSICAL_MEMORY_MASTER_FILE_

%include "Morgenroetev1.inc"


interface_open MemoryMap
	add entry_length, dword
	add base_address, qword
	add length, qword
	add type, dword
	add acpi3_0, dword
interface_close

interface_open InternMemoryMap
	add type, dword
	add next, dword
interface_close

DefineFunction InitialiseMemoryManager, 2
DefineFunction IsFreeMemoryRange, 2
DefineFunction BlockFreeMemoryRange, 2
DefineFunction AllocateMemory, 2

%define MEM_PAGE_SIZE 0x10000
%define MEM_PAGE_MASK 0x0FFFF
%define MEM_PAGE_SIZE_SHR 16
%define BYTES_PER_PAGE 8
%define BYTES_PER_PAGE_SHL 3


%define MEM_FREE 0
%define MEM_RESERVED 1
%define MEM_UNUSABLE 2

%endif
