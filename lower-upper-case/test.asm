%include "/home/HouXinLin/project/nasm/include/io.inc"

 
SECTION .data
    port db "8080",0h
    p   dd 10
timeval:
    tv_sec  dd 0
    tv_usec dd 0
SECTION .bss
    portBuffer resb 4
    

SECTION .text
    global CMAIN
CMAIN:

    mov ebp, esp; for correct debugging
;目标 原
    mov eax,101
    mov ebx,1000
    cmpxchg [p],ebx
.next:
            
        loop .next
	call exit
    
 
    nop
reversal:
    nop
    call toInt
    mov ebx,0
    mov bh,al
    mov bl,ah
    nop
    
    ret
  
toInt:
    mov eax,0
    mov ecx,0
_next:    
    cmp byte[esi+ecx],0    
    je _finish
    mov edx,0
    mov dl, [esi+ecx]
    sub dl,48  ;;edx中保存当前ascii转换的数组
    push edx
    mov ebx,10
    mul ebx
    pop edx
    add eax,edx
    
    inc ecx
    jmp _next
_finish:
    ret
exit:

    mov ebx,0
    mov eax,1
    int 80h
    