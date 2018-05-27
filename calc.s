section .rodata
LC0:
  DB  "%x",0 ; Format string
LC2:
  DB  "%c",0 ; Format string
LC3:
  DB "%s",0
LC4:
  DB "%d",10,0

section .bss
LC1: RESD  5
POS: RESD 1
SIZE equ 80
BUFF: RESB SIZE
NEXT: RESD 1
INSERT: RESD 1
ANS: RESD 1
CARRY : RESB 1
FLAG: RESB 1
COUNT : RESD 1
COUNT2 : RESD 1
ADDFLAG : RESB 1
OPS : RESD 1
FLAGD: RESB 1
DB: RESB 1

section .data
        msg     dd  'Error: Insufficient Number of Arguments on Stack',0xa      
        msg2    dd  '>>calc:',0xa          
        msg3    dd 'Error: Operand Stack Overflow',0xa  
        msg4    dd 'Error: Illegal Input',0xa
        msg5    dd 'got string:',0xa
        msg6    dd 'number inserted is:',0xa                

section .text
  align 16
  global main
  extern printf
  extern fprintf
  extern malloc
  extern free
  extern fgets
  extern stderr
  extern stdin
  extern stdout 


main:

    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...

    
    mov dword [FLAGD],0
    mov dword [POS],0
    mov dword [OPS],0
    
    mov ecx, [ebp+8]
    cmp ecx,1
    je loop
    mov ebx, dword [ebp+12]
    mov eax, dword [ebx+4]
    cmp byte [eax], '-'
        jne loop
    cmp byte [eax + 1], 'd'
        jne loop
    cmp byte [eax + 2], 0
        jne loop
    mov byte [FLAGD], 1


    loop:
    push msg2
    push LC3
    call printf
    add esp,8
       
    push dword [stdin]
    push dword SIZE
    push BUFF

    call fgets
    add esp,12
    cmp byte [FLAGD],1
        jne calnit
    pushad
    push LC3
    push msg5
    push dword [stderr]
    call fprintf
    add esp,12
    popad
    pushad
    push eax
    push LC3
    call printf
    add esp,8
    popad

    calnit:
    cmp byte [eax],'q'
        je end

    cmp byte [eax],'d'
        jne nex0
    cmp dword[POS],0
        je error
    cmp dword[POS],5
        je error2
    jmp duper

    nex0:
    cmp byte [eax],'+'
        jne nex
    cmp dword[POS],1
        jg adder
    jmp error
    
    nex:
    cmp byte [eax],'p'
        jne nex1
    cmp dword[POS],0
        jg printer
    jmp error

    nex1:
    cmp byte [eax],'&'
        jne nex2
    cmp dword[POS],1
        jg ander
    jmp error

    nex2:
    cmp byte [eax],'0'
        jl error3
    cmp byte [eax],'9'
        jg  error3

    nex3:
    cmp dword [POS],5
        je error2
    push eax 
    call input
    add esp , 4
    jmp loop

    adder:
    mov edx,dword [POS]
    sub edx,1
    mov ecx,edx
    sub ecx,1
    shl edx,2
    shl ecx,2
    push dword [LC1+edx]
    push dword [LC1+ecx]
    call Add
    add esp,8
    inc dword [OPS]
    jmp loop

    duper:
    mov edx,dword [POS]
    sub edx,1
    push dword [LC1+edx*4]
    call dup
    add esp,4
    inc dword [OPS]
    jmp loop

    printer:
    mov edx,dword [POS]
    sub edx,1
    shl edx,2
    push dword [LC1+edx]
    call popNprint
    add esp,4
    push 10
    push LC2
    call printf
    add esp,8
    inc dword [OPS]
    jmp loop

    ander:
    mov edx,dword [POS]
    sub edx,1
    mov ecx,edx
    sub ecx,1
    shl edx,2
    shl ecx,2
    push dword [LC1+edx]
    push dword [LC1+ecx]
    call and
    add esp,8
    inc dword [OPS]
    jmp loop

    error:
    push msg
    push LC3
    call printf
    add esp,8
    jmp loop

    error2:
    push msg3
    push LC3
    call printf
    add esp,8
    push 10
    push LC2
    call printf
    add esp,8
    jmp loop

    error3:
    push msg4
    push LC3
    call printf
    add esp,8
    jmp loop


    end:
    cmp dword [POS],0
        je done
    mov edx,dword [POS]
    sub edx,1
    shl edx,2
    push dword [LC1+edx]
    call pop
    add esp,4
    jmp end

    done:
    push dword [OPS]
    push LC4
    call printf
    add esp,8
    mov ebx,0
    mov eax,1
    int 0X80
        
    input:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     ecx, [ebp+8]    ; Copy function args to registers: leftmost...        
    

    mov ebx,0

    check_length:
    cmp byte [ecx],0
        je len
    cmp byte [ecx],10
        je len    
    inc ebx
    inc ecx
    jmp check_length


    len:
    mov ecx, dword [ebp+8]  ; Get argument (pointer to string)  
    and ebx,1
    jnz odd                 ; if the length if the number is odd
   
  
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov eax , [ANS]

    mov ebx,0
    mov ecx, dword [ebp+8]
    mov bl,[ecx]
    sub bl,48
    shl bl,4
    inc ecx
    mov dl,[ecx]
    sub dl,48
    or bl,dl
    mov [eax],bl            ;insert 2 digits into link
    mov [eax+1],dword 0
    mov [NEXT],eax
    inc ecx

    insert:
    cmp byte [ecx],0
        je last
    cmp byte [ecx],10
        je last

    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov eax , [ANS]

    mov ebx,0
    mov bl,[ecx]
    sub bl,48
    shl bl,4
    inc ecx
    mov dl,[ecx]
    sub dl,48
    or bl,dl
    mov [eax],bl            ;insert 2 digits into link
    mov edx,dword [NEXT]
    mov [eax+1],edx
    mov [NEXT],eax
    inc ecx
    jmp insert

    last:
    mov ebx,[POS]
    shl ebx,2
    mov edx,dword [NEXT]
    mov [LC1+ebx],edx
    inc dword [POS]

    cmp byte [FLAGD],1
        jne last2
    mov byte [DB],1
    pushad
    push msg6
    push LC3
    call printf
    add esp,8
    popad
    push edx
    call popNprint
    add esp,4
    mov byte [DB],0
    pushad
    push 10
    push LC2
    call printf
    add esp,8
    popad

    last2:
    jmp end_input

    odd:
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS],eax
    popad
    mov eax , [ANS]
    mov ebx,0
    mov bl,[ecx]
    sub bl,48
    mov [eax],bl            ;insert 1 digit into link
    mov [eax+1],dword 0
    mov [NEXT],eax
    inc ecx
    jmp insert
    
