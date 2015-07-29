%ifndef _ATA_DRIVER_INC_
%define _ATA_DRIVER_INC_

%include "Morgenroetev1.inc"

DefineFunction InitialiseAtaDriver, 0

%define ATA_BUS0 0x1F0
%define ATA_DEVCTRL0 0x3F6

%define ATA_IO_DATA 0
%define ATA_IO_FEATURE 1
%define ATA_IO_SECCOUNT 2
%define ATA_IO_SECNUM 3
%define ATA_IO_LBAMID 4
%define ATA_IO_LBAHI 5
%define ATA_IO_HEAD 6
%define ATA_IO_CMD 7


%endif
