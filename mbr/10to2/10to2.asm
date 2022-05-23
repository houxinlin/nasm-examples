org 0x7c00

start:
    	mov ax,78
    	mov cx,0
_next:    
	inc cx
   	mov dx,0
   	mov bx,2
  	div bx
  	 
  	 
  	push dx
   	cmp ax,0
 	ja _next
 	 
print:
	pop ax 	
	add al,48 
	mov  ah , 0eh
	int 10h
        loop print

times 510 - ($ -$$) db 0
dw 0xaa55
