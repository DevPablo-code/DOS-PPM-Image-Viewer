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
    push dx
    mov dx, &FileData
    call ReadBlockOfFile
    pop dx

    mov si, &FileData
    xor bx, bx

    .Loop:
        cmp [si + bx], 0Ah
        jz .Next
        cmp [si + bx], 23h
        jz .Comment
        
        jmp GetImageWidth

    .Comment:
        call SkipLine
    .Next:
        inc bx
        cmp bx, ax
        jmp .Loop

GetImageWidth:
    sub sp, 5
    mov di, sp

    .Loop:
        mov dl, [si + bx]
        cmp dl, 20h
        jz .EndLoop

        mov [di], dl

        inc bx
        inc di
        jmp .Loop

    .EndLoop:
        mov [di], 0
        inc bx

        mov si, sp

        call StringToNumber

        mov si, &FileData

        add sp, 5

        mov ImageWidth, ax

GetImageHeight:
    sub sp, 5
    mov di, sp

    .Loop:
        mov dl, [si + bx]
        cmp dl, 0Ah
        jz .EndLoop

        mov [di], dl

        inc bx
        inc di
        jmp .Loop

    .EndLoop:
        mov [di], 0
        inc bx

        mov si, sp

        call StringToNumber

        mov si, &FileData
        
        add sp, 5

        mov ImageHeight, ax

GetMaxColorValue:
    sub sp, 5
    mov di, sp

    .Loop:
        mov dl, [si + bx]
        cmp dl, 0Ah
        jz .EndLoop

        mov [di], dl

        inc bx
        inc di
        jmp .Loop

    .EndLoop:
        mov [di], 0
        inc bx

        mov si, sp

        call StringToNumber

        mov si, &FileData
        
        add sp, 5

        mov MaxColorValue, ax

EnterGraphicsMode:
    push bx
    mov ax, 4F02h
    mov bx, 105h
    int 10h
    pop bx

DrawImage:
    xor cx, cx
    xor dx, dx
    
    .Loop: 
        push cx
        push dx
        xor ax, ax
        mov al, [si + bx]
        mov cl, [si + bx + 1]
        mov dl, [si + bx + 2]

        call GetAveragedColor
        call MapColorTo16Shades

        pop dx
        pop cx

        push bx

        mov ah, 0Ch
        mov bh, 0

        int 10h

        pop bx

        add bx, 3h
        mov ax, BytesRecentlyRead
        sub ax, bx
        cmp ax, 3h
        jnb .NextColumn

        cmp ax, 0h
        jbe .LoadNextBlock


    .LoadNextBlockPartially:
        push dx
        push cx

        mov di, [si + bx]
        mov FileData, di

        mov dx, &FileData
        add dx, ax

        mov bx, FileHandle
        mov cx, BlockSize
        sub cx, ax

        push ax
        call ReadBytesFromFile
        cmp ax, 0h
        jz WaitForKeypress
        pop ax
        add BytesRecentlyRead, ax
        xor bx, bx

        pop cx
        pop dx  

        jmp .NextColumn

    .LoadNextBlock: 
        push dx

        mov dx, &FileData
            
        call ReadBlockOfFile
        cmp ax, 0h
        jz WaitForKeypress
        xor bx, bx

        pop dx

    .NextColumn:
        inc cx
        cmp cx, ImageWidth
        jb .Loop

    .NextRow:
        xor cx, cx
        inc dx
        cmp dx, ImageHeight
        jb .Loop
        
WaitForKeypress:
    mov ah, 0h
    int 16h

ReturnToTextMode:
    mov ah, 00h
    mov al, 03h
    int 10h

Exit:
    ret

NoArguments:
    mov dx, &NoArgumentsError
    call PrintLine
    ret

NoArgumentsError: db 'Image path not specified$'

P6FormatFound: db 'Binary format$'
P6FormatExpectedError: db 'Binary format expected$'

MapColorTo16Shades:
    mov ah, 0h
    mov dl, 16
    div dl
    add ax, dl

    ret

GetAveragedColor:
    add ax, dl
    add ax, cl
    mov dl, 3

    div dl

    ret

SkipLine:
    .Loop:
        cmp [si + bx], 0Ah
        jz .EndLoop

        inc bx
        cmp bx, ax
        jbe .Continue
        push dx
        mov dx, &FileData
        call ReadBlockOfFile
        pop dx
        xor bx, bx

        .Continue:
            jmp .Loop

    .EndLoop:
        ret

ReadBlockOfFile:
    push bx
    push cx

    mov bx, FileHandle
    mov cx, BlockSize

    call ReadBytesFromFile

    pop cx
    pop bx

    ret

ReadBytesFromFile:
    mov ah, 3Fh
    int 21h
    jb .Fail

    .Success:
        cmp ax, 0
        jz .EOF
        mov BytesRecentlyRead, ax
        ;mov dx, &FileReadSuccessMessage
        ;call PrintLine
        ret
    .Fail:
        mov dx, &ReadFromFileError
        call PrintLine
        jmp Exit
        ret
    .EOF:
        ;mov dx, &ReachedEOFMessage
        ;call PrintLine
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

        sub cl, 30h
        mul bx
        add ax, cx

        inc si
        jmp .Loop
        
    .Exit:
        pop cx
        pop bx
        ret

ImageWidth: dw 0
ImageHeight: dw 0
MaxColorValue: dw 0
BlockSize: dw 400h
FilePath: db 127 @ 0
FileHandle: dw 0
BytesRecentlyRead: dw 0
FileData: db 401h @ 0