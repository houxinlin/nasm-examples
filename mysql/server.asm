        %include "has256.asm"
        %include "string.asm"

        section .data
MYSQL_PASSWORD:
        db '123456', 0
MYSQL_DATABASE_NAME:
        db 'root', 0
MYSQL_SCHEMA_NAME:
        db 'user', 0, 0
MYSQL_PLUGIN_NAME:
        db 'caching_sha2_password', 0, 0, 
MYSQL_QUERY_USER_SQL:
        db 'select * from user.users;', 0
CR:
        db 10, 0

d1:
        db -16, 72, -26, -51, -3, -102, -122, -100, 125, -81, 2, 65, -95, -37, 100, -33, -15, -11, 61, 61, -50, 29, 0, 72, -90, -80, -29, 18, 123, -25, 123, 53, 0
d2:
        db 19, -81, -116, 89, 3, -15, -107, 117, 67, 125, 73, 22, -16, 99, -29, -65, 85, -4, -27, -63, -120, 65, 40, -118, -103, -121, 107, 59, 60, 64, 98, 35, 0
AF_INET:
        dd 2
SOCK_STREAM:
        dd 1
IPPROTO_TCP:
        dd 6
msg1:
        db 0xaa, 0x3f, 0x55, 0x69, 0
test_hext:
        db 109, 18, 82, 4, 120, 7, 26, 123, 28, 39, 34, 86, 48, 71, 69, 21, 94, 17, 115, 9, 0
has256_k:
        dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

bind_error_msg:
        db 'bind error', 0
http_response:
        db 'HTTP/1.1 200 OK', 13, 10
        db 'Content-Type: text/plain; charset=utf-8', 13, 10
        db 13, 10 , 0
        section .bss
        mysql_auth_salt_buffer resb 32
        mysql_sockaddr_in resb 16
        mysql_read_buffer resb 10240
        mysql_auth_package resb 1024
        mysql_password_dig_1 resb 32
        mysql_password_dig_2 resb 32
        mysql_password_dig_merge resb 32+20
        mysql_login_buffer resb 200
        mysql_command_buffer resb 200

        mysql_socket_fd resd 1
        data resb 64
        datalen resd 1
        bitlen resq 1
        state resd 8
        buffer resb 32

        server_sockaddr_in resb 16
        client_sockaddr_in resb 16
        server_socket_fd resd 1
        client_socket_read_buffer resb 1024

        section .text
        global _start

_start:

        call create_server_socket
        call exit

create_server_socket:
        mov eax, 0x167
        mov ebx, [AF_INET]
        mov ecx, [SOCK_STREAM]
        mov edx, [IPPROTO_TCP]
        int 0x80
        mov dword[server_socket_fd], eax

        mov edi, 4
        push 1
        mov esi, esp
        mov edx, 2
        mov ecx, 1
        mov ebx, eax
        mov eax, 0x16e
        int 0x80
        add esp, 4

        mov word [server_sockaddr_in], 2
        mov word [server_sockaddr_in + 2], 0x901f
        mov dword [server_sockaddr_in + 4], 0x0100007f

        mov eax, 0x169
        mov ebx, dword[server_socket_fd]
        mov ecx, server_sockaddr_in
        mov edx, 16
        int 0x80
        cmp eax, 0
        jne bind_error

        mov eax, 0x16b
        mov ebx, dword[server_socket_fd]
        mov ecx, 5
        int 0x80

accept:
        mov eax, 0x16c
        mov ebx, dword[server_socket_fd]
        mov ecx, client_sockaddr_in
        push 16
        mov edx, esp
        mov esi, 0
        int 0x80
        add esp, 4                     ; eax保存客户端描述符

        push eax
        call handler_client_request
        add esp, 4

        jmp accept

        mov eax, 6
        mov ebx, dword[server_socket_fd]
        int 0x80
        ret

