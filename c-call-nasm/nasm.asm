global add

section .text
add:
	pusha
	mov     edx, 9
        mov     ecx, msg  
	mov     ebx, 1    
	mov     eax, 4   
    	int     80h
	popa
 	
 	mov     eax, [esp+4]
 	add	eax,[esp+8]
 	ret
    
section .data
msg db 'in nasm',0Dh, 0Ah,0h
