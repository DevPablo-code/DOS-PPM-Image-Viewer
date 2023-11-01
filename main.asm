org 100h

cmp [80h], 1
jb NoArguments

mov di, &FilePath
call GetCmdArgument

mov dx, &FilePath
mov di, &FileHandle

call OpenFileRead

CheckP6:
    mov bx, FileHandle
    mov cx, 2

    sub sp, 2
    mov dx, sp

    call ReadBytesFromFile

    pop dx

    cmp dx, 3650h
    jz .Success

    mov dx, &P6FormatExpectedError
    call PrintLine
    ret

    .Success:
        mov dx, &P6FormatFound
        call PrintLine

CheckForComment:
    call ReadBlockOfFile

    mov si, &FileData
    xor bx, bx

    .Loop:
        cmp [si + bx], 0Ah
        jz .Next
        cmp [si + bx], 23h
        jz .Comment
        
        jmp GetImageWidth

    .Comment
        call SkipLine
    .Next:
        inc bx
        cmp bx, ax
        jmp .Loop

GetImageWidth:
    sub sp, 5
    mov di, sp

    .Loop:
        mov dx, [si + bx]
        cmp dx, 20h
        jz .EndLoop

        mov [di], dx

        inc bx
        inc di
        jmp .Loop

    .EndLoop:
        mov [di], 0
        mov si, sp
        push si
        call StringToNumber
        pop si
        add sp, 5

GetImageHeight:


Exit:
    ret

NoArguments:
    mov dx, &NoArgumentsError
    call PrintLine
    ret

NoArgumentsError: db 'Image path not specified$'

P6FormatFound: db 'Binary format$'
P6FormatExpectedError: db 'Binary format expected$'

SkipLine:
    .Loop:
        cmp [si + bx], 0Ah
        jmp .EndLoop

        inc bx
        cmp bx, ax
        jbe .Continue
        call ReadBlockOfFile
        xor bx, bx

        .Continue:
            jmp .Loop

    .EndLoop:
        ret

ReadBlockOfFile:
    mov cx, 1024
    mov dx, &FileData

    call ReadBytesFromFile

    mov BytesRecentlyRead, ax

    ret

ReadBytesFromFile:
    mov ah, 3Fh
    int 21h
    jb .Fail

    .Success:
        cmp ax, 0
        jz .EOF
        mov dx, &FileReadSuccessMessage
        call PrintLine
        ret
    .Fail:
        mov dx, &ReadFromFileError
        call PrintLine
        jmp Exit
        ret
    .EOF:
        mov dx, &ReachedEOFMessage
        call PrintLine
        ret

FileReadSuccessMessage: db 'Successfully read from file$'
ReachedEOFMessage: db 'Reached end of file$'
ReadFromFileError: db 'Failed to read file$'

;On entry:	AH = 3Dh
;AL = access mode, where:
;0 = read access
;1 = write access
;2 = read/write access
;All other bits off
;DS.DX = Segment:offset of ASCIIZ file specification
;Returns:	Carry clear if successful: AX = file handle

OpenFileRead:
    mov ah, 3Dh
    mov al, 0
    
    int 21h

    jb .Fail

    mov [di], ax

    ret

.Fail:
    mov dx, &OpenFileFail
    call PrintLine
    jmp Exit

OpenFileFail: db 'Failed to open file$'
OpenFileSuccess: db 'File opened successfully$'

GetCmdArgument:
    push si
    push bx

    mov si, 82h

    xor bx, bx

    .Loop:
        mov dl, [si + bx]

        cmp dl, 0Dh

        jz .EndLoop

        mov [di + bx], dl

        inc bx

        jmp .Loop

    .EndLoop:
        mov [di + bx], '$'

    pop bx
    pop si
    ret

PrintLine:
    push ax

    mov ah, 9h

    int 21h

    mov ah, 6h
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h

    pop ax

    ret

StringToNumber:
        push bx
        push dx

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

FilePath: db 127 @ 0
FileHandle: dw 0
FileData: db 1024 @ 0
BytesRecentlyRead: dw 0