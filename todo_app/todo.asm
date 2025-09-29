section .data
	O_WRONLY                          equ 0o001
	O_RDONLY                          equ 0o000
	O_CREAT                           equ 0o100
	O_TRUNC                           equ 0o1000

	storage_filename                  db "data.txt", 0
	settings_filename                 db "settings.txt", 0

	MAX_TODO_COUNT                    equ 25000
	todo_ids                          TIMES MAX_TODO_COUNT dq 0
	todo_content_max_length           equ 255
	todo_contents                     TIMES MAX_TODO_COUNT db "                                                                                                                                                                                                                                                               " ; this inner length in 255 
	todo_statuses                     TIMES MAX_TODO_COUNT dq 0
	todo_count                        dq 0

	extra_buffer                      db 0
	temp_todo_id_buffer_len           equ 8
	temp_todo_id_buffer               TIMES temp_todo_id_buffer_len db 0
	temp_todo_status_buffer           db 0, 0 
	temp_todo_content_buffer          TIMES todo_content_max_length db 0
	settings_file_fd                  dq 8
	settings_file_content_len         equ 10
	settings_file_content             TIMES settings_file_content_len db 0
	storage_file_fd                   dq 0
	storage_file_content_len          equ 50000
	storage_file_read_content_len     dq 0 
	storage_file_content              TIMES storage_file_content_len db 0
	todo_count_ascii_len              equ 10
	todo_count_ascii                  times todo_count_ascii_len db 0
	user_selected_option              db 0
	user_selected_option_len          equ 1 
	todo_id_ascii                     TIMES 10 db 0 
	todo_id_ascii_len                 equ $-todo_id_ascii
	todo_status_ascii                 TIMES 10 db 0 
	todo_status_ascii_len             equ $-todo_status_ascii

	newline_msg                       db 10, 0
	newline_msg_len                   equ $-newline_msg
	menu_msg                          db 10, "-------------------------------", 10, "### TODO APP ###", 10, "-------------------------------", 10, 10, "OPTIONS >", 10, "1. list tasks", 10, "2. add tasks", 10, "3. update task", 10, "4. delete task", 10, "5. exit", 10, 10, 0
	menu_msg_len                      equ $-menu_msg
	prompt_msg                        db "> ", 0
	prompt_msg_len                    equ $-prompt_msg
	bye_msg                           db "Bye...", 10
	bye_msg_len                       equ $-bye_msg 
	invalid_main_option_msg           db "Invalid option...", 10
	invalid_main_option_msg_len       equ $-invalid_main_option_msg
	todo_list_welcome_msg             db "-------------------------------", 10, "### TODO LIST ###", 10
	todo_list_welcome_msg_len         db $-todo_list_welcome_msg 
	todo_list_id_msg                  db "-------------------------------", 10, "id: ", 0
	todo_list_id_msg_len              equ $-todo_list_id_msg 
	todo_list_content_msg             db "content: ", 0
	todo_list_content_msg_len         equ $-todo_list_content_msg 
	todo_list_status_msg              db "status: ", 0
	todo_list_status_msg_len          equ $-todo_list_status_msg

	invalid_todo_count_fmt          db "invalid last id: %s", 0
	debug_print_todo_count          db "current todo id: %ld", 10, 0


section .text
	global main
	extern printf


main:
	call proc_load_settings
	cmp rbx, 1
	je todo_last_id_fail

	call proc_update_settings
	call proc_load_todos

main_loop:
	; print the welcome msg
	lea rdi, [menu_msg]
	mov rsi, menu_msg_len
	call proc_print_msg

	; read the user input
	mov rdi, prompt_msg
	mov rsi, prompt_msg_len 
	mov rdx, user_selected_option
	mov rcx, user_selected_option_len
	call proc_read_input
	call proc_load_main_option
	jmp main_loop

todo_last_id_fail:
	push rbp
	mov rbp, rsp
	lea rdi, [invalid_todo_count_fmt]
	lea rsi, [settings_file_content]
	call printf
	mov rsp, rbp
	pop rbp

fail_exit:
	mov rax, 0x3c
	mov rdi, 1
	syscall

success_exit:
	; print the bye msg
	mov rdi, bye_msg
	mov rsi, bye_msg_len
	call proc_print_msg

	mov rax, 0x3c
	mov rdi, 0
	syscall


