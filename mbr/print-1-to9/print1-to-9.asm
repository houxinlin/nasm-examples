org 0x7c00

start:
	mov ah,15
	int 10h
	mov ah,0
	int 10h
	mov cx,9
	mov bx,1
_next
	    mov dx,bx
	    add dx,48
	    mov ax,dx
	    mov ah,0eh

	    int 10h
	    inc bx
	    push cx
	    mov ah,86h
	    mov cx,3h
	    mov dx,0h
	    int 15h
	    pop cx
	    loop _next

	   jmp start


times 510 - ($ -$$) db 0
dw 0xaa55