handler_client_request:
        push ebp
        mov ebp, esp
        sub esp, 16
        push dword[ebp+8]

        call get_request_path
        mov esi, eax
        add esp, 4

        mov eax, MYSQL_PASSWORD
        call _create_mysql_socket

        mov dword[ebp-4], eax

        push http_response
        call getTextLength
        add ecx, eax
        add esp, 4
        mov edx, eax
        mov ecx, http_response
        mov ebx, dword[ebp+8]
        mov eax, 0x4
        int 0x80

        push dword[ebp-4]
        call getTextLength
        add esp, 4
        mov ecx, eax

        mov edx, ecx
        mov ecx, dword[ebp-4]
        mov ebx, dword[ebp+8]
        mov eax, 0x4
        int 0x80

        mov ebx, dword[ebp+8]
        mov eax, 0x6
        int 0x80

        leave
        ret

get_request_path:
        push ebp
        mov ebp, esp
        sub esp, 12

        mov edx, 1024
        mov ecx, client_socket_read_buffer
        mov ebx, [ebp+8]
        mov eax, 3
        int 0x80

        mov eax, client_socket_read_buffer
        mov ebx, 32                    ; 找到方法后面的空格位置
        call string_index
        mov esi, client_socket_read_buffer
        add esi, eax
        inc esi                        ; 跳过空格

        mov eax, esi
        mov ebx, 32
        push esi
        call string_index
        pop esi
; eax保存长度
        mov ebx, eax
        mov eax, esi
        call sub_string
        leave
        ret
bind_error:
        push bind_error_msg
        call print
        call exit

_create_mysql_socket:
        push ebp
        mov ebp, esp
        sub esp, 32
        mov eax, 0x167
        mov ebx, [AF_INET]
        mov ecx, [SOCK_STREAM]
        mov edx, [IPPROTO_TCP]
        int 0x80
        mov dword[mysql_socket_fd], eax

        mov word [mysql_sockaddr_in], 2
        mov word [mysql_sockaddr_in + 2], 0xea0c
        mov dword [mysql_sockaddr_in + 4], 0x0100007f

        mov eax, 0x16a
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_sockaddr_in
        mov edx, 16
        int 0x80

        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        mov edx, 1024
        int 0x80
        mov eax, mysql_read_buffer
        add eax, 6                     ; 跳过前几个没用字节
skip_mysql_version:
        add eax, 1
        cmp byte[eax], 0
        jne skip_mysql_version
        add eax, 5                     ; skip
        push eax
        call getTextLength

        mov ecx, eax
        pop eax
        mov esi, eax
        mov edi, mysql_auth_salt_buffer
        rep movsb                      ; ;复制响应体中第一个salt到mysql_auth_salt_buffer

        add esi, 19
        push esi
        call getTextLength
        pop esi
        mov ecx, eax
        rep movsb                      ; ;复制响应体中第二个salt到mysql_auth_salt_buffer

        mov eax, mysql_auth_salt_buffer
; 加密原始密码，保存到mysql_password_dig_1
        push 6
        push MYSQL_PASSWORD
        call sha256_generator
        mov esi, buffer
        mov edi, mysql_password_dig_1
        mov ecx, 32
        rep movsb
        add esp, 8
        mov eax, mysql_password_dig_1

; sha256(sha256(password))
        push 32
        push mysql_password_dig_1
        call sha256_generator
        mov esi, buffer                ; save
        mov edi, mysql_password_dig_2
        mov ecx, 32
        rep movsb                      ; copy buffer to mysql_password_dig_2
        mov eax, mysql_password_dig_2
        add esp, 8
; mysql_password_dig_merge = mysql_password_dig_2+服务器返回的20byte盐
        mov esi, mysql_password_dig_2
        mov edi, mysql_password_dig_merge
        mov ecx, 32
        rep movsb
        mov esi, mysql_auth_salt_buffer
        mov ecx, 20
        rep movsb

        push 52
        push mysql_password_dig_merge
        call sha256_generator
        mov esi, buffer
        mov edi, mysql_password_dig_merge
        mov ecx, 32
        rep movsb
        mov eax, mysql_password_dig_merge
        add esp, 8

