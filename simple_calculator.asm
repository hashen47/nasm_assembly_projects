; NOTE:
; simple calculator (currently not supported for floating point values)
; do given operation between two numbers (n1 and n2)
; operators: (+, -, *, /, %)


section .data
	max_num_size:      equ 8 

	welcome_msg:       db "simple calculator (currently not supported for floating point numbers)", 10
	welcome_msg_len:   equ $-welcome_msg 
	n1_input_msg:      db "Enter n1: "
	n1_input_msg_len:  equ $-n1_input_msg 
	n2_input_msg:      db "Enter n2: "
	n2_input_msg_len:  equ $-n2_input_msg 
	opt_input_msg:     db "Enter operator (+-*/%): "
	opt_input_msg_len: equ $-opt_input_msg

	ans:               dq 0

	ans_fmt:           db "%d %c %d = %d", 10, 0
	n1_output_fmt:     db "n1: %d", 10, 10, 0
	n2_output_fmt:     db "n2: %d", 10, 10, 0
	opt_output_fmt:    db "opt: %c", 10, 10, 0
	n1_err_fmt:        db "invalid n1: %s", 10, 0
	n2_err_fmt:        db "invalid n2: %s", 10, 0
	opt_err_fmt:       db "invalid opt: %c", 10, 0


section .bss
	n1_str    resb max_num_size 
	n2_str    resb max_num_size 
	opt       resb 1
	n1        resq 1
	n2        resq 1
	extra_buf resb 1


section .text
	global main
	extern printf


main:
	call func_welcome

	mov rax, 1
	mov rdi, 1
	lea rsi, [n1_input_msg]
	mov rdx, n1_input_msg_len
	syscall

	lea rdi, [n1_str]
	mov rsi, max_num_size
	call func_read_buffer

	lea rdi, [n1_str]
	mov rsi, max_num_size
	call func_ascii_to_number
	cmp rbx, 1
	je n1_fail 
	mov [n1], rax

	push rbp
	mov rbp, rsp
	lea rdi, n1_output_fmt
	mov rsi, [n1]
	call printf
	mov rsp, rbp
	pop rbp

	mov rax, 1
	mov rdi, 1
	lea rsi, [n2_input_msg]
	mov rdx, n2_input_msg_len
	syscall

	lea rdi, [n2_str]
	mov rsi, max_num_size
	call func_read_buffer

	lea rdi, [n2_str]
	mov rsi, max_num_size
	call func_ascii_to_number
	cmp rbx, 1
	je n2_fail
	mov [n2], rax

	push rbp
	mov rbp, rsp
	lea rdi, n2_output_fmt
	mov rsi, [n2]
	call printf
	mov rsp, rbp
	pop rbp

	mov rax, 1
	mov rdi, 1
	lea rsi, [opt_input_msg]
	mov rdx, opt_input_msg_len
	syscall

	lea rdi, [opt]
	mov rsi, 1
	call func_read_buffer

	xor rax, rax
	mov al, [opt]
	mov rdi, rax
	call func_validate_opt
	cmp rbx, 1
	je opt_fail

	push rbp
	mov rbp, rsp
	lea rdi, opt_output_fmt
	xor rdx, rdx
	mov dl, [opt]
	mov rsi, rdx 
	call printf
	mov rsp, rbp
	pop rbp

	mov rdi, [n1] 
	mov rsi, [n2] 
	xor rdx, rdx
	mov dl, [opt] 
	lea rcx, ans
	call func_calculate_result

	push rbp
	mov rbp, rsp
	lea rdi, ans_fmt
	mov rsi, [n1]
	xor rdx, rdx
	mov dl, [opt]
	mov rcx, [n2]
	mov r8, [ans]
	call printf
	mov rsp, rbp
	pop rbp

exit:
	mov rax, 0x3c
	mov rdi, 0
	syscall

n1_fail:
	push rbp
	mov rbp, rsp
	lea rdi, n1_err_fmt
	lea rsi, n1_str
	call printf
	mov rsp, rbp
	pop rbp
	jmp fail

n2_fail:
	push rbp
	mov rbp, rsp
	lea rdi, n2_err_fmt
	lea rsi, n2_str
	call printf
	mov rsp, rbp
	pop rbp
	jmp fail

opt_fail:
	push rbp
	mov rbp, rsp
	lea rdi, opt_err_fmt
	xor rdx, rdx 
	mov dl, [opt]
	mov rsi, rdx
	xor rdx, rdx
	call printf
	mov rsp, rbp
	pop rbp

