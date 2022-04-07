loadBindRoot:
    mov esi ,[esp+16]
    call getStringLength
    mov ecx,eax
    mov edi,root
    rep    movsb
    ret
loadBindPort:
    mov esi,[esp+12]   ;;从启动参数中加载端口
    call reversal     ;;反转端口字节
    ret

reversal:
    call toInt
    mov ebx,0
    mov bh,al
    mov bl,ah
    ret
toInt:
    mov eax,0
    mov ecx,0
_nextToInt:    
    cmp byte[esi+ecx],0    
    je _finishToInt
    mov edx,0
    mov dl, [esi+ecx]
    sub dl,48  ;;edx中保存当前ascii转换的数组
    push edx
    mov ebx,10
    mul ebx
    pop edx
    add eax,edx
    inc ecx
    jmp _nextToInt
_finishToInt:
    ret                
    
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
 ;;返回一个整数，表示新增的字节数量
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
    add     edx,48   ;;加上48是ascii码
    mov     [headersBuffer+32+eax],edx ;;向buffer中增加长度
    inc     eax ;;偏移
    loop     _loop
  
    mov     edi,headersBuffer
    add     edi,32
    add     edi,eax ;;n长度的相应大小
    
    call   setResponseMedia   ;;设置相应头
    
    mov     esi,header_end  ;;4个字节的结尾
    mov     ecx,4
    rep     movsb
    
    ret
setResponseMedia:
    mov     esi,header_line
    mov     ecx,2
    rep     movsb
    

    mov     esi,response_header_content_type  ;;复制content-type到buffer中
    mov     ecx,13
    rep     movsb
    
    add     eax,15
    
    ;;到这里buffer中的数据如下，eax是len(285779)+2+13的大小
    ;;HTTP/1.1 200 OK
    ;;Content-Length:285779
    ;;content-type:
    ;;这个时候只有edi和eax是需要用的
    
    push    edi     ;;保存buffer
    push    eax
    
    mov     esi,fullPath    ;;参数
    call    getMediaIndexBySuffix   ;;获取这个请求的media类型，参数是esi,结果位于edi，如果eax是1
    cmp     eax,0       ;;如果没找到了这个媒体类型
    je      setDefaultMedia
copy:
    mov     edx,edi     ;;保存结果到edx中
    pop     eax     
    pop     edi
    call    copyMediaToResponse  ;;将这个媒体类型复制到buffer中

    ret
setDefaultMedia:
     mov    edi,default_media  
     jmp    copy
     ret    
copyMediaToResponse:
     push   eax
     mov    esi,edx          ;;源字符是由getMediaIndexBySuffix获得或者是default_media
     call   getStringLength ;;获取他的长度
     mov    ecx,eax
     mov    ebx,ecx
     rep    movsb
     pop    eax
     add    eax,ebx 
     ret

 