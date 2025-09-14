section .data
	el_size         equ 8
	el_count        equ 5 
	max_buf_len     equ 18

	array_i         dq 0

	input_fmt       db "Enter (%ld) > ", 0
	output_fmt      db "(%ld) > %ld", 10, 10, 0
	sum_output_fmt  db "Sum: %ld", 10, 0
	invalid_num_fmt db "invalid number: %.18s", 0


section .bss
	extra_buf resb 1
	buf       resb max_buf_len 
	array     resq el_count
	array_sum resq 1


section .text
	global main
	extern printf
	extern fflush


main:
.read_loop:
	; print prompt
	push rbp
	mov rbp, rsp
	lea rdi, [input_fmt]
	mov rsi, qword [array_i]
	inc rsi
	call printf
	mov rsp, rbp
	pop rbp

	; call fflush
	push rbp
	mov rbp, rsp
	mov rdi, 0
	call fflush
	mov rsp, rbp
	pop rbp

	; restore the buffer
	call proc_restore_buf

	; read the buf
	call proc_read_buf

	; convert buf to number
	call proc_atoi
	cmp rbx, 1
	je fail_exit

	; add value to array
	mov rbx, qword [array_i]
	imul rbx, el_size
	mov [array+rbx], rax

	; print the value of current array element 
	push rbp
	mov rbp, rsp
	lea rdi, [output_fmt]
	mov rsi, [array_i]
	add rsi, 1
	mov rdx, rax 
	call printf
	mov rsp, rbp
	pop rbp
	
	; inc n
	add qword [array_i], 1
	cmp qword [array_i], el_count
	jl .read_loop

	; calculate the sum
	call proc_cal_sum

	; print the sum
	push rbp
	mov rbp, rsp
	lea rdi, [sum_output_fmt]
	mov rsi, qword [array_sum]
	call printf
	mov rsp, rbp
	pop rbp

	; exit the program
	mov rax, 0x3c
	mov rdi, 0
	syscall

fail_exit:
	; print the error msg
	mov rbp, rsp
	lea rdi, [invalid_num_fmt]
	lea rsi, [buf]
	call printf
	mov rsp, rbp
	pop rbp

	mov rax, 0x3c
	mov rdi, 1
	syscall


proc_read_buf:
	mov rax, 0
	mov rdi, 0
	lea rsi, [buf]
	mov rdx, max_buf_len
	syscall

	call proc_is_newline_exists
	cmp rbx, 1
	je proc_read_buf_exit

	call proc_read_extra_buf

proc_read_buf_exit:
	ret


proc_read_extra_buf:
	mov rcx, max_buf_len

.proc_read_extra_buf_loop:
	mov rax, 0
	mov rdi, 0
	lea rsi, [extra_buf]  
	mov rdx, 1
	syscall

	mov dl, [extra_buf]
	cmp dl, 10
	je proc_read_extra_buf_exit
	loop .proc_read_extra_buf_loop
	jmp proc_read_extra_buf_exit

proc_read_extra_buf_exit:
	ret


proc_is_newline_exists:
	mov rdi, 0
	xor rbx, rbx
	mov rcx, max_buf_len
	lea rsi, [buf]

.proc_is_newline_exists_loop:
	mov dl, byte [rsi]
	cmp dl, 10
	je proc_is_newline_exists_found_newline
	inc rsi
	loop .proc_is_newline_exists_loop
	jmp proc_is_newline_exists_exit

proc_is_newline_exists_found_newline:
	mov rbx, 1

proc_is_newline_exists_exit:
	ret


proc_restore_buf:
	mov rcx, max_buf_len
	lea rsi, [buf]
	sub rcx, 1

.proc_restore_buf_loop:
	mov dl, 0
	mov byte [rsi], dl
	inc rsi
	loop .proc_restore_buf_loop
	ret


proc_atoi:
	mov r8, 1       ; store the multiplier
	xor r10, r10    ; store the length
	xor rax, rax
	xor rbx, rbx
	lea rsi, [buf]
	mov rcx, max_buf_len
	sub rcx, 1
	mov dl, [rsi]
	cmp dl, '-'
	jne .proc_atoi_loop
	mov r8, -1
	inc rsi

.proc_atoi_loop:
	xor rdx, rdx
	mov dl, [rsi]
	cmp dl, 10
	je proc_atoi_before_exit
	cmp dl, 48
	jl proc_atoi_fail
	cmp dl, 57 
	jg proc_atoi_fail
	sub dl, 48
	imul rax, 10
	add rax, rdx 
	inc r10
	inc rsi
	loop .proc_atoi_loop
	jmp proc_atoi_exit

proc_atoi_fail:
	mov rbx, 1
	jmp proc_atoi_exit

proc_atoi_before_exit:
	cmp r10, 0
	jne proc_atoi_exit
	mov rbx, 1

proc_atoi_exit:
	imul rax, r8
	ret


proc_cal_sum:
	mov qword [array_i], 0

.proc_cal_sum_loop:
	mov rcx, el_size 
	imul rcx, qword [array_i]
	xor rdx, rdx
	mov rdx, qword [array+rcx] 
	add qword [array_sum], rdx
	add qword [array_i], 1
	cmp qword [array_i], el_count
	jl .proc_cal_sum_loop
	ret


section .note.GNU-stack
