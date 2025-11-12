
; boot.asm — MBR boot sector (stage1)
org 0x7C00
bits 16

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    ; Print message
    mov si, msg_boot
    call puts

    ; Read loader (LBA 1) to 0x7E00
    mov ah, 0x02        ; BIOS read sectors
    mov al, 2           ; 2 sectors (to ensure loader code fits)
    mov ch, 0           ; cylinder 0
    mov cl, 2           ; sector 2 (LBA 1)
    mov dh, 0           ; head 0
    mov dl, [boot_drive]
    mov bx, 0           ; ES:BX = 0:0x7E00
    mov es, bx
    mov bx, 0x7E00      
    int 0x13
    jc disk_error

    jmp 0x0000:0x7E00   ; jump to loader

disk_error:
    mov si, msg_fail
    call puts
.disk_hang:
    cli
    hlt
    jmp .disk_hang

puts:
    pusha
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007      ; BH = page 0, BL = light gray
    int 0x10
    jmp .loop
.done:
    popa
    ret

boot_drive: db 0
msg_boot: db 'myos boot...', 0
msg_fail: db 'Boot error!', 0

.end_hang:
    cli
    hlt
    jmp .end_hang

times 510-($-$$) db 0
dw 0xAA55