fail:
	mov rax, 0x3c
	mov rdi, 1
	syscall


func_welcome:
	mov rax, 1
	mov rdi, 1
	lea rsi, welcome_msg 
	mov rdx, welcome_msg_len
	syscall
	ret


func_found_newline: ; is newline found rax set to 1, else set to 0 
	push rcx
	mov rax, 0
	mov rcx, rsi 
func_found_newline_loop:
	mov dl, byte [rdi]
	cmp dl, 10
	je newline_found
	inc rdi
	loop func_found_newline_loop
	jmp func_found_newline_exit
newline_found:
	mov rax, 1
func_found_newline_exit:
	pop rcx
	ret


func_read_buffer:
	mov rax, 0
	mov rdx, rsi
	mov rsi, rdi
	mov rdi, 0
	syscall
	mov rdi, rsi
	mov rsi, rdx
	call func_found_newline
	cmp rax, 1
	je func_read_buffer_exit

.read_extra_buffer:
	mov rax, 0
	mov rdi, 0
	lea rsi, [extra_buf]
	mov rdx, 1
	syscall
	mov dl, [extra_buf]
	cmp dl, 10
	je func_read_buffer_exit
	jmp .read_extra_buffer

func_read_buffer_exit:
	ret


func_ascii_to_number:
	xor rbx, rbx
	xor rax, rax 
	xor rdx, rdx
	mov r8, 1
	mov rcx, rsi
	mov dl, byte [rdi]
	cmp dl, '+'
	inc rdi
	je .func_ascii_to_number_loop
	dec rdi
	cmp dl, '-'
	jne .func_ascii_to_number_loop
	mov r8, -1
	inc rdi

.func_ascii_to_number_loop:
	xor rdx, rdx
	mov dl, byte [rdi]
	cmp dl, 10
	je func_ascii_to_number_exit
	cmp dl, 48
	jl func_ascii_to_number_fail
	cmp dl, 57
	jg func_ascii_to_number_fail
	sub dl, '0'
	imul rax, 10
	add rax, rdx
	inc rdi
	loop .func_ascii_to_number_loop
	jmp func_ascii_to_number_exit

func_ascii_to_number_fail:
	xor rax, rax
	mov rbx, 1

func_ascii_to_number_exit:
	imul rax, r8
	ret


func_validate_opt:
	xor rbx, rbx
	mov rdx, rdi
	cmp dl, '+'
	jne func_validate_opt_sub
	jmp func_validate_opt_end

func_validate_opt_sub:
	cmp dl, '-'
	jne func_validate_opt_mult
	jmp func_validate_opt_end

func_validate_opt_mult:
	cmp dl, '*'
	jne func_validate_opt_div
	jmp func_validate_opt_end

func_validate_opt_div:
	cmp dl, '/'
	jne func_validate_opt_modular
	jmp func_validate_opt_end

func_validate_opt_modular:
	cmp dl, '%'
	je func_validate_opt_end

func_validate_opt_fail:
	mov rbx, 1

func_validate_opt_end:
	ret


func_calculate_result:
	; rdi - n1 value 
	; rsi - n2 value 
	; rdx - operator
	; rcx - ans address
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	mov qword [rbp-0x8], rdi
	mov qword [rbp-0x10], rsi
	mov qword [rbp-0x18], rcx
	mov byte [rbp-0x19], dl
	xor rax, rax
	add rax, qword [rbp-0x8]
	mov dl, byte [rbp-0x19]
	cmp dl, '+'
	jne func_calculate_result_sub
	add rax, qword [rbp-0x10] 
	jmp func_calculate_result_end

func_calculate_result_sub:
	cmp dl, '-'
	jne func_calculate_result_mult
	sub rax, qword [rbp-0x10]
	jmp func_calculate_result_end

func_calculate_result_mult:
	cmp dl, '*'
	jne func_calculate_result_div
	imul rax, [rbp-0x10]
	jmp func_calculate_result_end

func_calculate_result_div:
	cmp dl, '/'
	jne func_calculate_result_modular
	cqo
	idiv qword [rbp-0x10]
	jmp func_calculate_result_end

func_calculate_result_modular:
	cqo
	idiv qword [rbp-0x10]
	mov rax, rdx

func_calculate_result_end:
	mov rbx, qword [rbp-0x18]
	mov [rbx], rax
	mov rsp, rbp
	pop rbp 
	ret


section .note.GNU-stack 
