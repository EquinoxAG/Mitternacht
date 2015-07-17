%ifndef _KRNL_STRING_INC_
%define _KRNL_STRING_INC_
%include "Morgenroetev1.inc"

interface_open KString
	add length, qword
	add data, qword
	add data0, qword
	add data1, qword
	add data2, qword
	add data3, qword
	add data4, qword
	add data5, qword
interface_close
interface_constructor KString, StrConstructor


DefineFunction KString::StrConstructor, 0
DefineFunction KString::c_str,0
DefineFunction KString::append_str, 1
DefineFunction KString::append_int, 1
DefineFunction KString::append_inth, 1
DefineFunction KString::nline,0 

%endif
