%ifndef _KRNEL_HEAP_INC_
%define _KRNEL_HEAP_INC_
%include "Morgenroetev1.inc"

DefineFunction InitialiseHeap, 1
DefineFunction malloc, 2
DefineFunction free,1
DefineFunction VerifyBlock, 1
DefineFunction PrintMemoryMap, 0
DefineFunction CleanupHeap, 0

interface_open HeapInfoBlock
	add next, dword
	add size, dword
	add alloc_reason, dword
interface_close

%define FREE_BLOCK 0

%endif
