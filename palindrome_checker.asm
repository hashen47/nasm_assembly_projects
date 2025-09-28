section .data
	welcome_msg            db "<<< Palindrome Checker >>>", 10, 10
	welcome_msg_len        equ $-welcome_msg

	prompt_msg             db "Enter the number: ", 0
	prompt_msg_len         equ $-prompt_msg

	palindrome_msg         db "is a palindrome...", 10, 0
	palindrome_msg_len     equ $-palindrome_msg

	not_palindrome_msg     db "not a palindrome...", 10, 0
	not_palindrome_msg_len equ $-not_palindrome_msg

	buffer_len             equ 255 
	buffer                 times buffer_len db 0 
	extra_buffer           db 0

	buffer_msg_fmt         db "input: %s", 10, 0


section .text 
	global main
	extern printf


main:
	; show welcome msg
	mov rax, 1
	mov rdi, 1
	mov rsi, welcome_msg
	mov rdx, welcome_msg_len
	syscall

	mov rdi, prompt_msg
	mov rsi, prompt_msg_len
	mov rdx, buffer 
	mov rcx, buffer_len
	call proc_read_input

	mov rdi, buffer
	mov rsi, buffer_len
	call proc_replace_newline_or_last_character_with_null

	push rbp
	mov rbp, rsp
	mov rdi, buffer_msg_fmt
	mov rsi, buffer
	call printf
	mov rsp, rbp
	pop rbp

	mov rdi, buffer
	mov rsi, buffer_len
	call proc_check_is_palindrome
	cmp rax, 1
	je palindrome

	mov rax, 1
	mov rdi, 1
	mov rsi, not_palindrome_msg
	mov rdx, not_palindrome_msg_len
	syscall
	
	jmp exit

palindrome:
	mov rax, 1
	mov rdi, 1
	mov rsi, palindrome_msg
	mov rdx, palindrome_msg_len
	syscall

exit:
	mov rax, 0x3c
	mov rdi, 0
	syscall


proc_check_is_palindrome:
	; rdi - buffer
	; rsi - buffer length
	push rbp
	mov rbp, rsp
	sub rsp, 0x18 
	mov qword [rbp-0x8], rdi   ; start pointer
	mov qword [rbp-0x10], rsi
	mov qword [rbp-0x18], 0    ; end pointer
	mov rcx, rsi
	mov rsi, rdi

.proc_check_is_palindrome_get_end_pointer_loop:
	mov dl, byte [rdi]
	cmp dl, 0 
	je proc_check_is_palindrome_after_get_end_pointer_loop
	inc rdi
	loop .proc_check_is_palindrome_get_end_pointer_loop

proc_check_is_palindrome_after_get_end_pointer_loop:
	dec rdi
	mov qword [rbp-0x18], rdi

	mov rdi, qword [rbp-0x8]
	mov rsi, qword [rbp-0x10] 
	call proc_get_buffer_length

	cdq
	mov rbx, 2
	div rbx 
	mov rcx, rax
	mov rsi, qword [rbp-0x8]
	mov rdi, qword [rbp-0x18]

proc_check_is_palindrome_checker_loop:
	xor rbx, rbx
	xor rdx, rdx
	mov bl, byte [rsi]
	mov dl, byte [rdi]
	cmp bl, dl
	jne proc_check_is_palindrome_not_palindrome
	inc rsi
	dec rdi
	loop proc_check_is_palindrome_checker_loop
	mov rax, 1	
	jmp proc_check_is_palindrome_exit

proc_check_is_palindrome_not_palindrome:
	xor rax, rax
	jmp proc_check_is_palindrome_exit

proc_check_is_palindrome_exit:
	mov rsp, rbp
	pop rbp
	ret


proc_get_buffer_length:
	; rdi - buffer
	; rsi - buffer max length
	mov rcx, rsi
	mov rsi, rdi
	xor rax, rax

.proc_get_buffer_length:
	mov dl, byte [rsi]
	cmp dl, 0 
	je proc_get_buffer_length_exit
	inc rax
	inc rsi
	loop .proc_get_buffer_length

proc_get_buffer_length_exit:
	ret


proc_read_input:
	; rdi - prompt msg 
	; rsi - prompt msg length
	; rdx - buffer
	; rcx - buffer length
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	mov qword [rbp-0x8], rdi
	mov qword [rbp-0x10], rsi
	mov qword [rbp-0x18], rdx
	mov qword [rbp-0x20], rcx
	
	; print prompt msg
	mov rax, 1
	mov rdi, 1
	mov rsi, qword [rbp-0x8]
	mov rdx, qword [rbp-0x10]
	syscall

	; read the input
	mov rax, 0
	mov rdi, 0
	mov rsi, qword [rbp-0x18]
	mov rdx, qword [rbp-0x20]
	syscall

	mov rdi, qword [rbp-0x18]
	mov rsi, qword [rbp-0x20]
	call proc_find_newline
	cmp rax, 1
	je proc_read_input_exit
	
	call proc_read_extra_buffer

proc_read_input_exit:
	mov rsp, rbp
	pop rbp
	ret


proc_read_extra_buffer:
	; rdi - buffer length
	mov rcx, rdi

.proc_read_extra_buffer_loop:
	mov rax, 0
	mov rdi, 0
	mov rsi, extra_buffer
	mov rdx, 1
	syscall

	mov dl, byte [extra_buffer]
	cmp dl, 10
	je proc_read_extra_buffer_exit

	loop .proc_read_extra_buffer_loop

proc_read_extra_buffer_exit:
	ret


proc_find_newline:
	; rdi - buffer
	; rsi - buffer length
	xor rax, rax
	mov rcx, rsi 
	mov rsi, rdi

.proc_find_newline_loop:
	mov dl, byte [rsi]
	cmp dl, 10
	je proc_find_newline_find
	inc rsi
	loop .proc_find_newline_loop
	jmp proc_find_newline_exit

proc_find_newline_find:
	mov rax, 1
	jmp proc_find_newline_exit

proc_find_newline_exit:
	ret


proc_replace_newline_or_last_character_with_null:
	; rdi - buffer
	; rsi - buffer length
	mov rcx, rsi
	mov rsi, rdi

proc_replace_newline_or_last_character_with_null_loop:
	mov dl, byte [rsi]
	cmp dl, 10
	je proc_replace_newline_or_last_character_with_null_newline_found
	inc rsi
	loop proc_replace_newline_or_last_character_with_null_loop
	jmp proc_replace_newline_or_last_character_with_null_newline_not_found

proc_replace_newline_or_last_character_with_null_newline_found:
	mov byte [rsi], 0
	jmp proc_replace_newline_or_last_character_with_null_exit

proc_replace_newline_or_last_character_with_null_newline_not_found:
	dec rsi
	mov byte [rsi], 0

proc_replace_newline_or_last_character_with_null_exit:
	ret


section .note.GNU-stack
