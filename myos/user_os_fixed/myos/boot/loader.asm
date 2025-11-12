; loader.asm - Second stage loader (LBA 1, loaded at 0x7E00)
org 0x7E00
bits 16

%define ENDL 0x0D, 0x0A
KERNEL_LOAD_SEG equ 0x1000

; --- constants for 1.44MB floppy ---
SectorsPerTrack  equ 18
HeadsPerCylinder equ 2

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

    ; Load kernel from LBA=3 .. KERNEL_SECTORS to ES:BX = 0x1000:0x0000
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    xor bx, bx

    mov ax, 3                 ; LBA start = 3 (after 2-sector loader)
    mov [lba_tmp], ax
    mov si, KERNEL_SECTORS    ; sectors to read
    call disk_read_lba
    jc error

    ; Print success message
    mov si, msg_ok
    call print_string
    
    ; Setup GDT
    lgdt [gdt_descriptor]

    ; Disable interrupts before switching to protected mode
    cli
    
    ; Load IDT with null (we don't need interrupts yet)
    lidt [idt_descriptor]
    
    ; Switch to protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to 32-bit code to load CS with proper descriptor
    ; Must do this IMMEDIATELY after setting PE bit
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

; Convert AX=LBA → CHS: returns CH=cyl(low8), CL[5:0]=sector(1..), CL[7:6]=cyl(high2), DH=head
lba_to_chs:
    push ax
    push dx
    xor dx, dx
    div word [spt]            ; AX = LBA / SPT, DX = LBA % SPT
    inc dx                    ; DX = sector
    mov cx, dx                ; CX = sector
    xor dx, dx
    div word [heads]          ; AX = cylinder, DX = head
    mov dh, dl                ; DH = head
    mov ch, al                ; CH = cylinder low 8
    shl ah, 6
    or cl, ah                 ; CL[7:6] = cylinder high 2
    pop dx
    pop ax
    ret

disk_read_lba:
    ; IN:  AX = LBA start,  SI = sector count, ES:BX = dest
    ; OUT: CF clear on success, CF set on failure
    push ax
    push bx
    push cx
    push dx
    push di

.next_chunk:
    cmp si, 0
    jz .done

    ; sectors left on this track = SPT - ((LBA % SPT))
    push ax
    xor dx, dx
    div word [spt]            ; DX = LBA % SPT
    mov cx, [spt]
    sub cx, dx                ; CX = sectors left on track
    pop ax

    ; take min(SI, CX) → AL
    mov ax, si
    cmp ax, cx
    jbe .use_si
    mov ax, cx
.use_si:
    mov di, ax                ; DI = to_read
    push si
    sub si, di                ; SI -= to_read

    ; compute CHS for current LBA
    push ax                   ; save to_read
    call lba_to_chs
    pop ax                    ; AX = to_read

    mov ah, 0x02              ; BIOS read
    mov al, al                ; AL = to_read
    mov dl, [boot_drive]      ; drive
    stc
    int 0x13
    jc .fail

    ; advance destination by to_read*512
    mov cx, 512
    mul cx                    ; DX:AX = to_read * 512 (fits 16-bit in AX)
    add bx, ax
    jnc .no_carry
    push dx
    mov dx, es
    add dx, 0x1000            ; 0x1000 = 64KB/16 (one segment)
    mov es, dx
    pop dx
.no_carry:

    ; advance LBA
    add word [lba_tmp], di
    mov ax, [lba_tmp]

    pop si
    jmp .next_chunk

.done:
    clc
    jmp .out

.fail:
    stc
.out:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
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
    mov esp, 0x0090000
    
    ; Clear direction flag
    cld
    
    ; Before jumping to kernel, write a test pattern to verify video memory access
    mov edi, 0xB8000      ; Video memory
    mov ax, 0x4F41        ; 'A' with red on white attribute
    mov [edi], ax
    mov ax, 0x4F42        ; 'B' with red on white attribute
    mov [edi+2], ax
    mov ax, 0x4F43        ; 'C' with red on white attribute
    mov [edi+4], ax
    
    ; Jump to kernel at linear address 0x00010000 
    ; (NOT KERNEL_LOAD_SEG:0, as that would be a selector:offset)
    jmp dword 0x00010000

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
spt   dw SectorsPerTrack
heads dw HeadsPerCylinder
lba_tmp dw 0

; Messages
msg_loading db 'Loading kernel (', 0
msg_sectors db ' sectors)...', ENDL, 0
msg_ok      db 'Kernel loaded!', ENDL, 0
msg_error   db 'Disk read error!', ENDL, 0

times 512-($-$$) db 0