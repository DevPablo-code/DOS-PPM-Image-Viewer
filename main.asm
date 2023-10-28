org 100h

cmp [80h], 1
jb NoArguments

NoArguments:
    mov dx, &NoArgumentsError
    call PrintLine
    ret

NoArgumentsError: db 'Image path not specified$'

call GetFilePath
call OpenFile
call CheckP6Identifier
call ReadFilePieceOfData

call FindImageWidth

ret

FindImageWidth:
    xor bx, bx
    xor cx, cx
    .Loop:
        mov dx, [si + bx]
        cmp dx, '#'
        jz .Comment
        cmp dx, 0Ah
        jz .Next
    
    .Comment:
        call SkipLineInFile
    .Next:
        inc bx
        cmp bx, BytesRead
        jbe .Loop

    
    ret

SkipLineInFile:
    .Loop:
        cmp [si + bx], 0Ah
        jmp .ExitLoop

        inc bx
        cmp bx, BytesRead
        jbe .Loop

    .ExitLoop:
        ret

ReadFilePieceOfData:
    mov ah, 3Fh
    mov bx, FileHandle
    mov cx, 400h
    use_ds
    mov dx, &FileData

    int 21h

    jz .Success

    ret

.Success:
    cmp ax, 0
    jz .EOF

    mov dx, &ReadSuccess
    call PrintLine
    ret
.EOF:
    mov dx, &ReadReachedEOF
    call PrintLine
    ret

ReadSuccess: db 'Bytes has been successfully read$'
ReadReachedEOF: db 'Reached end of file$'

CheckP6Identifier:
    mov ah, 3Fh
    mov bx, FileHandle
    mov cx, 2

    sub sp, 2
    mov dx, sp

    int 21h

    pop dx

    cmp dx, 3650h

    jnz P6FormatExpected

    mov dx, &P6FormatSuccess
    call PrintLine

    ret

P6FormatExpected:
    mov dx, &P6FormatExpectedError
    call PrintLine
    ret

P6FormatExpectedError: db 'Byte PPM format expected$'
P6FormatSuccess: db 'Found PPM Byte$'

OpenFile:
    mov ah, 3Dh
    mov al, 0
    mov dx, &FilePath

    int 21h

    jb CantOpenFile

    mov FileHandle, ax

    ret

CantOpenFile:
    mov dx, &CantOpenFileError
    call PrintLine
    ret

CantOpenFileError: db 'Cant open file$'

GetFilePath:
    mov si, 82h
    mov di, &FilePath
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

    xor ax, ax
.Loop:
    mov dx, [si]
    cmp dx, 0
    jz .Exit

    sub dx, 30h
    mov bx, 10
    mul bx
    add ax, dx

    add si, 1
    jmp_short .Loop
    
.Exit:
    pop bx

FilePath: db 126 @ 0
FileHandle: dw 0
FileData: db 512 @ 0
BytesRead: db 4