%include "asm_io.inc"

SECTION .data
err1: db "incorrect number of command line arguments",10,0
err2: db "incorrect command line argument",10,0
initial: db "initial configuration",10,0
final: db "final configuration",10,0
XX: db "XXXXXXXXXXXXXXXXXXXXXX",10,0
peg: times 10 dd 0
change: dd 0

SECTION .bss
input: resd 1
no_of_os: resd 1


SECTION .text
global asm_main

;------------------------------------------------------------------------------------

showp:
	enter 0,0
	pusha
	mov ebx, [ebp+8]			; store address of array in ebx
	mov ecx, dword 0			; set eax to 0
	mov ecx, [ebp+12]			; number of pegs in ecx

	dec ecx						; decrement ecx to obtain index
	imul ecx, ecx, 4			; ecx contains offset to last element
	add ebx, ecx				; ebx points to last element in peg

					; LOOP THROUGH ELEMENTS N TO 1

	LOOP_SHOWP:
		mov eax, [ebx]			; eax holds value at ebx
		push eax				; push element to stack
		call print_line			; and call subroutine to print the line
		add esp, 4				; restore stack
		sub ecx, 4				; decrement number of pegs
		sub ebx, 4				; point to previous element in peg
		cmp ecx, dword 0		; if no. of pegs > 0
		ja LOOP_SHOWP			; loop again

					; PRINT LAST ELEMENT AND BASE SEPARATELY

	mov ebx, [ebp+8]			; ebx points to first element
	mov eax, [ebx]				; eax containt first element
	push eax
	call print_line				; function call
	add esp, 4					; restore stack
	mov eax, XX
	call print_string			; print base of X's
	call print_nl
	call read_char				; wait for user to press enter

	popa
	leave
	ret

;------------------------------------------------------------------------------------

print_line:						; subroutine to print each line, called by showp
	enter 0,0
	pusha
	mov ecx, [ebp+8]			; ecx contains number of disks on peg
	mov [no_of_os], ecx			; store in memory
	mov edx, dword 11
	sub edx, ecx				; edx contains number of spaces

					; PRINT SPACES BEFORE O's

	SPACES:
		cmp edx, dword 0		; if no. of spaces is <= 0
		jbe O_LEFT				; jump to next loop
		mov eax, ' '
		call print_char			; print space
		dec edx
		jmp SPACES

					; PRINT O's ON LEFT

	O_LEFT:
		mov eax, 'o'
		call print_char			; print 'o'
		dec ecx
		cmp ecx, dword 0		; if no. of o's is <= 0
		ja O_LEFT				; jump to start of loop

					; PRINT '|'

	mov eax, '|'
	call print_char
	mov ecx, dword [no_of_os]

					; PRINT O's ON RIGHT
	O_RIGHT:
		mov eax, 'o'
		call print_char			; print 'o'
		dec ecx
		cmp ecx, dword 0		; if no. of o's is <= 0
		ja O_RIGHT				; jump to start of loop

	call print_nl
	popa
	leave
	ret

;------------------------------------------------------------------------------------

sorthem:
	enter 0,0
	pusha
	mov ebx, [ebp+8]			; address of peg in ebx
	mov ecx, [ebp+12]			; no. of disks in ecx 

					; CHECK NO. OF DISKS == 1

	cmp ecx, dword 1			; base case
	je DONE						; done sorting

					; RECURSIVE CALL

	mov edx, ecx				; store original values
	mov esi, ebx				; esi has base address
	dec ecx						; n-1
	add ebx, 4					; A+4
	push ecx
	push ebx
	call sorthem				; recursive call
	add esp, 8					; clean stack
	
	mov edi, dword 0			; edi = 0
	
					; SORTING LOOP

	SORT:
		cmp edi, edx
		ja SORT_END
		imul edi, edi, 4
		mov ebx, [esi+edi]
		mov ecx, edi
		add ecx, 4
		mov eax, [ecx+esi]
		cmp ebx, eax
		ja NEXT_ITER
		mov [esi+edi], eax
		mov [ecx+esi], ebx
		shr edi, 2
		mov [change], dword 1	; set change to 1

	NEXT_ITER:
		inc edi
		jmp SORT

	SORT_END:
		cmp [change], 0
		je DONE
		push dword [input]
		push peg
		call showp
		add esp, 8

	DONE:
		popa
		leave
		ret

;------------------------------------------------------------------------------------

asm_main:
	enter 0,0
	pusha

					; CHECK ARG COUNT

	mov edx, dword[ebp+8] 		; get argc
	cmp edx, dword 2     		; check it is 2
	jne ERR1             		; if not display err1 and terminate asm_main
	
					; CHECK ARG BETWEEN 2-9
	
	mov eax,dword[ebp+12]		; get argv[1]
	mov ebx, dword[eax+4]
	mov eax, dword 0
	mov al, byte[ebx]    		; get the first byte of argv[1]
	cmp al, byte '1'
	jbe ERR2					; display error 2 if first byte is less than or equal to ascii code for 1
	cmp al, byte '9'
	ja ERR2						; display error 2 if first byte is greater than ascii code for 9
	mov cl, byte [ebx+1]		; get second byte of argv[1]
	cmp cl, 0
	jne ERR2					; display error 2 if second byte is not 0
	sub al, '0' 				; al contains digit
	mov [input], eax			; store passed integer in memory

					; CALL RCONF
	
	push eax					; pass no. of pegs as 2nd arg to rconf
	mov ebx, peg
	push ebx					; pass address of first peg as 1st arg
	call rconf
	pop ebx						; pop off stack
	pop eax

					; INITIAL CONFIGURATION DISPLAY
	

	mov eax, initial
	call print_string
	mov eax, dword [input]
	push eax
	push peg
	call showp
	add esp, 8

					; SORT USING SORTHEM SUBROUTINE

	push eax
	push peg
	call sorthem
	add esp, 8

					; FINAL CONFIGURATION DISPLAY

	mov eax, final
	call print_string
	mov eax, dword [input]
	push eax
	push peg
	call showp
	add esp, 8
	jmp EXIT

ERR1:
	mov eax, err1				; displays err1
   	call print_string
   	jmp EXIT

ERR2:
   	mov eax, err2				; displays err2
   	call print_string

EXIT:							; Exit routine
	popa
	leave
	ret