end_input:    ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

popNprint:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    
    mov ecx,eax
    mov ebx,0
    mov byte [FLAG],1

    length:
    cmp dword[ecx+1],0
    je bloop
    add ebx,1
    mov ecx, dword [ecx+1]
    jmp length

    bloop:

    pushad

    sloop:
    cmp ebx,0
        je print
    mov eax,dword[eax+1]
    sub ebx,1
    jmp sloop
    
    print:
    cmp byte [FLAG],1
        jne not

    mov dl,byte [eax]
    shr dl,4
    cmp dl ,0
        je second
    mov byte [FLAG],0
    movzx dx , dl
    movzx edx , dx
    
    pushad
    push edx
    push LC0
    call printf
    add esp,8   
    popad
    jmp res

    second:
    mov dl,byte [eax]
    and dl,15
    cmp dl ,0
        je endloop
    mov byte [FLAG],0
    movzx dx , dl
    movzx edx , dx

    pushad
    push edx
    push LC0
    call printf
    add esp,8   
    popad
    jmp endloop


    not:
    mov dl,byte [eax]
    shr dl,4
    movzx dx , dl
    movzx edx , dx
    
    pushad
    push edx
    push LC0    
    call printf
    add esp,8
    popad
res:
    mov dl,byte [eax]
    and dl,15
    movzx dx , dl
    movzx edx , dx

    push edx
    push LC0    

    call printf
    add esp,8
    endloop:
    popad

    sub ebx,1
    cmp ebx,-1
    je freeLink
    jmp bloop

    freeLink:
    cmp  byte [FLAG],1
        jne ff
    push dword 0
    push LC4  
    call printf
    add esp,8


    ff:    
    cmp byte [DB],1
        je fff
    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    push eax
    call pop
    add esp,4

    fff:
    ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

