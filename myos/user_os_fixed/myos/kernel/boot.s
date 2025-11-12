.section .text
.global _start
.extern kmain

_start:
    # We're already in protected mode with a basic GDT
    # Stack is already set up by loader
    
    # Clear screen with simple attribute
    movl $0xB8000, %edi     # Start of video memory
    movw $0x0720, %ax       # Light gray on black, space char (simple plain text)
    movl $2000, %ecx        # 80*25 = 2000 characters total
    rep stosw               # Fill screen with spaces (16-bit stores)
    
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
