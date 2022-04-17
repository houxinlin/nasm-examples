%include "/home/HouXinLin/project/nasm/include/io.inc"

bits 32
global CMAIN



%define CLONE_VM	0x00000100
%define CLONE_FS	0x00000200
%define CLONE_FILES	0x00000400
%define CLONE_SIGHAND	0x00000800
%define CLONE_PARENT	0x00008000
%define CLONE_THREAD	0x00010000
%define CLONE_IO	0x80000000


%define MAP_GROWSDOWN	0x0100
%define MAP_ANONYMOUS	0x0020
%define MAP_PRIVATE	0x0002
%define PROT_READ	0x1
%define PROT_WRITE	0x2
%define PROT_EXEC	0x4

%define THREAD_FLAGS \
 CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_PARENT|CLONE_THREAD|CLONE_IO

%define STACK_SIZE	(4096 * 1024)

section .data

total:  dd 0
timeval:
    tv_sec  dd 0
    tv_usec dd 0
section .text
CMAIN:
        mov     ebp, esp
        mov     ebx, threadFunction
        call    createThread

        mov     ebx, threadFunction
        call    createThread


waitF:	
        mov     dword [tv_sec], 1
        mov     dword [tv_usec], 0
        mov     eax, 162
        mov     ebx, timeval
        mov     ecx, 0
        int     0x80
        
        
        mov     eax,[total]
        mov     ebx,0
        mov     ecx,10
        mov     edx,0
        call    printTotal
        call    exit


threadFunction:
        mov     ecx,10000
_nextAdd:
        lock    inc dword[total]
        loop    _nextAdd
	call   exit
createThread:
	push   ebx
	call   createStack
	lea    ecx, [eax + STACK_SIZE - 8]
	pop    dword [ecx]
	mov    ebx, THREAD_FLAGS
	mov    eax, 120
	int    0x80
	ret

createStack:
	mov    ebx, 0
	mov    ecx, STACK_SIZE
	mov    edx, PROT_WRITE | PROT_READ
	mov    esi, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
	mov    eax, 192
	int    0x80
	ret
printTotal:
        div     ecx
        push    edx
        inc     ebx     ;;存取结果是几位数
        cmp     eax,0   ;;商是否为0
        jz      printResult     ;;是0退出
        mov     edx,0
        mov     ecx,10
        jmp     printTotal
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