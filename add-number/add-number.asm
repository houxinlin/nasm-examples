%include "/home/HouXinLin/project/nasm/include/io.inc"

section .text
global CMAIN
CMAIN:
    mov ebp, esp; for correct debugging
    ;write your code here

    push    2
    push    2
    push    2
    xor     eax,eax
    mov     ecx,3   ;;计算栈中3个数
    call    sum
   
    xor     ebx,ebx

    xor     edx, edx
    mov     ecx, 10

loopdiv:
    div     ecx
    push    edx
    inc     ebx     ;;存取结果是几位数
    cmp     eax,0   ;;商是否为0
    jz      printResult     ;;是0退出
    mov     edx,0
    mov     ecx,10
    jmp     loopdiv
printResult: ;;打印结果
    nop    
    cmp     ebx,0
    jz      exit
    
    mov     eax,[esp]
    call    printNumber
    pop     eax
    dec     ebx
    jmp     printResult
printNumber:
    push    ebx
    add     eax,48
    push    eax
    mov     edx, 1
    mov     ecx,esp
    mov     ebx, 1  
    mov     eax, 4
    int     80h   
    pop     eax
    pop     ebx
    ret
sum:
    add     ebx,4   ;;栈中偏移地址
    add     eax,dword[esp+ebx]  ;;累加
    loop     sum        ;;继续累加
    ret
exit:
    mov     ebx,0
    mov     eax,1
    int     80h    