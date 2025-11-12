; loader.asm - Second stage loader (LBA 1, loaded at 0x7E00)
org 0x7E00
bits 16

%define ENDL 0x0D, 0x0A
KERNEL_LOAD_SEG equ 0x1000

start:
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Print loading message
    mov si, msg_loading
    call print_string
    
    ; Convert kernel sectors to string and print
    mov ax, KERNEL_SECTORS
    call print_number
    
    mov si, msg_sectors
    call print_string

    ; Enable A20 line
    call enable_a20

    ; Load kernel (LBA 2.., KERNEL_SECTORS sectors) to 0x10000
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    xor bx, bx          ; ES:BX = 0x1000:0x0000 = physical 0x10000
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 3           ; sector 3 (LBA 2)
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc error

    ; Print success message
    mov si, msg_ok
    call print_string
    
    ; Setup GDT
    lgdt [gdt_descriptor]
    
    ; Switch to protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
        ; Disable interrupts
    cli
    
    ; Load IDT with null (we don't need interrupts yet)
    lidt [idt_descriptor]
    
    ; Far jump to 32-bit code to load CS with proper descriptor
    jmp 0x08:pmode_entry

; Real mode functions
; -------------------
print_string:
    pusha                   ; Save all registers
.next:
    lodsb                   ; Load byte from SI into AL
    or al, al               ; Test if end of string (0)
    jz .done                ; If zero, we're done
    mov ah, 0x0E            ; BIOS teletype function
    mov bx, 0x0007          ; BH = page 0, BL = light gray
    int 0x10                ; Call BIOS
    jmp .next               ; Loop to next character
.done:
    popa                    ; Restore all registers
    ret

print_number:
    pusha
    mov cx, 10          ; Divisor = 10 for decimal
    mov bx, 0           ; Counter for number of digits
    
    ; Handle zero case specially
    test ax, ax
    jnz .process
    mov al, '0'
    mov ah, 0x0E
    mov bx, 0x0007      ; BH = page 0, BL = light gray
    int 0x10
    jmp .done
    
.process:
    mov dx, 0           ; Clear DX for division
    div cx              ; AX/CX -> AX=quotient, DX=remainder
    push dx             ; Save remainder (will be a digit)
    inc bx              ; Count this digit
    test ax, ax         ; Is quotient zero?
    jnz .process        ; If not, keep processing
    
.print:
    pop ax              ; Get digit
    add al, '0'         ; Convert to ASCII
    mov ah, 0x0E        ; BIOS teletype
    push bx             ; Save counter
    mov bx, 0x0007      ; BH = page 0, BL = light gray
    int 0x10            ; Print character
    pop bx              ; Restore counter
    dec bx              ; Decrement counter
    jnz .print          ; If more digits, continue printing
    
.done:
    popa                ; Restore all registers
    ret

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

error:
    mov si, msg_error
    call print_string
    cli
    hlt

halt:
    cli
    hlt
    jmp halt

; 32-bit protected mode code
; -------------------------
bits 32
pmode_entry:
    ; Setup segment registers with data descriptor
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack at the top of conventional memory
    mov esp, 0x90000
    
    ; Clear direction flag
    cld
    
    ; Jump to kernel
    ; Visual marker to confirm successful mode switch
    mov dword [0xB8000], 0x07690748   ; "Hi" in white on black

    ; Jump to kernel entry point
    jmp KERNEL_LOAD_SEG:0x0000

; Data section
; -----------
bits 16
align 8

; GDT - Global Descriptor Table
gdt:
    ; Null descriptor
    dw 0            ; Limit (low)
    dw 0            ; Base (low)
    db 0            ; Base (middle)
    db 0            ; Access
    db 0            ; Granularity
    db 0            ; Base (high)
    
    ; Code segment descriptor (0x08)
    dw 0xFFFF       ; Limit (low): 0xFFFFF
    dw 0x0000       ; Base (low): 0x0
    db 0x00         ; Base (middle)
    db 10011010b    ; Access (exec/read, code, non-system)
    db 11001111b    ; Granularity (4KiB) + 32-bit + limit(high)
    db 0x00         ; Base (high)
    
    ; Data segment descriptor (0x10)
    dw 0xFFFF       ; Limit (low): 0xFFFFF
    dw 0x0000       ; Base (low): 0x0
    db 0x00         ; Base (middle)
    db 10010010b    ; Access (read/write, data, non-system)
    db 11001111b    ; Granularity (4KiB) + 32-bit + limit(high)
    db 0x00         ; Base (high)
gdt_end:

; Empty IDT (Interrupt Descriptor Table)
idt:
    times 8 db 0    ; Empty IDT entry
idt_end:

; GDT Descriptor
gdt_descriptor:
    dw gdt_end - gdt - 1  ; Size (16 bits)
    dd gdt                ; Address (32 bits)

; IDT Descriptor
idt_descriptor:
    dw idt_end - idt - 1  ; Size (16 bits)
    dd idt                ; Address (32 bits)

; Variables
boot_drive db 0

; Messages
msg_loading db 'Loading kernel (', 0
msg_sectors db ' sectors)...', ENDL, 0
msg_ok      db 'Kernel loaded!', ENDL, 0
msg_error   db 'Disk read error!', ENDL, 0

times 512-($-$$) db 0