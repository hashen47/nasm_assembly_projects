section .data
	MAX_BUF_LEN:          equ 20 
	number_input_msg:     db "Enter the number: "
	number_input_len:     equ $-number_input_msg
	number_output_fmt:    db "number: %ld", 10, 0
	fibonacii_output_fmt: db "fibonacii number: %ld", 10, 0
	atoi_error_fmt:       db "invalid positive whole number: %s", 10, 0


section .bss
	buffer    resb MAX_BUF_LEN
	extra_buf resb 1
	number    resq 1
	ans       resq 1
	

section .text
	global main
	extern printf


main:
	mov rax, 1
	mov rdi, 1
	lea rsi, [number_input_msg]
	mov rdx, number_input_len
	syscall

	call proc_read_buffer
	call proc_atoi
	cmp rbx, 1
	je atoi_fail

	push rbp
	mov rbp, rsp 
	lea rdi, [number_output_fmt]
	mov rsi, [number] 
	call printf
	mov rsp, rbp
	pop rbp

	call proc_calculate_fibonacii

	push rbp
	mov rbp, rsp 
	lea rdi, [fibonacii_output_fmt]
	mov rsi, [ans] 
	call printf
	mov rsp, rbp
	pop rbp

exit:
	mov rax, 0x3c 
	mov rdi, 0
	syscall

atoi_fail:
	push rbp
	mov rbp, rsp
	lea rdi, [atoi_error_fmt]
	lea rsi, [buffer]
	call printf
	mov rsp, rbp
	pop rbp

fail:
	mov rax, 0x3c
	mov rdi, 1
	syscall


proc_calculate_fibonacii:
	push rbp
	mov rbp, rsp
	sub rsp, 0x18
	mov qword [rbp-0x8], 0
	mov qword [rbp-0x10], 0
	cmp qword [number], 0
	je proc_calculate_fibonacii_exit
	mov qword [rbp-0x10], 1
	cmp qword [number], 1 
	je proc_calculate_fibonacii_exit
	xor rdx, rdx
	mov rcx, [number]
	sub rcx, 1

.proc_calculate_fibonacii:
	mov rdx, qword [rbp-0x8] 
	add rdx, qword [rbp-0x10] 
	mov rax, qword [rbp-0x10]
	mov qword [rbp-0x8], rax 
	mov qword [rbp-0x10], rdx
	loop .proc_calculate_fibonacii

proc_calculate_fibonacii_exit:
	mov rax, qword [rbp-0x10]
	mov qword [ans], rax 
	mov rsp, rbp
	pop rbp
	ret


proc_atoi:
	xor rax, rax
	xor rdi, rdi
	lea rsi, [buffer]
	mov rcx, MAX_BUF_LEN
	xor rbx, rbx 

.proc_atoi_loop:
	xor rdx, rdx
	mov dl, byte [rsi]
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
	jmp proc_atoi_exit

proc_atoi_fail:
	mov rbx, 1

proc_atoi_exit:
	mov [number], rax
	ret


proc_read_buffer:
	xor rax, rax
	xor rdi, rdi
	lea rsi, [buffer]
	mov rdx, MAX_BUF_LEN
	syscall

	call proc_find_newline
	cmp rax, 1
	je proc_read_buffer_exit

.proc_read_buffer_loop:
	xor rax, rax 
	xor rdi, rdi
	lea rsi, [extra_buf]
	mov rdx, 1
	syscall
	cmp byte [rsi], 10
	je proc_read_buffer_exit
	loop .proc_read_buffer_loop
	
proc_read_buffer_exit:
	ret


proc_find_newline:
	lea rsi, [buffer]
	xor rax, rax
	mov rcx, MAX_BUF_LEN

.proc_find_newline_loop:
	mov dl, byte [rsi]
	cmp dl, 10
	mov rax, 1
	je proc_find_newline_exit
	xor rax, rax
	inc rsi
	loop .proc_find_newline_loop

proc_find_newline_exit:
	ret


section .note.GNU-stack
