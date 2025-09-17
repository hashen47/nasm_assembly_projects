section .data
	max_buffer_len     equ 15 
	number             dq 0
	max_integer_number equ 18446744073709551615 ; maximum unsigned integer number that can store in a 64bit register

	prompt_msg     db "Enter the number: "
	prompt_msg_len equ $-prompt_msg

	atoi_invalid_number_fail_msg_fmt    db "invalid number input: %s", 10, 0
	atoi_negative_number_fail_msg_fmt   db "number cannot be negative: %s", 10, 0
	number_output_fmt                   db "number: %zu", 10, 0
	factorial_output_fmt                db "factorial: %zu", 10, 0


section .bss
	buffer       resb max_buffer_len 
	extra_buffer resb 1


section .text
	global main
	extern printf


main:
	mov rax, 1
	mov rdi, 1
	lea rsi, [prompt_msg]
	mov rdx, prompt_msg_len
	syscall

	call proc_read_buffer

	call proc_atoi
	cmp rax, 1
	je atoi_invalid_number_fail

	cmp qword [number], 0
	jl atoi_negative_number_fail 

	push rbp
	mov rbp, rsp
	lea rdi, [number_output_fmt]
	mov rsi, [number]
	call printf
	mov rsp, rbp
	pop rbp
	
	call proc_calculate_factorial

	push rbp
	mov rbp, rsp
	lea rdi, [factorial_output_fmt]
	mov rsi, rax
	call printf
	mov rsp, rbp
	pop rbp

	jmp exit 

atoi_invalid_number_fail:
	push rbp
	mov rbp, rsp
	lea rdi, [atoi_invalid_number_fail_msg_fmt]
	lea rsi, [buffer]
	call printf
	mov rsp, rbp
	pop rbp
	jmp fail_exit

atoi_negative_number_fail:
	push rbp
	mov rbp, rsp
	lea rdi, [atoi_negative_number_fail_msg_fmt]
	lea rsi, [buffer]
	call printf
	mov rsp, rbp
	pop rbp
	
fail_exit:
	mov rax, 0x3c
	mov rdi, 1
	syscall

exit:
	mov rax, 0x3c
	mov rdi, 0
	syscall


proc_calculate_factorial:
	xor rax, rax
	mov rcx, [number]
	cmp rcx, 0
	je proc_calculate_factorial_exit 
	mov rax, 1

.proc_calculate_factorial_loop:
	mul rcx
	mov rbx, max_integer_number
	xor rdx, rdx
	div rbx
	mov rax, rdx ; doing this modular thing to handle overflow
	loop .proc_calculate_factorial_loop

proc_calculate_factorial_exit:
	ret


proc_atoi:
	xor rax, rax
	mov r8, 1 
	lea rsi, [buffer]
	mov rcx, max_buffer_len
	mov dl, [rsi]
	cmp dl, '-'
	jne .proc_atoi_loop
	mov r8, -1
	inc rsi

.proc_atoi_loop:
	xor rdx, rdx
	mov dl, [rsi]
	cmp dl, 10
	je proc_atoi_exit
	cmp dl, 48
	jl proc_atoi_fail
	cmp dl, 57
	jg proc_atoi_fail
	sub dl, '0'
	imul rax, 10
	add rax, rdx
	inc rsi
	loop .proc_atoi_loop
	xor rbx, rbx
	jmp proc_atoi_exit

proc_atoi_fail:
	mov rbx, 1

proc_atoi_exit:
	imul rax, r8
	mov [number], rax
	mov rax, rbx
	ret


proc_read_buffer:
	mov rax, 0
	mov rdi, 0
	lea rsi, [buffer]
	mov rdx, max_buffer_len
	syscall

	call proc_find_newline
	cmp rax, 1
	je proc_read_buffer_exit

	call proc_read_extra_buffer

proc_read_buffer_exit:
	ret


proc_find_newline:
	xor rax, rax
	lea rsi, [buffer]
	mov rcx, max_buffer_len

.proc_find_newline:
	mov dl, [rsi]
	cmp dl, 10
	je proc_find_newline_found
	inc rsi
	loop .proc_find_newline
	jmp proc_find_newline_exit

proc_find_newline_found:
	mov rax, 1

proc_find_newline_exit:
	ret


proc_read_extra_buffer:
	mov rcx, max_buffer_len

.proc_read_extra_buffer:
	mov rax, 0
	mov rdi, 0
	lea rsi, [extra_buffer]
	mov rdx, 1
	syscall

	mov dl, [extra_buffer] 
	cmp dl, 10
	je proc_read_extra_buffer_exit
	loop .proc_read_extra_buffer

proc_read_extra_buffer_exit:
	ret


section .note.GNU-stack