proc_list_todos:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	mov qword [rbp-0x8] , todo_ids
	mov qword [rbp-0x10], todo_contents
	mov qword [rbp-0x18], todo_statuses 
	mov qword [rbp-0x20], 0 

	mov rax, 1
	mov rdi, 1
	mov rsi, todo_list_welcome_msg
	mov rdx, todo_list_welcome_msg_len
	syscall

proc_list_todos_loop:
	mov rcx, [rbp-0x20]
	cmp rcx, [todo_count]
	jge proc_list_todos_exit

	mov rax, 1
	mov rdi, 1
	mov rsi, todo_list_id_msg
	mov rdx, todo_list_id_msg_len
	syscall

	mov rbx, qword [rbp-0x8]
	mov rdi, [rbx]
	mov rsi, todo_id_ascii
	mov rdx, todo_id_ascii_len
	call proc_itoa

	mov rdi, todo_id_ascii
	mov rsi, todo_id_ascii_len
	call proc_get_ascii_length

	mov rdx, rax
	mov rax, 1
	mov rdi, 1
	mov rsi, todo_id_ascii 
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, newline_msg
	mov rdx, newline_msg_len
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, todo_list_content_msg
	mov rdx, todo_list_content_msg_len
	syscall

	mov rbx, qword [rbp-0x8]
	add rbx, 8
	mov qword [rbp-0x8], rbx

	mov rbx, [rbp-0x10]
	mov rax, 1
	mov rdi, 1
	mov rsi, rbx
	mov rdx, todo_content_max_length
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, newline_msg
	mov rdx, newline_msg_len
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, todo_list_status_msg
	mov rdx, todo_list_status_msg_len
	syscall

	add rbx, todo_content_max_length
	mov qword [rbp-0x10], rbx

	mov rax, 1
	mov rdi, 1
	mov rsi, todo_list_status_msg
	mov rdi, todo_list_status_msg_len
	syscall

	mov rbx, qword [rbp-0x18]
	mov rdi, [rbx]
	mov rsi, todo_status_ascii 
	mov rdx, todo_status_ascii_len
	call proc_itoa

	mov rax, 1
	mov rdi, 1
	mov rsi, todo_status_ascii 
	mov rdx, 1
	syscall

	mov rbx, qword [rbp-0x18]
	add rbx, 8
	mov qword [rbp-0x18], rbx

	mov rax, 1
	mov rdi, 1
	mov rsi, newline_msg
	mov rdx, newline_msg_len
	syscall

	mov rcx, qword [rbp-0x20]
	inc rcx
	mov qword [rbp-0x20], rcx 

	jmp proc_list_todos_loop

proc_list_todos_exit:
	mov rsp, rbp
	pop rbp
	ret


proc_load_todos:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20 
	mov qword [rbp-0x8], todo_ids 
	mov qword [rbp-0x10], todo_contents 
	mov qword [rbp-0x18], todo_statuses 
	mov qword [rbp-0x20], 0 

	; open the file
	mov rax, 2
	mov rdi, storage_filename 
	mov rsi, O_RDONLY  
	mov rdx, 0o644
	syscall

	; store the file descriptor 
	mov [storage_file_fd], rax

	; read the data 
	mov rax, 0
	mov rdi, [storage_file_fd]
	mov rsi, storage_file_content 
	mov rdx, storage_file_content_len
	syscall

	mov [storage_file_read_content_len], rax

	mov rsi, storage_file_content
	mov rcx, [storage_file_read_content_len]

proc_load_todos_main_loop:
	mov rcx, qword [rbp-0x20]
	cmp rcx, [todo_count]
	jge proc_load_todos_exit
	push rsi

	; reset buffers
	mov rdi, temp_todo_id_buffer
	mov rsi, temp_todo_id_buffer_len
	call proc_reset_buffer

	mov rdi, temp_todo_content_buffer
	mov rsi, todo_content_max_length
	call proc_reset_buffer

	mov rdi, temp_todo_status_buffer
	mov rsi, 1
	call proc_reset_buffer

	pop rsi
	; first read id
proc_load_todos_read_id:
	mov rbx, temp_todo_id_buffer
proc_load_todos_read_id_loop:
	dec rcx
	mov dl, [rsi]
	cmp dl, '|'
	je proc_load_todos_read_content
	mov byte [rbx], dl
	inc rbx
	inc rsi
	jmp proc_load_todos_read_id_loop

	; then read content
proc_load_todos_read_content:
	inc rsi
	mov rbx, temp_todo_content_buffer
