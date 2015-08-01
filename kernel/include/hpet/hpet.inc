%ifndef _HIGH_PERFORMANCE_EVENT_TIMER_HPP_
%define _HIGH_PERFORMANCE_EVENT_TIMER_HPP_

%include "Morgenroetev1.inc"

interface_open HPETRegisters
	add GeneralCapabilitys, qword
	add GeneralConfiguration, 0x10, qword
	add GeneralInterruptStatus, 0x20, qword
	add MainCounterValue, 0xF0, qword
	add Timer0Config, 0x100, qword
	add Timer0Comp, 0x108, qword
	add Timer0IntrRoute, 0x110, qword
interface_close

DefineFunction SupplyHPETTable, 1
DefineFunction InitialiseHPET, 0

%endif