; xorstring 完整最后加密
        push mysql_password_dig_1
        push mysql_password_dig_merge
        call xor_string
        add esp, 8
; mov eax,mysql_password_dig_1
; call hex_to_string
; push eax

        mov eax, mysql_login_buffer

        mov esi, mysql_login_buffer
        mov byte[esi+3], 1             ; 设置序号
        mov byte[esi+4], 0x4f
        mov byte[esi+5], 0xb7
        mov byte[esi+6], 0x0e
        mov byte[esi+7], 0x00

        mov byte[esi+8], 0x00
        mov byte[esi+9], 0x00
        mov byte[esi+10], 0x80
        mov byte[esi+11], 0x00
        mov byte[esi+12], 0x53

; 数据库用户名
        push MYSQL_DATABASE_NAME
        call getTextLength
        add esp, 4
        mov ecx, eax
        mov edi, mysql_login_buffer
        mov esi, MYSQL_DATABASE_NAME
        add edi, 12+24
        rep movsb
        mov al, 0
        stosb
        mov al, 0x20
        stosb
        mov esi, mysql_password_dig_1
        mov ecx, 32
        rep movsb

        push MYSQL_SCHEMA_NAME
        call getTextLength
        mov ecx, eax
        inc ecx
        add esp, 4
        mov esi, MYSQL_SCHEMA_NAME
        rep movsb

        mov esi, MYSQL_PLUGIN_NAME
        mov ecx, 22
        rep movsb
        mov edi, mysql_login_buffer

        push MYSQL_SCHEMA_NAME
        call getTextLength
        mov ecx, eax
        add esp, 4
        push MYSQL_DATABASE_NAME
        call getTextLength
        add esp, 4
        add ecx, eax
        add ecx, 87                    ; 固定大小
        add ecx, 2                     ; 2个空字符
        mov eax, ecx
        mov byte[edi], al
        mov byte[edi+1], 0
        mov byte[edi+2], 0

        mov edx, eax

        add edx, 4
        mov eax, 0x04
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_login_buffer
        int 0x80                       ; 发送认证包

        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        mov edx, 50
        int 0x80

        mov eax, MYSQL_QUERY_USER_SQL
        push eax
        call getTextLength
        add esp, 4
        mov dword[mysql_command_buffer], eax
        inc dword[mysql_command_buffer]
        mov dword[mysql_command_buffer+3], 0 ; package number
        mov dword[mysql_command_buffer+4], 3 ; command type

        mov ecx, eax
        mov esi, MYSQL_QUERY_USER_SQL
        lea edi, [mysql_command_buffer+5]
        rep movsb

        mov edx, eax
        add edx, 5
        mov eax, 0x04
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_command_buffer
        int 0x80

        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        mov edx, 3
        int 0x80                       ; MySQL Protocol - column count 读取三个字节的查询响应，一般为1

        xor eax, eax
        mov al, byte [mysql_read_buffer+2]
        shl eax, 16
        mov ah, byte[mysql_read_buffer+1]
        mov al, byte[mysql_read_buffer]
        inc eax

        mov edx, eax
        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        int 0x80                       ; MySQL Protocol - column count

        call mysql_query_response
        leave
        ret
mysql_query_response:
        push ebp
        mov ebp, esp
        sub esp, 32

        call new_string_buffer
        push eax
        xor eax, eax
        mov al, '['
        push eax
        mov ebx, esp
        push 1
        push ebx
        call standardization_char
        mov dword[ebp-4], eax
        add esp, 16

        xor ecx, ecx
        mov cl, byte[mysql_read_buffer+1]
        cmp ecx, 0
        je mysql_query_response_read_end
