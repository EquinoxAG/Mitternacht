all:
	nasm -f elf64 -o ./bin/prekernel.elf ./boot/prekernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	nasm -f bin -o ./bin/bootloader.bin ./boot/mbr.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	nasm -f elf64 -o ./bin/vga_driver.elf ./kernel/graphics/vga_driver.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	nasm -f elf64 -o ./bin/pmemory_driver.elf ./kernel/memory/pmemory.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	nasm -f elf64 -o ./bin/vmemory_driver.elf ./kernel/memory/vmemory.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	nasm -f elf64 -o ./bin/string.elf ./kernel/string/string.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/prekernel.elf ./bin/kernel.elf ./bin/vga_driver.elf ./bin/pmemory_driver.elf ./bin/vmemory_driver.elf ./bin/string.elf
	cat ./bin/kernel.bin >> ./bin/bootloader.bin
	./appender ./bin/bootloader.bin ./bin/bootloader.bin

debug_kernel:
	nasm -e -o output.asm ./kernel/kernel.asm  -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	vim output.asm
	rm output.asm
debug_string:
	nasm -o output.asm -e ./kernel/string/string.asm  -i ./kernel/include/ -i ./kernel/include/Morgenroete/
	vim output.asm
	rm output.asm

clean:
	rm ./bin/prekernel.elf
	rm ./bin/kernel.elf
	rm ./bin/vga_driver.elf
	rm ./bin/pmemory_driver.elf
	rm ./bin/vmemory_driver.elf
	rm ./bin/string.elf

