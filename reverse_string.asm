section .data
	input_msg         : db "Enter the string: ", 0
	input_msg_len     : equ $-input_msg
	original_str_fmt  : db "original string: %s", 10, 0
	reverse_str_fmt   : db "reverse string : %s", 10, 0

	max_input_length: equ 255
	input_length    : dq 0 


section .bss
	extra_buf resb 1 
	input     resb max_input_length


section .text
	global main
	extern printf


main:
	mov rax, 1
	mov rdi, 1
	lea rsi, input_msg
	mov rdx, input_msg_len 
	syscall

	mov rdi, max_input_length
	lea rsi, [input]
	call func_read_buffer

	mov rdi, max_input_length
	lea rsi, [input]
	call func_get_buffer_length_and_rm_last_newline
	mov [input_length], rax

	push rbp
	mov rsp, rsp
	lea rdi, [original_str_fmt]
	lea rsi, [input]
	call printf
	mov rsp, rbp
	pop rbp

	mov rdi, [input_length]
	lea rsi, [input]
	call func_reverse_buffer

	push rbp
	mov rsp, rsp
	lea rdi, [reverse_str_fmt]
	call printf
	mov rsp, rbp
	pop rbp

	mov rax, 0x3c
	mov rdi, 0
	syscall


func_read_buffer:
	; rdi: length
	; rsi: input container 
	mov r8, rdi 
	mov rax, 0
	mov rdi, 0
	mov rdx, r8 
	syscall

	mov rdi, r8
	call func_find_newline
	cmp rax, 1
	je func_read_buffer_end

.read_extra_buffer:
	mov rax, 0
	mov rdi, 0
	lea rsi, [extra_buf]
	mov rdx, 1
	syscall

	cmp byte [extra_buf], 10 
	je func_read_buffer_end
	jmp .read_extra_buffer

func_read_buffer_end:
	ret


func_find_newline:
	; rdi: length 
	; rsi: input container
	mov rcx, rdi

.func_find_newline_loop:
	mov rax, 1
	mov dl, byte [rsi]
	cmp dl, 10 
	je func_find_newline_exit
	xor rax, rax
	inc rsi
	loop .func_find_newline_loop

func_find_newline_exit:
	ret


func_get_buffer_length_and_rm_last_newline:
	; this function don't count the last newline
	; rdi: max_length
	; rsi: buffer
	mov rcx, rdi
	xor rdi, rdi

.func_get_buffer_length_and_rm_last_newline_loop:
	mov dl, byte [rsi]
	cmp dl, 10
	je func_get_buffer_length_and_rm_last_newline_found_newline 
	inc rsi
	inc rdi
	loop .func_get_buffer_length_and_rm_last_newline_loop
	jmp func_get_buffer_length_and_rm_last_newline_exit

func_get_buffer_length_and_rm_last_newline_found_newline:
	mov byte [rsi], 0

func_get_buffer_length_and_rm_last_newline_exit:
	mov rax, rdi
	ret


func_reverse_buffer:
	; rdi: buffer length
	; rsi: buffer pointer
	mov r10, rdi
	dec r10
	mov rax, rdi
	mov rdi, 2
	cqo
	idiv rdi 
	mov rdi, rax 
	xor r8, r8

.func_reverse_buffer_loop:
	cmp r8, rdi 
	je func_reverse_buffer_exit
	mov dl, byte [rsi+r8]
	mov cl, byte [rsi+r10]
	mov byte [rsi+r8], cl 
	mov byte [rsi+r10], dl 
	inc r8
	dec r10 
	jmp .func_reverse_buffer_loop

func_reverse_buffer_exit:
	ret


section .note.GNU-stack
