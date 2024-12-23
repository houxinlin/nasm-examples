getTextLength:
        mov eax, 0
        mov edx, [esp+4]
get_test_length_nextchar:
        cmp byte [edx], 0
        jz get_test_length_end
        inc edx
        inc eax
        jmp get_test_length_nextchar

get_test_length_end:
        ret

println_string:
        mov eax, 4
        mov ebx, 1
        mov ecx, [esp+4]
        mov edx, [esp+8]
        mov eax, 4
        int 80h
        ret

        ret

print:
        mov eax, 4
        mov ebx, 1
        mov ecx, [esp+4]
        push ecx
        call getTextLength
        mov edx, eax
        mov eax, 4
        int 80h
        pop eax
        ret

str_cat:
        push ebp
        mov ebp, esp
        sub esp, 12
        push 1
        push 2
        push 3

        xor ecx, ecx
        push dword[ebp+8]
        call getTextLength
        add esp, 4
        mov dword[esp], eax

        push dword[ebp+12]
        call getTextLength
        add esp, 4
        mov dword[esp+4], eax

        mov ecx, [esp]
        add ecx, [esp+4]
        mov dword[esp+8], ecx

        push 0
        push 0
        push 34
        push 3
        push ecx
        push 0
        mov eax, 90
        mov ebx, esp
        int 0x80
        add esp, 24
        mov esi, [ebp+8]
        mov edi, eax
        mov ecx, [esp]
        rep movsb

        mov ecx, [esp+4]
        mov esi, dword[ebp+12]
        rep movsb
        sub edi, dword[esp+8]
        mov eax, edi
        leave
        ret

new_string_buffer:
        push 0
        push 0
        push 34
        push 3
        push 1
        push 0
        mov eax, 90
        mov ebx, esp
        int 0x80
        add esp, 24

        ret

; 参数放eax中，16进制格式
print_hex_string:
        push ebp
        mov ebp, esp
        sub esp, 7

        mov byte[ebp-4], 0

        mov edx, 0
        mov ebx, 16
        div ebx
        cmp edx, 10
        jl print_hex_string_set_low_less
        add edx, 'a'
        sub edx, 10
        mov byte[ebp-5], dl
        jmp print_hex_string_next

print_hex_string_set_low_less:
        add edx, '0'
        mov byte[ebp-5], dl

print_hex_string_next:
        mov edx, 0
        mov ebx, 16
        div ebx
        cmp edx, 10
        jl print_hex_string_set_height_less
        add edx, 'a'
        sub edx, 10
        mov byte[ebp-6], dl
        jmp print_hex_string_call
print_hex_string_set_height_less:
        add edx, '0'
        mov byte[ebp-6], dl

print_hex_string_call:

        mov eax, ebp
        sub eax, 6
        push eax
        call print
        leave
        ret

; 参数放入eax中
hex_to_string:
        push ebp
        mov ebp, esp
        sub esp, 8

        mov esi, eax
        push esi
        call getTextLength
        mov eax, 32
        mov dword[ebp-4], eax
        mov ebx, 2
        mul ebx
        add esp, 4

        push 0
        push 0
        push 34
        push 3
        push eax
        push 0
        mov eax, 90
        mov ebx, esp
        int 0x80
        mov dword[ebp-8], eax
        add esp, 24

        mov ecx, [ebp-4]
        mov edi, dword[ebp-8]          ; ;结果复制到新内存
        mov edx, esi
hex_to_string_loadsb:
        mov esi, edx
        xor eax, eax
        lodsb
        push edx
        push ecx
        call hex_to_string_copy
        pop ecx
        pop edx
        add edx, 1
        loop hex_to_string_loadsb
        mov eax, dword[ebp-8]
        leave
        ret
hex_to_string_copy:
        push ebp
        mov ebp, esp
        sub esp, 7
        mov byte[ebp-4], 0
        mov edx, 0
        mov ebx, 16
        div ebx
        cmp edx, 10
        jl hex_to_string_set_low_less
        add edx, 'a'
        sub edx, 10
        mov byte[ebp-5], dl
        jmp hex_to_string_next
hex_to_string_set_low_less:
        add edx, '0'
        mov byte[ebp-5], dl
hex_to_string_next:
        mov edx, 0
        mov ebx, 16
        div ebx
        cmp edx, 10
        jl hex_to_string_set_height_less
        add edx, 'a'
        sub edx, 10
        mov byte[ebp-6], dl
        jmp hex_to_string_call
hex_to_string_set_height_less:
        add edx, '0'
        mov byte[ebp-6], dl
hex_to_string_call:
        mov eax, ebp
        sub eax, 6

        mov esi, eax
        movsb
        movsb
        leave
        ret

; 参数eax、ebx
xor_string:
        push ebp
        mov ebp, esp
        sub esp, 8
        push dword[ebp+12]
        call getTextLength
        mov dword[ebp-4], 32
        add esp, 4
        push dword[ebp+8]
        call getTextLength
        mov dword[ebp-8], 32
        add esp, 4
        mov ecx, 0
xor_string_loop:
        cmp ecx, dword[ebp-4]
        je xor_string_finish

        mov edx, 0
        mov eax, ecx
        mov ebx, dword[ebp-8]
        div ebx

        mov esi, dword[ebp+8]
        add esi, edx

        mov edi, dword[ebp+12]
        add edi, ecx
        xor eax, eax
        mov al, byte [edi]
        xor al, byte [esi]
        mov byte [edi], al
        inc ecx
        jmp xor_string_loop
xor_string_finish:
        leave
        ret
string_index:

        push ecx
        mov ecx, 0
        mov esi, eax
        push eax
        call getTextLength
        add esp, 4

        push ebx
        mov edi, esp
string_index_loop:
        cmpsb
        je string_index_end
        dec edi
        inc ecx
        cmp ecx, eax
        je string_index_not_found
        jmp string_index_loop
string_index_end:
        add esp, 8
        mov eax, ecx
        ret
string_index_not_found:
        mov ecx, -1
        jmp string_index_end

sub_string:
        push ebx
        push eax
        push ebx
        push 0
        push 0
        push 34
        push 3
        push ebx
        push 0
        mov eax, 90
        mov ebx, esp
        int 0x80
        mov edi, eax
        add esp, 24

        pop ebx
        pop eax
        mov esi, eax
        mov ecx, ebx
        rep movsb
        pop ebx
        sub edi, ebx
        mov eax, edi

        ret
memset:
        push ebp
        mov ebp, esp
        mov ecx, 0
memset_loop:
        cmp ecx, [ebp+8]
        jge memset_end
        lea esi, [ebp+12]
        mov edi, [ebp+16]
        add edi, ecx
        movsb
        inc ecx
        jmp memset_loop
memset_end:
        leave
        ret

standardization_char:
        mov ecx, [esp+8]
        inc ecx
        push 0
        push 0
        push 34
        push 3
        push ecx
        push 0
        mov eax, 90
        mov ebx, esp
        int 0x80
        add esp, 24
        mov esi, [esp+4]
        mov edi, eax
        sub ecx, 1
        rep movsb
        ret

exit:
        mov ebx, 0
        mov eax, 1
        int 80h
