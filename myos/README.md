# myos

A simple hobby OS with a custom bootloader and a freestanding C++ kernel.

## Build

- Requires: `nasm`, `gcc` (i386), `ld`, `dd`
- Run `make` to build the OS image (`build/myos.iso`).
- Run `make clean` to remove build artifacts.

## Structure

- `boot/boot.asm`: Boot sector (MBR, LBA 0)
- `boot/loader.asm`: Second-stage loader (LBA 1)
- `kernel/boot.s`: 32-bit entry stub
- `kernel/kmain.cpp`: C++ kernel entry
- `kernel/console.cpp`/`console.hpp`: VGA text console
- `kernel/linker.ld`: Linker script (kernel at 0x10000)
