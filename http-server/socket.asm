
SECTION .data
    headers db 'HTTP/1.1 200 OK', 0Dh, 0Ah, 'Content-Type: application/octet-stream', 0Dh, 0Ah, 0Dh, 0Ah
    root db '/home/HouXinLin/test', 0h 

SECTION .bss
    fileContents resb 40960
    responseBuffer resb 40960
    requestBuffer resb 4096
    fullPath resb 1024
    requestPath resb 1024
SECTION .text
global  _start
 
_start:
    mov ebp, esp
 
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
 
    mov     edi, eax 
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

 
read:
 
    mov     edx, 4096          ;;读取客户端内容
    mov     ecx, requestBuffer
    mov     ebx, esi
    mov     eax, 3
    int     80h


getRequestResourcePath: ;;获取请求资源路径
    mov eax,requestBuffer
    mov ebx,eax
nextResourceChar:    
    cmp byte[ebx],32    ;;如果是空格
    jz record           ;;开始记录
    inc ebx             ;;下一个字符
    jmp nextResourceChar 
    ret
record: 
    mov edx,ebx     ;;ebx是第一个空格后的位置
    sub edx,eax     ;存放开始索引
    mov ecx, requestBuffer
    add ecx,edx         ;;从ecx后的位置开始查看地一个空格
    mov edx,0
hasEnd:
    inc ecx
    cmp byte[ecx],32  ;;如果下一个也是空格
    jz finishSearch
    
    mov eax, dword[ecx]   ;;获取当前字符
    mov dword[requestPath+edx],eax
    inc edx
    jmp hasEnd
finishSearch:
    push esi
    mov esi,root
    mov edi,fullPath
    mov ecx,20
    rep movsb   ;;复制root
    
    mov esi,requestPath 
    mov edi,fullPath
    add edi,20
    mov ecx,edx
    rep movsb
    pop esi
   
write:
    push esi

    mov edi,responseBuffer      ;;字符复制目的地址
    mov esi,headers             ;;字符复制原地址
    mov ecx,59                  ;;复制59个字节到响应buffer中
    rep movsb
    
    call readFile               ;;读取文件
    mov edi,responseBuffer+59  ;;偏移59个字节拼接body
    mov esi,fileContents

    mov ecx,eax
    rep movsb               ;;在复制n个字节，eax是读取到的字节数量，不固定
    
    pop esi

    mov     edx, eax     ;;文件内容长度
    add     edx,59       ;;加上头部长度
    mov     ecx, responseBuffer    ;;输出
    mov     ebx, esi 
    mov     eax, 4  
    int     80h 
    call    exit
    
readFile:
    mov     ecx, 4           ;;打开文件
    mov     ebx, fullPath
    mov     eax, 5
    int     80h
    
    mov     edx, 40960         ;;尝试读取4096个字节到fileContents
    mov     ecx, fileContents  
    mov     ebx, eax 
    mov     eax, 3  
    int     80h         ;读取
    ret
    
exit:
 
    mov ebx,0
    mov eax,1
    int 80h
    
