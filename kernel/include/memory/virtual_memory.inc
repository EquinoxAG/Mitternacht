%ifndef _VIRTUAL_MEMORY_INC_
%define _VIRTUAL_MEMORY_INC_
%include "Morgenroetev1.inc"

%define BOOTUP_PML4_ADDR 0x600000
%define BOOTUP_FIRST_USABLE_ADDR (BOOTUP_PML4_ADDR+0x3000)


%define PAGE_READ_4KB 1
%define PAGE_READ_WRITE_4KB 2
%define PAGE_READ_WRITE_EXECUTE_4KB 4
%define PAGE_READ_2MB 9
%define PAGE_READ_WRITE_2MB 10
%define PAGE_READ_WRITE_EXECUTE_2MB 12

%define PAGE_CACHE_UC 0
%define PAGE_CACHE_WT 1
%define PAGE_CACHE_WB 2
%define PAGE_CACHE_STRONG_UC 4
%define PAGE_CACHE_WC 8
%define PAGE_CACHE_WP 0x10

%define IA32_PAT_MSR 0x277

%define PAT_MEM_TYPE_UC 0
%define PAT_MEM_TYPE_WC 1
%define PAT_MEM_TYPE_WT 4
%define PAT_MEM_TYPE_WP 5
%define PAT_MEM_TYPE_WB 6
%define PAT_MEM_TYPE_UCWEAK 7

DefineFunction InitialiseVirtualMemory, 1
;1= Virtual address, 2 = physical address, 3 = Page attributes 4 = cache type,
;DefineFunction MapVirtToPhys, 4, 'vmemory.asm'





%endif
