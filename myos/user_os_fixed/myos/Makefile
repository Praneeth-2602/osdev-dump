# Makefile — builds BIOS boot sector → stage2 loader → 32-bit C++ kernel

ASM = nasm
QEMU = qemu-system-i386
IMG = build/os.img

# Prefer cross; fallback to host 32-bit toolchain
CROSS ?= i686-elf-
CC := $(CROSS)gcc
LD := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy

# Fallback if cross not found
ifeq (, $(shell which $(CC) 2>/dev/null))
CC := gcc
LD := ld
OBJCOPY := objcopy
CFLAGS_EXTRA := -m32
LDFLAGS_EXTRA := -m elf_i386
endif

CXX := $(CC)

CFLAGS = -O2 -ffreestanding -fno-asynchronous-unwind-tables -fno-exceptions -fno-rtti -nostdlib -nostartfiles $(CFLAGS_EXTRA)
CXXFLAGS= $(CFLAGS) -std=c++17 -fno-rtti -fno-exceptions
LDFLAGS = -nostdlib -z max-page-size=0x1000 $(LDFLAGS_EXTRA)

KERNEL_SECTORS ?= 64  # default; overridden when building loader from kernel size

.PHONY: all run clean dirs

all: dirs $(IMG)

run: all
	$(QEMU) -drive format=raw,file=$(IMG)

clean:
	rm -rf build

# -----------------------
# Disk image layout (raw):
# LBA 0 : boot sector (stage1)
# LBA 1-2 : stage2 loader (2 sectors)
# LBA 3.. : flat kernel (KERNEL_SECTORS sectors)
# -----------------------

$(IMG): build/boot.bin build/loader.bin build/kernel.bin
	dd if=/dev/zero of=$(IMG) bs=512 count=2880 status=none
	# stage1 at LBA0
	dd if=build/boot.bin of=$(IMG) bs=512 count=1 conv=notrunc status=none
	# stage2 at LBA1 (2 sectors)
	dd if=build/loader.bin of=$(IMG) bs=512 seek=1 conv=notrunc status=none
	# kernel at LBA3 (after 2-sector loader)
	dd if=build/kernel.bin of=$(IMG) bs=512 seek=3 conv=notrunc status=none

# Boot sector (512B)
build/boot.bin: boot/boot.asm | dirs
	$(ASM) -f bin $< -o $@

# Stage2 loader (up to 1024B, uses 2 sectors)
build/loader.bin: boot/loader.asm build/kernel.bin | dirs
	SECTORS=$$(( ( $$(wc -c < build/kernel.bin) + 511 ) / 512 )); \
	$(ASM) -f bin -D KERNEL_SECTORS=$$SECTORS $< -o $@
	# Ensure loader.bin is exactly 1024 bytes (2 sectors)
	truncate -s 1024 $@

# Kernel (flat 32-bit binary)
build/kernel.bin: build/kernel.elf | dirs
	$(OBJCOPY) -O binary $< $@

build/kernel.elf: kernel/boot.s kernel/console.cpp kernel/kmain.cpp kernel/linker.ld | dirs
	$(CXX) $(CXXFLAGS) -Ikernel -c kernel/console.cpp -o build/console.o
	$(CXX) $(CXXFLAGS) -Ikernel -c kernel/kmain.cpp -o build/kmain.o
	$(CC) $(CFLAGS) -c kernel/boot.s -o build/boot.o
	$(LD) $(LDFLAGS) -T kernel/linker.ld -o $@ build/boot.o build/console.o build/kmain.o

dirs:
	mkdir -p build