proc_load_todos_read_content_loop:
	dec rcx
	mov dl, byte [rsi]
	cmp dl, '|'
	je proc_load_todos_read_status
	mov byte [rbx], dl
	inc rbx
	inc rsi
	jmp proc_load_todos_read_content_loop

proc_load_todos_read_status:
	inc rsi
	mov rbx, temp_todo_status_buffer
proc_load_todos_read_status_loop:
	dec rcx
	mov dl, byte [rsi]
	cmp dl, '|'
	je proc_load_todos_before_loop
	cmp dl, 10
	je proc_load_todos_before_loop
	mov byte [rbx], dl
	inc rbx
	inc rsi
	jmp proc_load_todos_read_status_loop

proc_load_todos_before_loop:
	inc rsi
	push rsi

	mov rdi, temp_todo_id_buffer
	mov rsi, temp_todo_id_buffer_len
	call proc_atoi

	mov rdi, qword [rbp-0x8] ; todo_ids 
	mov qword [rdi], rax
	add rdi, 8               ; size of the qword pointer
	mov qword [rbp-0x8], rdi

	mov rdi, temp_todo_status_buffer
	mov rsi, 1
	call proc_atoi

	mov rdi, qword [rbp-0x18] ; todo_statuses
	mov qword [rdi], rax
	add rdi, 8
	mov qword [rbp-0x18], rdi

	mov rdi, qword [rbp-0x10] ; todo_contents
	mov rsi, temp_todo_content_buffer
	mov rcx, todo_content_max_length

.proc_load_todos_fill_todo_contents_loop:
	mov dl, byte [rsi]
	mov byte [rdi], dl
	inc rdi
	inc rsi
	loop .proc_load_todos_fill_todo_contents_loop
	
	mov qword [rbp-0x10], rdi

	pop rsi

	mov rcx, qword [rbp-0x20]
	inc rcx
	mov qword [rbp-0x20], rcx

	jmp proc_load_todos_main_loop

proc_load_todos_exit:
	; close the file
	mov rax, 3
	mov rdi, [storage_file_fd]
	syscall

	mov rsp, rbp
	pop rbp
	ret


proc_reset_buffer:
	push rcx
	; rdi - buffer address
	; rsi - buffer address length
	mov rcx, rsi
	mov rsi, rdi
	dec rcx
	cmp rcx, 0
	jne .proc_reset_buffer
	mov byte [rsi], 0
	jmp proc_reset_buffer_exit

.proc_reset_buffer:
	mov byte [rsi], 0
	inc rsi
	loop .proc_reset_buffer

proc_reset_buffer_exit:
	pop rcx
	ret


proc_load_main_option:
	mov dl, [user_selected_option]
	cmp dl, "1"
	jne proc_load_main_option_two
	call proc_list_todos
proc_load_main_option_one:
	; option one
	jmp proc_load_main_option_exit
proc_load_main_option_two:
	cmp dl, "2"
	jne proc_load_main_option_three
	; option two 
	jmp proc_load_main_option_exit
proc_load_main_option_three:
	cmp dl, "3"
	jne proc_load_main_option_four
	; option three
	jmp proc_load_main_option_exit
proc_load_main_option_four:
	cmp dl, "4"
	jne proc_load_main_option_five
	; option four 
	jmp proc_load_main_option_exit
proc_load_main_option_five:
	cmp dl, "5"
	jne proc_load_main_option_fail
	; option five 
	jmp success_exit
proc_load_main_option_fail:
	mov rdi, invalid_main_option_msg
	mov rsi, invalid_main_option_msg_len
	call proc_print_msg
proc_load_main_option_exit:
	ret


proc_get_ascii_length:
	; rdi - buffer
	; rsi - max buffer length
	xor rax, rax
	mov rcx, rsi
	mov rsi, rdi 

.proc_get_ascii_length_loop:
	mov dl, byte [rsi]
	cmp dl, 0
	je proc_get_ascii_length_exit
	inc rax
	inc rsi
	loop .proc_get_ascii_length_loop

proc_get_ascii_length_exit:
	ret


proc_get_number_length:
	; rdi - number value
	mov rbx, 1
	mov rax, rdi
	mov rdi, 10
	cmp rax, 0
	jge proc_get_number_length_loop
	imul rax, -1

proc_get_number_length_loop:
	cdq
	div rdi 
	cmp rax, 0
	je proc_get_number_length_exit
	inc rbx
	jmp proc_get_number_length_loop

