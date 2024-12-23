; ;ROTLEFT(a,b) (((a) << (b)) | ((a) >> (32-(b))))

rotleft:
        push ebp
        mov ebp, esp
        sub esp, 12
        push edx
        push ecx

        mov edx, [ebp+12]              ; mov `a` to edx
        mov ecx, [ebp+8]               ; mov `b` to ecx

        shl edx, cl
        mov [esp+12] , edx             ; save (a) << (b)

        mov ecx, 32
        sub ecx, [ebp+8]
        mov edx, [ebp+12]
        shr edx, cl
        or [esp+12], edx
        mov eax, [esp+12]

        pop ecx
        pop edx
        mov esp, ebp
        pop ebp
        ret
sha256_rotright:
        push ebp
        mov ebp, esp
        sub esp, 12
        push edx
        push ecx

        mov edx, [ebp+12]              ; mov `a` to edx
        mov ecx, [ebp+8]               ; mov `b` to ecx

        shr edx, cl
        mov [esp+12] , edx             ; save (a) << (b)

        mov ecx, 32
        sub ecx, [ebp+8]
        mov edx, [ebp+12]

        shl edx, cl
        or [esp+12], edx
        mov eax, [esp+12]

        pop ecx
        pop edx
        mov esp, ebp
        pop ebp
        ret

has256_ch:
        push ebp
        push ecx
        mov ebp, esp
        sub esp, 4
        mov ecx, [ebp+20]              ; mov  `x` to ecx
        mov dword[esp] , ecx
        mov ecx, [ebp+16]
        and dword[esp], ecx            ; save x & y to [esp]

        mov ecx, [ebp+20]
        not ecx
        and ecx, [ebp+12]

        xor [esp], ecx
        mov eax, [esp]

        mov esp, ebp
        pop ecx
        pop ebp
        ret

has256_maj:
        push ebp
        push edx
        mov ebp, esp
        sub esp, 12

        mov edx, [ebp+20]
        and edx, [ebp+16]
        mov [esp], edx                 ; save (x) & (y) to esp

        mov edx, [ebp+20]
        and edx, [ebp+12]
        mov dword[esp+4], edx          ; save (x) & (z) to esp+4

        mov edx, [ebp+16]
        and edx, [ebp+12]
        mov dword[esp+8], edx

        mov edx, [esp+4]
        xor [esp], edx                 ; ((x) & (y)) ^ ((x) & (z))
        mov edx, [esp+8]
        xor [esp], edx
        mov eax, [esp]

        mov esp, ebp
        pop edx
        pop ebp
        ret
sha256_ep0:

        push ebp
        push edx
        mov ebp, esp
        sub esp, 8

        mov edx, [ebp+12]
        push edx
        push 2
        call sha256_rotright
        add esp, 8
        mov [esp], eax

        push edx
        push 13
        call sha256_rotright
        add esp, 8
        xor [esp], eax

        push edx
        push 22
        call sha256_rotright
        add esp, 8
        xor [esp], eax
        mov eax, [esp]
        mov esp, ebp
        pop edx
        pop ebp
        ret
sha256_ep1:

        push ebp
        push edx
        mov ebp, esp
        sub esp, 8

        mov edx, [ebp+12]
        push edx
        push 6
        call sha256_rotright
        add esp, 8
        mov [esp], eax

        push edx
        push 11
        call sha256_rotright
        add esp, 8
        xor [esp], eax

        push edx
        push 25
        call sha256_rotright
        add esp, 8
        xor [esp], eax
        mov eax, [esp]
        mov esp, ebp
        pop edx
        pop ebp
        ret

sha256_sig0:
        push ebp
        push edx
        mov ebp, esp
        sub esp, 8

        mov edx, [ebp+12]
        push edx
        push 7
        call sha256_rotright
        add esp, 8
        mov [esp], eax

        push edx
        push 18
        call sha256_rotright
        add esp, 8
        xor [esp], eax

        shr edx, 3
        xor [esp], edx
        mov eax, [esp]

        mov esp, ebp
        pop edx
        pop ebp
        ret
sha256_sig1:
        push ebp
        push edx
        mov ebp, esp
        sub esp, 8

        mov edx, [ebp+12]
        push edx
        push 17
        call sha256_rotright
        add esp, 8
        mov [esp], eax

        push edx
        push 19
        call sha256_rotright
        add esp, 8
        xor [esp], eax

        shr edx, 10
        xor [esp], edx
        mov eax, [esp]

        mov esp, ebp
        pop edx
        pop ebp
        ret
