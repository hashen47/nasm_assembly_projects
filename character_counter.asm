; character counter 
; count vowels, consonants, digits, or spaces in a string.


section .data
	max_buf_len        equ 255 

	vowel_count        dq 0
	consonants_count   dq 0
 	digit_count        dq 0
	space_count        dq 0

	newline            db 10
	newline_len        equ $-newline

	prompt_msg         db "enter the string: "
	prompt_msg_len     equ $-prompt_msg

	buf_output_msg     db  10, "string: "
	buf_output_msg_len equ $-buf_output_msg

	character_count_output_fmt   db 10, "vowel count: %ld", 10, "consonants count: %ld", 10, "digit count: %ld", 10, "spaces count: %ld", 10, 0


section .bss
	buf       resb max_buf_len
	extra_buf resb 1


section .text
	global main
	extern printf


main: 
	; show prompt msg
	mov rax, 1
	mov rdi, 1
	lea rsi, [prompt_msg]
	mov rdx, prompt_msg_len
	syscall

	call proc_read_buf

	; show entered string
	mov rax, 1
	mov rdi, 1
	lea rsi, [buf_output_msg]
	mov rdx, buf_output_msg_len
	syscall

	mov rax, 1
	mov rdi, 1
	lea rsi, [buf]
	mov rdx, max_buf_len
	syscall

	; if string have newline at the end doesn't print the newline, otherwise print the newline
	call proc_find_newline
	cmp rax, 1
	je proc_count_characters_label
	mov rax, 1
	mov rdi, 1
	lea rsi, [newline] 
	mov rdx, newline_len
	syscall
	
proc_count_characters_label:
	call proc_count_characters

	; show character counts msg
	push rbp
	mov rbp, rsp
	lea rdi, [character_count_output_fmt]
	mov rsi, [vowel_count]
	mov rdx, [consonants_count] 
	mov rcx, [digit_count] 
	mov r8, [space_count]
	call printf
	mov rsp, rbp
	pop rbp

	mov rax, 0x3c
	mov rdi, 0
	syscall


proc_count_characters:
	mov rcx, max_buf_len
	lea rax, [buf]
	mov rcx, max_buf_len

proc_count_characters_loop_start:
	cmp rcx, 0
	jle proc_count_characters_exit
	dec rcx

	mov dl, [rax]
	cmp dl, 10
	je proc_count_characters_exit

	; vowel 
	cmp dl, 'a'
	je proc_count_characters_found_vowel
	cmp dl, 'A' 
	je proc_count_characters_found_vowel
	cmp dl, 'e'
	je proc_count_characters_found_vowel
	cmp dl, 'E' 
	je proc_count_characters_found_vowel
	cmp dl, 'i'
	je proc_count_characters_found_vowel
	cmp dl, 'I' 
	je proc_count_characters_found_vowel
	cmp dl, 'o'
	je proc_count_characters_found_vowel
	cmp dl, 'O' 
	je proc_count_characters_found_vowel
	cmp dl, 'u'
	je proc_count_characters_found_vowel
	cmp dl, 'U' 
	je proc_count_characters_found_vowel

	; space
	cmp dl, 32 
	je proc_count_characters_found_space

	; digit
	cmp dl, 48
	jl proc_count_characters_finding_uppercase_consonant
	cmp dl, 57
	jg proc_count_characters_finding_uppercase_consonant
	jmp proc_count_characters_found_digit

	; lowercase consonant
proc_count_characters_finding_uppercase_consonant:
	cmp dl, 65
	jl proc_count_characters_finding_lowercase_consonant
	cmp dl, 90
	jg proc_count_characters_finding_lowercase_consonant
	jmp proc_count_characters_found_consonant

	; uppercase consonant
proc_count_characters_finding_lowercase_consonant:
	cmp dl, 97
	jl proc_count_characters_loop_end 
	cmp dl, 122
	jg proc_count_characters_loop_end 
	jmp proc_count_characters_found_consonant
	
proc_count_characters_found_vowel:
	add qword [vowel_count], 1
	jmp proc_count_characters_loop_end

proc_count_characters_found_consonant:
	add qword [consonants_count], 1
	jmp proc_count_characters_loop_end

proc_count_characters_found_digit:
	add qword [digit_count], 1
	jmp proc_count_characters_loop_end

proc_count_characters_found_space:
	add qword [space_count], 1
	jmp proc_count_characters_loop_end

proc_count_characters_loop_end:
	inc rax
	jmp proc_count_characters_loop_start

proc_count_characters_exit:
	ret


proc_read_buf:
	xor rax, rax
	xor rax, rax
	lea rsi, [buf]
	mov rdx, max_buf_len
	syscall

	call proc_find_newline
	cmp rax, 1
	je proc_read_buf_exit
	
	call proc_read_extra_buf

proc_read_buf_exit:
	ret


proc_find_newline:
	lea rax, [buf]
	mov rcx, max_buf_len

.proc_find_newline_loop:
	mov dl, [rsi]
	cmp dl, 10
	je proc_find_newline_found
	inc rsi
	loop .proc_find_newline_loop

proc_find_newline_not_found:
	xor rax, rax
	jmp proc_find_newline_exit

proc_find_newline_found:
	mov rax, 1

proc_find_newline_exit:
	ret


proc_read_extra_buf:
	mov rcx, max_buf_len

.proc_read_extra_buf_loop:
	xor rax, rax
	mov rdi, rdi
	lea rsi, [extra_buf]
	mov rdx, 1
	syscall

	mov dl, [extra_buf]
	cmp dl, 10
	je proc_read_extra_buf_exit

	loop .proc_read_extra_buf_loop

proc_read_extra_buf_exit:
	ret


section .note.GNU-stack