mysql_query_response_read_field:
        cmp ecx, 0
        je mysql_query_response_read_rows
        push ecx
        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        mov edx, 3
        int 0x80                       ; d

        xor eax, eax
        mov al, byte [mysql_read_buffer+2]
        shl eax, 16
        mov ah, byte[mysql_read_buffer+1]
        mov al, byte[mysql_read_buffer]
        inc eax

        mov edx, eax
        mov eax, 0x03
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        int 0x80

        mov esi, mysql_read_buffer
        add esi, 1

        xor eax, eax
        mov al, byte[esi]
        add esi, eax
        inc esi

        xor eax, eax
        mov al, byte[esi]
        add esi, eax
        inc esi

        xor eax, eax
        mov al, byte[esi]
        add esi, eax
        inc esi

        xor eax, eax
        mov al, byte[esi]
        add esi, eax
        inc esi

        xor eax, eax
        mov al, byte[esi]
        add esi, eax
        inc esi

        xor eax, eax
        mov al, byte[esi]
        add esi, eax
        inc esi

        pop ecx
        dec ecx
        jmp mysql_query_response_read_field

mysql_query_response_read_rows:
; ;读取MySQL Protocol - intermediate EOF，没用
        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        mov edx, 3
        int 0x80
        xor eax, eax
        mov al, byte [mysql_read_buffer+2]
        shl eax, 16
        mov ah, byte[mysql_read_buffer+1]
        mov al, byte[mysql_read_buffer]
        inc eax
        mov edx, eax
        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        int 0x80

mysql_query_response_read_rows_next:
; ;读取行数据
        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        mov edx, 3
        int 0x80                       ; 读取row大小

        xor eax, eax
        mov al, byte [mysql_read_buffer+2]
        shl eax, 16
        mov ah, byte[mysql_read_buffer+1]
        mov al, byte[mysql_read_buffer]
        push eax                       ; 行的数据大小
        inc eax

        mov edx, eax
        mov eax, 0x3
        mov ebx, dword[mysql_socket_fd]
        mov ecx, mysql_read_buffer
        int 0x80

        mov esi, mysql_read_buffer
        add esi, 1                     ; 这里无法保证数据超过255的时候
        cmp byte[esi], 0xfe
        je mysql_query_response_read_end
        add esi, 1

        pop ebx
        sub ebx, 1

        push ebx
        push esi
        call standardization_char
        push eax
        push dword[ebp-4]
        call str_cat
        mov dword[ebp-4], eax
        add esp, 16

        xor eax, eax
        mov al, ', '
        push eax
        mov ebx, esp
        push 1
        push ebx
        call standardization_char
        push eax
        push dword[ebp-4]
        call str_cat
        mov dword[ebp-4], eax

        jmp mysql_query_response_read_rows_next

mysql_query_response_read_end:
        push dword[ebp-4]
        call getTextLength
        mov esi, dword[ebp-4]
        add esi, eax
        mov byte[esi-1], 0             ; 删除最后面,号
        xor eax, eax
        mov al, ']'
        push eax
        mov ebx, esp
        push 1
        push ebx
        call standardization_char
        push eax
        push dword[ebp-4]
        call str_cat
        add esp, 24
        leave
        ret

sha256_generator:
        push ebp
        mov ebp, esp
        sub esp, 8

        call sah_256_init

        push dword[ebp+12]
        push dword[ebp+8]
        call sha256_update
        mov eax, data
        add esp, 8
        call sha256_final
        leave
        ret

print_sha256:
        mov ecx, 32
print_sha256_loop:
        lodsb
        push ecx
        call print_hex_string
        pop ecx
        loop print_sha256_loop
        call exit

sha256_final:
        push ebp
        mov ebp, esp
        sub esp, 16
        mov edi, data
        mov ecx, dword[datalen]
        mov dword[ebp-4], ecx

        cmp ecx, 56
        jl sha256_final_jl_56_handler
        jmp sha256_final_jg_56_handler
sha256_final_jl_56_handler:
        mov byte[data+ecx], 0x80
        inc ecx
sha256_final_jl_56_handler_next:
; mov byte[data+ecx],0x00
        cmp ecx, 56
        jl sha256_final_jl_56_handler_set_zero
        jmp sha256_final_padding
