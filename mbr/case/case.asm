org 0x7c00

start:

	mov ah,0x00
	int 16h

case:
	mov dl,al
	cmp al,97
	jae tolow
	jmp tocap

tolow:
	sub al,32
	jmp print
tocap:
	add al,32
	jmp print

print:
	push ax
	mov al,dl
	mov  ah , 0eh
	int 10h
	
	mov al,'='
	mov  ah , 0eh
	int 10h
	
	pop ax
	mov  ah , 0eh
	int 10h
	
	
	mov al,' '
	mov  ah , 0eh
	int 10h
        jmp  start
    

times 510 - ($ -$$) db 0
dw 0xaa55
