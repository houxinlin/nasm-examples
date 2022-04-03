struc Media_Item
    .key    resb   10
    .value  resb   20
endstruc

SECTION .data
    HTML_MEDIA: ISTRUC Media_Item
        AT Media_Item.key, db 'html'
        AT Media_Item.value, db 'text/html'
    IEND
    
    IMAGE_PNG_MEDIA: ISTRUC Media_Item
        AT Media_Item.key, db 'png'
        AT Media_Item.value, db 'image/png'
    IEND
    
    IMAGE_JPG_MEDIA: ISTRUC Media_Item
        AT Media_Item.key, db 'jpg'
        AT Media_Item.value, db 'image/jpg'
    IEND
    
    IMAGE_CSS_MEDIA: ISTRUC Media_Item
        AT Media_Item.key, db 'css'
        AT Media_Item.value, db 'text/css'
    IEND
    IMAGE_JS_MEDIA: ISTRUC Media_Item
        AT Media_Item.key, db 'js'
        AT Media_Item.value, db 'text/javascript'
    IEND    
    MediaArray dd HTML_MEDIA,0h,IMAGE_PNG_MEDIA,0h,IMAGE_JPG_MEDIA,IMAGE_CSS_MEDIA,IMAGE_JS_MEDIA,0h
    
    MediaArraySize dd 5
section .text

getMediaIndexBySuffix:
        call    getSuffix
        mov     ebx,0   
        mov     eax,0
nextMediaArray:
        mov     ecx,[MediaArraySize]
        mov     edx,[MediaArray] ;;获取数组
        
        push    eax

        
        call    getMediaKey      ;;;根据索引ebx获取当前数组媒体类型
        mov     esi,suffixBuffer  ;;请求的文件后缀
       
        call    equalsStr          ;;判断请求后缀和当前是否想等
        cmp     eax,1       ;;如果相等
        pop     eax
        je      _finishFind
        inc     eax         ;;数组中下一个
        push    eax       
        sub     eax ,ecx
        pop     eax
        jz      _failFind
        jmp     nextMediaArray
        ret
_failFind:
        mov     eax,0
        ret        
_finishFind:
        call   getMediaValue
        mov     eax,1
        ret
;;更具索引ebx获取媒体key
getMediaKey:
        push    eax
        push    ebx
        
        mov     edi,[MediaArray] ;;获取数组
        mov     ebx,30
        mul     ebx  ;;得数保存在eax中
        add     edi,eax
        pop     ebx
        pop     eax
        ret
;;更具索引ebx获取媒体类型
getMediaValue:
        push    ebx
        mov     edi,[MediaArray] ;;获取数组
        mov     ebx,30
        mul     ebx  ;;得数保存在eax中
        add     edi,eax
        add     edi,10
        pop     ebx
        ret
;;比较esi和edi中的字符串        
equalsStr:
        push    ebx
        push    ecx
        call    getStringLength ;;获取
        mov     ebx,eax
        mov     ecx,eax
        rep     cmpsb
        pop     ecx
        pop     ebx
        je      _ok
        mov     eax,0
        ret
_ok:
        mov     eax,1
        ret     
      
;;获取扩展名称，源位于esi中
getSuffix:
        call    getStringLength
        push    esi
        mov     ecx, eax    ;;保存长度
_findPoint:
        dec     eax
        cmp     eax,-1
        jz      _finish
        cmp     byte[esi+eax],46 ;;找到ascii 46  .
        jnz     _findPoint
        mov     edi,suffixBuffer
        add     esi,eax
        inc     esi
        sub     ecx,eax
        dec     ecx
        rep     movsb     
_finish:          
        pop     esi
        ret
;;获取字符长度，源位于esi中
getStringLength:
       push     esi
       mov      eax,0
       dec      esi
_loopStr:       
       inc      eax
       cmp      byte [esi+eax],0
       jnz      _loopStr
       pop esi
       dec eax
       ret