Add:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]    

    mov ecx,1
    mov esi,1
    mov byte [ADDFLAG],0

    alength1:
    cmp dword[eax+1],0
        je length2
    inc ecx
    mov eax, dword [eax+1]
    jmp alength1

    length2:
    cmp dword[ebx+1],0
        je  sumedx 
    inc esi
    mov ebx, dword [ebx+1]
    jmp length2

    sumedx:
    
    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]
    mov byte [CARRY],0
    mov dword[COUNT],0
    mov dword[COUNT2],0

    cmp ecx,esi
       jl skip
    mov [COUNT],dword esi
    mov [COUNT2] ,dword ecx
    jmp sumloop

    skip:
    mov dword [ANS], eax
    mov eax,ebx
    mov ebx, dword [ANS]
    mov [COUNT],dword ecx
    mov [COUNT2],dword esi
   
    sumloop:    
    cmp dword [COUNT],0
        je flower

    mov cl, byte [eax]
    and cl,15
    mov ch, byte [ebx]
    and ch,15
    add cl,byte [CARRY]
        mov byte [CARRY],0
    
    add cl,ch
    cmp cl,9
        jle left
    mov byte [CARRY],1
    sub cl,10

    left:
    mov dl, byte[eax]
    shr dl,4
    mov dh,byte[ebx]
    shr dh,4
    add dl,byte [CARRY]
        mov byte [CARRY],0

    add dl,dh
    cmp dl,9
        jle firstfinish
    mov byte [CARRY],1
    sub dl,10

    firstfinish:
    cmp byte [ADDFLAG],1
        je secondfinish
    shl dl,4
    or cl,dl
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov esi , [ANS]
    mov byte [esi],cl
    mov dword [esi+1],0
    mov [NEXT],esi
    mov [INSERT],esi
    mov byte [ADDFLAG],1
    jmp adve 

    secondfinish:
    shl dl,4
    or cl,dl
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov esi , [ANS]
    mov byte [esi],cl
    mov edx,dword [NEXT]
    mov [edx+1],esi
    mov [esi+1],dword 0
    mov [NEXT],esi

    adve:
    sub dword [COUNT],1
    sub dword [COUNT2],1
    mov eax, dword [eax+1]
    mov ebx, dword [ebx+1]

    jmp sumloop

    flower:
    cmp dword [COUNT2],0
        je end_add

    mov cl, byte [eax]
    and cl,15
    add cl, byte [CARRY]
        mov byte [CARRY],0

    cmp cl,9
        jle left2
    mov byte [CARRY],1
    sub cl,10


    left2:
    mov ch, byte[eax]
    shr ch,4
    add ch,byte [CARRY]
        mov byte [CARRY],0

    cmp ch,9
        jle finish2
    mov byte [CARRY],1
    sub ch,10

    finish2:
    shl ch,4
    or cl,ch
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov esi , [ANS]
    mov byte [esi],cl
    mov edx,dword [NEXT]
    mov [edx+1],esi
    mov [esi+1],dword 0
    mov [NEXT],esi             
    mov eax, dword [eax+1]
    sub dword [COUNT2],1
    jmp flower

    end_add:
    cmp byte[CARRY],0
    je really_end

    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov eax , [ANS]

    mov byte [eax],1
    mov dword [eax+1],0 
    mov edx,dword [NEXT]
    mov dword [edx+1],eax


    really_end:
    pushad
    mov     eax, [ebp+8]
    push eax
    call pop
    add esp,4
    mov     ebx, [ebp+12]
    push ebx
    call pop
    add esp,4
    popad
    mov ebx,[POS]
    shl ebx,2
    mov edx,dword [INSERT]
    mov [LC1+ebx],edx
    inc dword [POS]


    ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller






