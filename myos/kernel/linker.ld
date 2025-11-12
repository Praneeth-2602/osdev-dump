ENTRY(_start)
OUTPUT_FORMAT(elf32-i386)

SECTIONS
{
    . = 0x00010000;       /* Kernel loads at 0x10000 physical (1 MB + 64 KB) */

    /* Code section */
    .text ALIGN(4K) : 
    {
        *(.text*)
    }

    /* Read-only data section */
    .rodata ALIGN(4K) : 
    {
        *(.rodata*)
    }

    /* Initialized data section */
    .data ALIGN(4K) : 
    {
        *(.data*)
    }

    /* Uninitialized data section */
    .bss ALIGN(4K) : 
    {
        *(COMMON)
        *(.bss*)
    }
    
    /* End of kernel - for debugging */
    kernel_end = .;
}