sha256_final_jl_56_handler_set_zero:
        mov byte[data+ecx], 0x00
        inc ecx
        jmp sha256_final_jl_56_handler_next

sha256_final_jg_56_handler:
        mov byte[data+ecx], 0x80
        inc ecx

sha256_final_jg_56_handler_loop:
        cmp ecx, 64
        jl sha256_final_jg_56_handler_set_zero
        jmp sha256_final_jg_56_handler_transform
sha256_final_jg_56_handler_set_zero:
        mov byte[data+ecx], 0x00
        inc ecx
        jmp sha256_final_jg_56_handler_loop

sha256_final_jg_56_handler_transform:
        nop
        mov eax, data
        mov eax, datalen
        mov eax, bitlen
        push data
        call sha256_transform
  

        push data
        push 0
        push 56
        call memset
        jmp sha256_final_padding

sha256_final_padding:
        mov edx, 0
        mov eax , [datalen]
        mov ebx, 8
        mul ebx
        mov esi, bitlen
        add dword[bitlen+4], eax       ; ctx->bitlen += ctx->datalen * 8;  bitlen low 8

        mov eax, [bitlen+4]
        mov byte[data+63], al          ; ctx->data[63] = ctx->bitlen;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov ecx, 8
        shrd eax, edx, cl
        sar edx, cl
        mov byte[data+62], al          ; ctx->data[62] = ctx->bitlen >> 8;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov ecx, 16
        shrd eax, edx, cl
        sar edx, cl
        mov byte[data+61], al          ; ctx->data[61] = ctx->bitlen >> 16;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov ecx, 24
        shrd eax, edx, cl
        sar edx, cl
        mov byte[data+60], al          ; ctx->data[60] = ctx->bitlen >> 24;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov eax, edx
        mov ecx, 32-32
        mov eax, edx
        sar edx, 31
        shr eax, cl
        mov byte[data+59], al          ; ctx->data[59] = ctx->bitlen >> 32;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov eax, edx
        mov ecx, 40-32
        sar edx, 31
        shr eax, cl
        mov byte[data+58], al          ; ctx->data[58] = ctx->bitlen >> 40;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov eax, edx
        mov ecx, 48-32
        sar edx, 31
        shr eax, cl
        mov byte[data+57], al          ; ctx->data[57] = ctx->bitlen >> 48;

        mov edx, [bitlen]
        mov eax, [bitlen+4]
        mov eax, edx
        mov ecx, 48-32
        sar edx, 31
        shr eax, cl
        mov byte[data+56], al          ; ctx->data[56] = ctx->bitlen >> 56;

        mov eax, data
        push data
        call sha256_transform

        mov ecx, 0
sha256_has:
        cmp ecx, 4
        jae sha256_final_exit

        mov eax, buffer
        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+0]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 0
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+4]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 4
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+8]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 8
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+12]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 12
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+16]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 16
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+20]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 20
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+24]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 24
        add edi, ebx
        stosb

        mov eax, ecx
        mov ebx, 8
        mul ebx
        mov ebx, 24
        sub ebx, eax
        lea edi, [state+28]
        push ecx
        mov cl, bl
        mov edx, dword[edi]
        shr edx, cl
        pop ecx
        and edx, 0x000000ff
        mov eax, edx
        mov edi, buffer
        mov ebx, ecx
        add ebx, 28
        add edi, ebx
        stosb
        nop

        inc ecx
        jmp sha256_has

sha256_final_exit:
        mov eax, buffer
        leave
        ret

sha256_update:
        push ebp
        mov ebp, esp
        sub esp, 16
        mov ecx, 0
        mov dword[ebp-4], ecx

sha256_update_loop:
        cmp ecx, [ebp+12]
        jae sha256_update_loop_finish

        mov eax, [ebp+8]
        lea esi, [eax+ecx]

        mov eax, data
        lea edi, [eax]
        add edi, [datalen]

        movsb
        inc dword[datalen]
        cmp dword[datalen], 64
        je sha256_update_sha256_transform
        inc ecx

        jmp sha256_update_loop