proc_get_number_length_exit:
	mov rax, rbx 
	ret


proc_itoa:
	; rdi - number
	; rsi - dst buffer
	; rdx - dst buffer length
	mov rax, rdi
	push rax
	push rsi
	push rdx
	call proc_get_number_length
	mov r8, rax
	pop rdx
	pop rsi
	pop rax

	mov rcx, r8 
	cmp rax, 0
	jge proc_itoa_before_loop_to_end_buffer
	imul rax, -1 
	mov byte [rsi], '-'
	inc rsi

proc_itoa_before_loop_to_end_buffer:
	dec rcx
	cmp rcx, 0
	je proc_itoa_before_loop

.proc_itoa_loop_to_end_buffer:
	inc rsi
	loop .proc_itoa_loop_to_end_buffer

proc_itoa_before_loop:
	mov rcx, r8

.proc_itoa_loop:
	cdq
	mov rdi, 10
	idiv rdi
	add rdx, 48
	mov byte [rsi], dl
	dec rsi
	loop .proc_itoa_loop
	inc rsi
	ret


proc_update_settings:
	; open the file
	mov rax, 2
	lea rdi, [settings_filename]
	mov rsi, O_WRONLY 
	mov rdx, 0o644
	syscall

	mov [settings_file_fd], rax

	mov rdi, todo_count
	mov rsi, todo_count_ascii
	mov rdx, todo_count_ascii_len
	call proc_itoa

	mov rdi, todo_count
	call proc_get_number_length
	mov rdx, rax
	mov rdi, todo_count
	cmp rdi, 0
	jge proc_update_settings_before_save
	inc rdx

proc_update_settings_before_save:
	; write to the file
	mov rax, 1
	mov rdi, [settings_file_fd]
	mov rsi, [todo_count_ascii]
	syscall

	; close the file
	mov rax, 3
	mov rdi, [settings_file_fd]
	syscall

	ret


proc_load_settings:
	; open the file 
	mov rax, 2
	lea rdi, [settings_filename]
	mov rsi, O_RDONLY 
	mov rdx, 0 
	syscall

	; save the file descriptor
	mov [settings_file_fd], rax

	; read the content of the file
	mov rdi, rax
	mov rax, 0
	lea rsi, [settings_file_content] 
	mov rdx, settings_file_content_len 
	syscall

	lea rdi, [settings_file_content]
	mov rsi, settings_file_content_len
	call proc_atoi
	cmp rbx, 1
	je proc_load_settings_fail
	mov [todo_count], rax

	xor rbx, rbx
	jmp proc_load_settings_exit

proc_load_settings_fail:
	mov rbx, 1

proc_load_settings_exit:
	mov rax, 3
	mov rdi, settings_file_fd
	syscall
	ret


proc_print_msg:
	; rdi - msg address
	; rsi - msg length
	mov rdx, rsi
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1
	syscall
	ret


proc_atoi:
	; rdi - buf address
	; rsi - buf length
	xor rax, rax
	xor rbx, rbx
	mov rcx, rsi
	mov rsi, rdi

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
	jmp proc_atoi_exit

proc_atoi_fail:
	mov rbx, 1

proc_atoi_exit:
	ret


proc_read_input:
	; rdi - prompt msg address
	; rsi - prompt msg length 
	; rdx - buffer address
	; rcx - buffer length
	push rdx
	push rcx
	call proc_print_msg
	pop rcx
	pop rdx

	mov rax, 0
	mov rdi, 0
	mov rsi, rdx
	mov rdx, rcx
	syscall

	mov rdi, rsi
	mov rsi, rdx
	call proc_find_newline
	cmp rax, 1
	je proc_read_input_exit
	call proc_read_extra_buffer

proc_read_input_exit:
	ret


proc_read_extra_buffer:
	; rdi - max buffer length
	mov rcx, rdi

.proc_read_extra_buffer_loop:
	mov rax, 0
	mov rdi, 0
	lea rsi, [extra_buffer]
	mov rdx, 1
	syscall
	
	mov dl, [extra_buffer]
	cmp dl, 10
	je proc_read_extra_buffer_exit
	loop .proc_read_extra_buffer_loop

proc_read_extra_buffer_exit:
	ret


proc_find_newline:
	; rdi - buffer address
	; rsi - buffer length
	xor rax, rax
	mov rcx, rsi
	mov rsi, rdi

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


section .note.GNU-stack
