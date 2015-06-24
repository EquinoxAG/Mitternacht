nasm -f elf64 -o ./bin/prekernel.elf ./boot/prekernel.asm -i ./kernel/include/
nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
nasm -f bin -o ./bin/bootloader.bin ./boot/mbr.asm -i ./kernel/include/
ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/prekernel.elf ./bin/kernel.elf
cat ./bin/kernel.bin >> ./bin/bootloader.bin
./appender ./bin/bootloader.bin ./bin/bootloader.bin
rm ./bin/prekernel.elf
rm ./bin/kernel.elf

