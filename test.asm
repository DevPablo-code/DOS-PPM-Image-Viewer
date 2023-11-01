org 100h

mov si, &NumberString
call StringToNumber

ret

NumberString: db '128' db 0

StringToNumber:
        push bx
        push cx

        xor ax, ax
        xor cx, cx

        mov bx, 10
    .Loop:
        mov cl, [si]
        cmp cl, 0
        jz .Exit

        sub cx, 30h
        mul bx
        add ax, cx

        inc si
        jmp .Loop
        
    .Exit:
        pop cx
        pop bx
        ret