sha256_update_sha256_transform:
        push data
        push ecx
        call sha256_transform
        pop ecx
        add dword[bitlen+4], 512
        mov dword[datalen], 0
        mov eax, dword[bitlen+4]
        mov eax, datalen
        mov eax, data
        inc ecx
        jmp sha256_update_loop
sha256_update_loop_finish:

        leave
        ret

sha256_transform:
        push ebp
        mov ebp, esp
        sub esp, 48+256

        xor al, al
        mov edi, esp
        mov ecx, 48 + 256
        rep stosb

        mov ecx, 16
        mov dword[ebp-4], 0            ; a
        mov dword[ebp-36], 0           ; i
        mov dword[ebp-40], 0           ; j

        mov eax, data
sha256_transform_first_loop:
        xor eax, eax
        xor ebx, ebx
        mov edi, data
        add edi, dword[ebp-40]
        mov al, byte[edi]
        shl eax, 24

        xor ebx, ebx
        mov edi, data
        mov ebx, dword[ebp-40]
        add ebx, 1
        add edi, ebx
        mov bl, byte[edi]
        shl ebx, 16

        or eax, ebx

        xor ebx, ebx
        mov edi, data
        mov ebx, dword[ebp-40]
        add ebx, 2
        add edi, ebx
        mov bl, byte[edi]
        shl ebx, 8
        or eax, ebx

        xor ebx, ebx
        mov edi, data
        mov ebx, dword[ebp-40]
        add ebx, 3
        add edi, ebx
        mov bl, byte[edi]
        or eax, ebx

        push eax
        push ecx
        mov ebx, 49
        mov ecx, 4
        mov eax, dword[ebp-36]
        mul ecx
        add ebx, eax
        pop ecx
        pop eax

        mov edi, ebp
        sub edi, ebx

        mov dword[edi], eax
        inc dword[ebp-36]
        add dword[ebp-40], 4
        loop sha256_transform_first_loop

        mov ecx, 64-16
sha256_transform_second_loop:
        cmp dword[ebp-36] , 64
        jae sha256_transform_second_loop_finish

        mov eax, [ebp-36]              ; i
        mov ebx, 4
        mul ebx
        add eax, 49
        neg eax
        mov edi, ebp                   ; edi =ebp-(49+([ebp-36]*4))
        add edi, eax

        mov eax, [ebp-36]              ; i
        sub eax, 2
        mov ebx, 4
        mul ebx
        add eax, 49
        neg eax
        mov esi, [ebp+eax]
        push esi
        call sha256_sig1
        add dword[edi], eax            ; SIG1(m[i - 2])
        add esp, 4

        mov eax, [ebp-36]              ; i
        sub eax, 7
        mov ebx, 4
        mul ebx
        add eax, 49
        neg eax
        mov esi, [ebp+eax]
        add dword[edi], esi            ; SIG1(m[i - 2]) +m[i - 7]

        mov eax, [ebp-36]              ; i
        sub eax, 15
        mov ebx, 4
        mul ebx
        add eax, 49
        neg eax
        mov esi, [ebp+eax]
        push esi
        call sha256_sig0
        add esp, 4
        add dword[edi], eax            ; SIG1(m[i - 2]) +m[i - 7]+ SIG0(m[i - 15])

        mov eax, [ebp-36]              ; i
        sub eax, 16
        mov ebx, 4
        mul ebx
        add eax, 49
        neg eax
        mov esi, [ebp+eax]
        add dword[edi], esi            ; SIG1(m[i - 2]) +m[i - 7]+ SIG0(m[i - 15]) +m[i - 16];

        inc dword[ebp-36]
        jmp sha256_transform_second_loop

