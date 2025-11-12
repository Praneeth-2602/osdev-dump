ENTRY(_start)
SECTIONS
{
    . = 0x00010000;     /* Kernel loads at 0x10000 physical */

    /* Code section */
    .text ALIGN(4K) : {
        *(.text*)
    }

    /* Read-only data section */
    .rodata ALIGN(4K) : {
        *(.rodata*)
    }

    /* Initialized data section */
    .data ALIGN(4K) : {
        *(.data*)
    }

    /* Uninitialized data section */
    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss*)
    }

    /* End of kernel - for debugging */
    kernel_end = .;
}