pop:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...     
      
    frees:
    cmp eax,0
        je end_pop
    
    mov edx, eax
    mov eax,dword[eax+1]

    pushad 
    push edx
    call free
    add esp,4
    popad

    jmp frees


    end_pop:
    sub dword [POS],1

    ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

and:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state
   
    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]    

    mov ecx,1
    mov esi,1
    mov [COUNT],dword 0
    
    length3:
    cmp dword[eax+1],0
        je length4
    inc ecx
    mov eax, dword [eax+1]
    jmp length3

    length4:
    cmp dword[ebx+1],0
        je  cmp_length2
    inc esi
    mov ebx, dword [ebx+1]
    jmp length4

    cmp_length2:
    
    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]

    cmp ecx,esi
       jl andloop
    mov ecx,esi

    andloop:
    mov [COUNT],dword ecx
    cmp dword [COUNT],0
        je end_and

    mov cl, byte [eax]
    mov ch, byte [ebx]
    and cl,ch
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov esi , [ANS]
    mov byte [esi],cl
    mov dword [esi+1],0
    mov [NEXT],esi
    mov [INSERT],esi
    jmp adv

    afterfirst:
    cmp dword [COUNT],0
        je end_and

    mov cl, byte [eax]
    mov ch, byte [ebx]
    and cl,ch
    pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS] , eax
    popad
    mov esi , [ANS]
    mov byte [esi],cl
    mov edx,dword [NEXT]
    mov [edx+1],esi
    mov [esi+1],dword 0
    mov [NEXT],esi

    adv:
    sub dword [COUNT],1
    cmp dword[ebx+1],0
        je end_and
    cmp dword[eax+1],0
        je end_and    
    mov eax, dword [eax+1]
    mov ebx, dword [ebx+1]

    jmp afterfirst

    end_and:
    pushad
    mov     eax, [ebp+8]
    push eax
    call pop
    add esp,4
    mov     ebx, [ebp+12]
    push ebx
    call pop
    add esp,4
    popad
    mov ebx,[POS]
    shl ebx,2
    mov edx,dword [INSERT]
    mov [LC1+ebx],edx
    inc dword [POS]

    ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

dup:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...     
    
mov ebx,eax 
mov dword[NEXT],0
mov ecx,0

length5:
    cmp dword[ebx+1],0
        je d
    inc ecx
    mov ebx, dword [ebx+1]
    jmp length5

d: 
mov eax, [ebp+8]
cmp ecx,-1
je end_dup
mov esi,ecx
dloop:
cmp esi,0
je dadd
mov eax,dword[eax+1]
dec esi
jmp dloop

dadd:
pushad
    push dword 5            ; push amount of bytes malloc should allocate    
    call malloc             ; call malloc
    add esp,4
    mov [ANS],eax
popad
    mov ebx , [ANS]
    mov edx,0
    mov dl,byte[eax]
    mov [ebx],dl
    mov edx,dword [NEXT]
    mov dword [ebx+1],edx
    mov [NEXT],ebx
    dec ecx
    jmp d

end_dup:
mov ebx,[POS]
mov edx,dword [NEXT]
mov [LC1+ebx*4],edx
inc dword [POS]

 ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller