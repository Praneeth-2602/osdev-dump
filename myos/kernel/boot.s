.section .text
.global _start
.extern kmain

_start:
    # We're already in protected mode with a basic GDT
    # Stack is already set up by loader
    
    # Write "K" at top left to show we reached kernel (debug)
    movl $0xB8000, %edi     # Start of video memory
    movl $0x0F4B, %eax      # Bright white K
    movw %ax, (%edi)
    
    # Clear rest of screen (write spaces with normal attribute)
    addl $2, %edi           # Skip the K we just wrote
    movl $0x07200720, %eax  # Normal attribute, space char (2 spaces)
    movl $499, %ecx         # (80*25-1)/2 = 999/2 = ~499 dwords
    rep stosl               # Fill screen with spaces
    
    # Call C++ kernel main
    call kmain
    
    # If kmain returns, halt the processor
1:  hlt
    jmp 1b

# Reserve stack space if needed
.section .bss
.align 16
stack_bottom:
.skip 16384             # 16 KB
stack_top: