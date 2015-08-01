all: boot/prekernel.asm kernel/kernel.asm boot/mbr.asm kernel/graphics/vga_driver.asm kernel/memory/pmemory.asm kernel/memory/vmemory.asm kernel/string/string.asm kernel/heap/heap.asm kernel/keyboard/keyboard.asm kernel/ata/ata_driver.asm kernel/acpi/acpi.asm kernel/apic/apic.asm kernel/exception/exception.asm kernel/hpet/hpet.asm link_all
	
boot/prekernel.asm:
	nasm -f elf64 -o ./bin/prekernel.elf ./boot/prekernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/kernel.asm:
	nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
boot/mbr.asm:
	nasm -f bin -o ./bin/bootloader.bin ./boot/mbr.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/graphics/vga_driver.asm:
	nasm -f elf64 -o ./bin/vga_driver.elf ./kernel/graphics/vga_driver.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/memory/pmemory.asm:
	nasm -f elf64 -o ./bin/pmemory_driver.elf ./kernel/memory/pmemory.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/memory/vmemory.asm:
	nasm -f elf64 -o ./bin/vmemory_driver.elf ./kernel/memory/vmemory.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/string/string.asm:
	nasm -f elf64 -o ./bin/string.elf ./kernel/string/string.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/heap/heap.asm:
	nasm -f elf64 -o ./bin/heap.elf ./kernel/heap/heap.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/ata/ata_driver.asm:
	nasm -f elf64 -o ./bin/ata_driver.elf ./kernel/ata/ata_driver.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/acpi/acpi.asm:
	nasm -f elf64 -o ./bin/acpi_driver.elf ./kernel/acpi/acpi.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/keyboard/keyboard.asm:
	nasm -f elf64 -o ./bin/keyboard.elf ./kernel/keyboard/keyboard.asm -i kernel/include/ -i ./kernel/include/Morgenroete/
kernel/apic/apic.asm:
	nasm -f elf64 -o ./bin/apic.elf ./kernel/apic/apic.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/exception/exception.asm:
	nasm -f elf64 -o ./bin/exceptions.elf ./kernel/exception/exception.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/hpet/hpet.asm:
	nasm -f elf64 -o ./bin/hpet.elf ./kernel/hpet/hpet.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/

link_all: boot/mbr.asm	
	ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/prekernel.elf ./bin/kernel.elf ./bin/vga_driver.elf ./bin/pmemory_driver.elf ./bin/vmemory_driver.elf ./bin/string.elf ./bin/heap.elf ./bin/ata_driver.elf ./bin/acpi_driver.elf ./bin/keyboard.elf ./bin/apic.elf ./bin/exceptions.elf ./bin/hpet.elf
	cat ./bin/kernel.bin >> ./bin/bootloader.bin
	./appender ./bin/bootloader.bin ./bin/bootloader.bin


.PHONY: boot/prekernel.asm kernel/keyboard/keyboard.asm kernel/kernel.asm boot/mbr.asm kernel/graphics/vga_driver.asm kernel/memory/pmemory.asm kernel/memory/vmemory.asm kernel/string/string.asm kernel/heap/heap.asm kernel/ata/ata_driver.asm kernel/acpi/acpi.asm kernel/apic/apic.asm kernel/exception/exception.asm kernel/hpet/hpet.asm link_all


clean:
	rm ./bin/prekernel.elf
	rm ./bin/kernel.elf
	rm ./bin/vga_driver.elf
	rm ./bin/pmemory_driver.elf
	rm ./bin/vmemory_driver.elf
	rm ./bin/string.elf
	rm ./bin/heap.elf
	rm ./bin/ata_driver.elf
	rm ./bin/acpi_driver.elf
	rm ./bin/keyboard.elf
	rm ./bin/apic.elf
	rm ./bin/exceptions.elf
	rm ./bin/hpet.elf
