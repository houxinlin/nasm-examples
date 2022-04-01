   
getFileSize:
    mov     ecx ,statStructBuffer
    mov     ebx,edx
    mov     eax,195
    int     80h
    mov     eax,[statStructBuffer+11*4]
    ret
loadBaseHeaderToBuffer:
     mov    edi,headersBuffer
     mov    esi,headers
     mov    ecx,72
     rep    movsb 
     ret
setBodyContentLength:
    mov     ecx,10
    mov     edx,0
    mov     ebx,0
loopdiv:
    div     ecx
    push    edx     ;余数入栈
    inc     ebx     ;;存取结果是几位数
    mov     edx,0
    mov     ecx,10
    cmp     eax,0   ;;商是否为0
    jnz     loopdiv

    mov     ecx,ebx
    mov     eax,0
_loop:
    nop
    pop     edx     ;;获取第n位
    add     edx,48
    mov     [headersBuffer+72+eax],edx
    inc     eax ;;偏移
    loop     _loop
  
    mov     edi,headersBuffer
    add     edi,72
    add     edi,eax
    mov     esi,header_end
    mov     ecx,4
    rep     movsb
    
    ret
