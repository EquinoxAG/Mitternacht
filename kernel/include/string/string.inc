%ifndef _KRNL_STRING_INC_
%define _KRNL_STRING_INC_
%include "Morgenroetev1.inc"

interface_open KString
	add length, qword
	add str_ptr, qword
	add max_strlen, qword
interface_close
interface_constructor KString, StrConstructor


DefineFunction KString::StrConstructor, 2
DefineFunction KString::c_str,0
DefineFunction KString::append_str, 1
DefineFunction KString::append_int, 1
DefineFunction KString::append_inth, 1
DefineFunction KString::nline,0 
DefineFunction KString::clear, 0 

%endif