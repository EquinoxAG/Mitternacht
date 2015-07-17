%ifndef _VIRTUAL_MEMORY_INC_
%define _VIRTUAL_MEMORY_INC_
%include "Morgenroetev1.inc"

%define BOOTUP_PML4_ADDR 0x600000
%define BOOTUP_FIRST_USABLE_ADDR (BOOTUP_PML4_ADDR+0x3000)


%define PAGE_READ 0x20000
%define PAGE_READ_WRITE 0x40000
%define PAGE_READ_WRITE_EXECUTE 0x80000
%define PAGE_USR_ACCESS 0x100000


%define IA32_PAT_MSR 0x277

%define PAT_MEM_TYPE_UC 0
%define PAT_MEM_TYPE_WC 1
%define PAT_MEM_TYPE_WT 4
%define PAT_MEM_TYPE_WP 5
%define PAT_MEM_TYPE_WB 6
%define PAT_MEM_TYPE_UCWEAK 7

%define PAGE_CACHE_TYPE_WB 0
%define PAGE_CACHE_TYPE_WT 1
%define PAGE_CACHE_TYPE_UCWEAK 2
%define PAGE_CACHE_TYPE_UC 3
%define PAGE_CACHE_TYPE_WP 6
%define PAGE_CACHE_TYPE_WC 7


DefineFunction InitialiseVirtualMemory, 1
;1= Virtual address, 2 = physical address, 3 = Length 4 = cache type,
DefineFunction MapVirtToPhys, 4
DefineFunction ReserveVirtMemRange, 1




%endif
