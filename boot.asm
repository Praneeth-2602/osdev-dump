BITS 16
ORG 0x7C00

start:
    ; DS:SI -> message
    xor ax, ax
    mov ds, ax
    mov si, msg

.print_loop:
    lodsb               ; AL = [DS:SI], SI++
    test al, al         ; reached '\0'?
    jz .done
    mov ah, 0x0E        ; BIOS teletype
    int 0x10
    jmp .print_loop

.done:
    jmp $               ; hang

msg db "Hello, World!", 0

times 510-($-$$) db 0
dw 0xAA55
