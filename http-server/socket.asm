
%include "utils.asm"

SECTION .data
    headers db 'HTTP/1.1 200 OK', 0Dh, 0Ah,'Content-Type: application/octet-stream',0Dh, 0Ah,'Content-Length:',0h
    header_end db 0Dh, 0Ah, 0Dh, 0Ah,0h
    notfound_response db 'HTTP/1.1 404 OK', 0Dh, 0Ah, 'Content-Type: text/html', 0Dh, 0Ah, 'Content-Length: 10', 0Dh, 0Ah, 0Dh, 0Ah, 'not found!', 0Dh, 0Ah, 0h
    root db '/home/HouXinLin/test', 0h 
    msg  db 'accept',0h
    ok  db 'ok',0h
    fail  db 'fail',0h
    SO_REUSEADDR  db 1,0h
   
    

SECTION .bss
    headersBuffer resb  4096
    fileContents resb   40960
    responseBuffer resb 40960
    requestBuffer resb  4096
    fullPath resb       1024
    requestPath resb    1024
    socketbuf    resb    4
    

    buffer resb 1024
    statStructBuffer resb 144

SECTION .text
global  CMAIN
 
CMAIN:
    mov ebp, esp; for correct debugging

    xor     eax, eax
    xor     ebx, ebx
    xor     edi, edi
    xor     esi, esi

    
socket:
 
    push    byte 6 
    push    byte 1
    push    byte 2
    mov     ecx, esp
    mov     ebx, 1
    mov     eax, 102
    int     80h    ;;创建Socket
   
bind:
    push eax
   
    mov  edi,4
    mov  esi,SO_REUSEADDR
    mov  edx,2
    mov  ecx,1
    mov  ebx,eax
    mov  eax,366
    int  80h
    
    pop eax
    mov     edi, eax ;;edi存放server socket描述副
    
    push    dword 0x00000000
    push    word 0x901f    ;;端口8080
    push    word 2
    mov     ecx, esp
    push    byte 16
    push    ecx
    push    edi
    mov     ecx, esp
    mov     ebx, 2
    mov     eax, 102
    int     80h         ;;绑定8080端口
    cmp     eax,0
    je      listen
    jmp     exit
 
listen:
 
    push    byte 1 
    push    edi
    mov     ecx, esp
    mov     ebx, 4
    mov     eax, 102
    int     80h     ;监听
 
accept:
 
    push    byte 0 
    push    byte 0
    push    edi
    mov     ecx, esp
    mov     ebx, 5
    mov     eax, 102
    int     80h
 
    mov     esi, eax          ;;将客户端描述符保存到esi中


    mov     eax, 2
    int     80h
    cmp     eax, 0
    jz      read
    jmp     accept
    
read:
    mov     edx,6
    mov     ecx,msg
    mov     ebx,1
    mov     eax,4
    int     80h
    
    mov     edx, 4096          ;;读取客户端内容
    mov     ecx, requestBuffer
    mov     ebx, esi
    mov     eax, 3
    int     80h


getRequestResourcePath: ;;获取请求资源路径
    mov     eax,requestBuffer
    mov     ebx,eax
    
nextResourceChar:    
    cmp     byte[ebx],32    ;;如果是空格
    jz      record           ;;开始记录
    inc     ebx             ;;下一个字符
    jmp     nextResourceChar 
    ret
    
record: 
    mov     edx,ebx     ;;ebx是第一个空格后的位置
    sub     edx,eax     ;存放开始索引
    mov     ecx, requestBuffer
    add     ecx,edx         ;;从ecx后的位置开始查看地一个空格
    mov     edx,0
    
hasEnd:
    inc     ecx
    cmp     byte[ecx],32  ;;如果下一个也是空格
    jz      finishSearch
    
    mov     eax, dword[ecx]   ;;获取当前字符
    mov     dword[requestPath+edx],eax
    inc     edx
    jmp     hasEnd
    
finishSearch:
    push    esi
    mov     esi,root
    mov     edi,fullPath
    mov     ecx,20
    rep     movsb   ;;复制root
    
    mov     esi,requestPath 
    mov     edi,fullPath
    add     edi,20
    mov     ecx,edx
    rep     movsb
    pop     esi
   

openFile:
    mov     ecx, 4           ;;打开文件
    mov     ebx, fullPath
    mov     eax, 5
    int     80h
    cmp     eax,0
    jl      notfound
    push    eax         ;;保存文件描述符

write:
    push    eax
    push    esi
    mov     edx,fullPath
    call    getFileSize                 ;获取文件大小，结果保存到eax中
    call    loadBaseHeaderToBuffer      ;家在header buffer用来拼接
    call    setBodyContentLength        ;设置body大小
   
    mov     edx,eax
    add     edx,76      ;其中72个字节是头信息，4个字节是body和header之间的分割符号
    
    pop     esi
    pop     eax

    mov     ecx, headersBuffer    ;;首先输出头
    mov     ebx, esi 
    mov     eax, 4  
    int     80h 
    
hasNext:  
    pop     eax         ;;文件描述符传递给readFile
    push    eax
    call    readFile      ;;调用之后eax保存读取的大小，fileContents保存文件内容
    push    eax
    mov     edx,eax
    mov     ecx, fileContents    ;;输出内容
    mov     ebx, esi 
    mov     eax, 4  
    int     80h 
    pop     eax             ;;读取的文件字节数
    cmp     eax,0
    call    closeFile
    jz      closeSocket
    jmp     hasNext
notfound:
    mov     edx,76
    mov     ecx, notfound_response    ;;输出头
    mov     ebx, esi 
    mov     eax, 4  
    int     80h 
closeSocket:
    ;;关闭客户端socket

    push    2
    push    esi
    mov     ecx, esp
    mov     ebx, 13
    mov     eax, 102
    int     80h
    
    cmp     eax,0
    jz      exit
    
    mov     edx,4
    mov     ecx,fail
    mov     ebx,1
    mov     eax,4
    int     80h
    jmp     exit    
readFile:
    mov     edx, 40960         ;;尝试读取40960个字节到fileContents
    mov     ecx, fileContents  
    mov     ebx, eax 
    mov     eax, 3  
    int     80h                 ;读取    
    ret
closeFile:
    mov     ebx,eax
    mov     eax,6    
    int     80h
    ret
exit:
  
    mov     ebx,0
    mov     eax,1
    int     80h