sha256_transform_second_loop_finish:
        mov eax, dword[state+0]
        mov dword[ebp-4], eax          ; a = ctx->state[0];

        mov eax, dword[state+4]
        mov dword[ebp-8], eax

        mov eax, dword[state+8]
        mov dword[ebp-12], eax

        mov eax, dword[state+12]
        mov dword[ebp-16], eax

        mov eax, dword[state+16]
        mov dword[ebp-20], eax

        mov eax, dword[state+20]
        mov dword[ebp-24], eax

        mov eax, dword[state+24]
        mov dword[ebp-28], eax

        mov eax, dword[state+28]
        mov dword[ebp-32], eax         ; h = ctx->state[7];

        mov dword[ebp-36], 0           ; rest i
sha256_transform_third:
        cmp dword[ebp-36], 64
        jae sha256_transform_add_state

        mov dword[ebp-44], 0
        mov eax, [ebp-32]
        mov dword[ebp-44], eax         ; t1=h

        push dword[ebp-20]
        call sha256_ep1
        add esp, 4
        add dword[ebp-44], eax         ; add t1,EP1(e)

        push dword[ebp-20]
        push dword[ebp-24]
        push dword[ebp-28]
        call has256_ch
        add esp, 12
        add dword[ebp-44], eax         ; add t1,CH(e,f,g)

        mov ebx, dword[ebp-36]         ; i
        mov eax, [has256_k+ebx*4]
        add dword[ebp-44], eax         ; add k[i]

        mov eax, ebx
        mov ebx, 4
        mul bl
        neg eax

        mov edi, ebp
        add edi, eax
        sub edi, 49
        mov eax, [edi]
        add dword[ebp-44], eax
        mov eax, dword[ebp-44]         ; t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];

        push dword[ebp-4]
        call sha256_ep0
        add esp, 4
        mov dword[ebp-48], eax

        push dword[ebp-4]
        push dword[ebp-8]
        push dword[ebp-12]
        call has256_maj
        add esp, 12
        add dword[ebp-48], eax         ; EP0(a) + MAJ(a,b,c);

        mov eax, [ebp-28]
        mov dword[ebp-32], eax         ; h = g

        mov eax, [ebp-24]
        mov dword[ebp-28], eax         ; g = f

        mov eax, [ebp-20]
        mov dword[ebp-24], eax         ; f = e

        mov eax, [ebp-16]
        add eax, [ebp-44]
        mov dword[ebp-20], eax         ; e = d + t1;

        mov eax, [ebp-12]
        mov dword[ebp-16], eax         ; d = c

        mov eax, [ebp-8]
        mov dword[ebp-12], eax         ; c = b

        mov eax, [ebp-4]
        mov dword[ebp-8], eax          ; b = a

        mov eax, [ebp-44]
        add eax, [ebp-48]
        mov dword[ebp-4], eax          ; a = t1 + t2;

        inc dword[ebp-36]
        jmp sha256_transform_third

sha256_transform_add_state:
        mov eax, [ebp-4]
        add dword[state], eax

        mov eax, [ebp-8]
        add dword[state+4], eax

        mov eax, [ebp-12]
        add dword[state+8], eax

        mov eax, [ebp-16]
        add dword[state+12], eax

        mov eax, [ebp-20]
        add dword[state+16], eax

        mov eax, [ebp-24]
        add dword[state+20], eax

        mov eax, [ebp-28]
        add dword[state+24], eax

        mov eax, [ebp-32]
        add dword[state+28], eax

        mov eax, state

sha256_transform_finish:
        leave

        ret
sah_256_init:
        mov eax, state
        mov dword[datalen], 0
        mov dword[bitlen], 0
        mov dword[bitlen+4], 0

        mov dword[state+0], 0x6a09e667
        mov dword[state+4], 0xbb67ae85
        mov dword[state+8], 0x3c6ef372
        mov dword[state+12], 0xa54ff53a
        mov dword[state+16], 0x510e527f
        mov dword[state+20], 0x9b05688c
        mov dword[state+24], 0x1f83d9ab
        mov dword[state+28], 0x5be0cd19
        ret

