#
# see ./Makefile for instructions on how to compile the code.
# see ./opf.txt for documentation.
#
	opf_C_default_size   = 4096
	opf_H_default_size   = 4096
	opf_S_default_size   = 4096
	opf_Q_size	     = 4
	opf_in_fd_block_size = 256

	opf_cell_size = 8
	opf_char_size = 1
	opf_bits_per_char = 8
	opf_pad_size  = opf_cell_size*opf_bits_per_char
	opf_syscall = 0x80
	opf_syscall_exit =  0x01
	opf_syscall_read =  0x03
	opf_syscall_write = 0x04
	opf_syscall_open =  0x05
	opf_syscall_close = 0x06
	opf_syscall_mmap =  0x5A
	opf_exit_success = 0x0
	opf_exit_failure = 0x1

	opf_mmap_prot_none =	 0x00
	opf_mmap_prot_read =	 0x01
	opf_mmap_prot_write =	 0x02
	opf_mmap_prot_exec =	 0x04
	opf_mmap_map_shared =	 0x01
	opf_mmap_map_private =	 0x02
	opf_mmap_map_fixed =	 0x10
	opf_mmap_map_anonymous = 0x20

	opf_stdin =  0
	opf_stdout = 1
	opf_stderr = 2

	opf_h_len    =	      0
	opf_h_next   =	      opf_h_len	 + opf_char_size
	opf_h_code   =	      opf_h_next + opf_cell_size
	opf_h_comp   =	      opf_h_code + opf_cell_size
	opf_h__size  =	      opf_h_comp + opf_cell_size
	opf_h_inline =	      opf_h__size
	opf_h_add_sub_table = opf_h_inline + opf_char_size

	opf_opcode_addb_rax =	0xC08348
	opf_opcode_addl_rax =	0x0548
	opf_opcode_call =	0xE8
	opf_opcode_dec_rax =    0xC8FF48
	opf_opcode_inc_rax =    0xC0FF48
	opf_opcode_jg =		0x7F
	opf_opcode_jge =	    0x7D
	opf_opcode_jl =		    0x7C
	opf_opcode_jle =	    0x7E
	opf_opcode_jmp =	    0xE9
	opf_opcode_jne =	    0x75
	opf_opcode_jz =		    0x74
	opf_opcode_ret =	    0xC3
	opf_opcode_subb_rax =	0xE88348
	opf_opcode_subl_rax =	0x2d48

	opf_call_size = 5

	opf_add_sub_one = 0
	opf_add_subb = 4
	opf_add_subl = 8

	opf_add_subb_delta = 3
	opf_add_subl_delta = 2

	opf_add_subb_size =  4
	opf_add_subl_size =  6

	opf_lif_cond_code_addr = 0
	opf_lif_cond_opcode =	 opf_cell_size
	opf_lif_cond__size =	 opf_cell_size+opf_char_size

	opf_in_refill	 = 0
	opf_in_name	 = opf_in_refill    + opf_cell_size
	opf_in_p	 = opf_in_name	    + opf_cell_size
	opf_in_s	 = opf_in_p	    + opf_cell_size
	opf_in_e	 = opf_in_s	    + opf_cell_size
	opf_in__size	 = opf_in_e	    + opf_cell_size

	opf_in_fd_fd	= opf_in__size
	opf_in_fd_bs	= opf_in_fd_fd + opf_cell_size
	opf_in_fd__size = opf_in_fd_bs + opf_cell_size

	opf_q_head  = 0
	opf_q_code  = opf_q_head + opf_cell_size
	opf_q__size = opf_q_code + opf_cell_size
	opf_q_mask  = ((1<<(opf_Q_size+1))-1)

	opf_q_head_drop_lit = 3
	opf_q_head_lit = 2
	opf_q_head_max = 0x10000

	opf_error_eoi =	     1
	opf_error_bad_word = 2

opf_argc:			.space opf_cell_size
opf_argv:			.space opf_cell_size
opf_B:				.long 16
opf_C:				.space opf_cell_size
opf_C_size:			.long opf_C_default_size
opf_H:				.space opf_cell_size
opf_H_size:			.long opf_H_default_size
opf_S:				.space opf_cell_size
opf_S_size:			.long opf_S_default_size
opf_D:				.long opf_D_top
opf_I:				.space opf_cell_size
opf_X:				.long opf_compile_call
opf_L:				.space opf_cell_size
opf_Q:				.long 0, 0
				.long 0, 0
				.long 0, 0
				.long 0, opf_vars_code
opf_Qi:				.long opf_q__size*(opf_Q_size-1)
opf_defined_vector:		.long opf_defined_interpret
opf_undefined_vector:		.long opf_number_interpret
opf_number_vector:		.long opf_atou
opf_not_number_vector:		.long opf_bad_word_abort
opf_abort_vector:		.long opf_abort_default
opf_defined_vector_cache:	.long opf_defined_compile
				.long opf_number_compile
opf_word_fail_msg:		.ascii " ?\n"


	.global _start
_start: 
	pop	%rax
	mov	%rax, opf_argc
	mov	%rsp, opf_argv
	mov	%rsp, %rbx
	push	$0
	mov	%rsp, opf_L
opf_cmd_line_next:
	add	$opf_cell_size, %rbx
	dec	%rax
	jz	opf_cmd_line_input_from_stdin
	mov	(%rbx), %rsi
	cmpb	$'-', (%rsi)
	jne	opf_cmd_line_input_from_file
	mov	$2, %rcx
opf_cmd_line_base:
	cmpb	$'b', opf_char_size(%rsi)
	jne	opf_cmd_line_code_size
	lea	opf_B, %rdx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_code_size:
	cmpb	$'c', opf_char_size(%rsi)
	jne	opf_cmd_line_header_size
	lea	opf_C_size, %rdx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_header_size:
	cmpb	$'h', opf_char_size(%rsi)
	jne	opf_cmd_line_param_size
	lea	opf_H_size, %rdx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_param_size:
	cmpb	$'s', opf_char_size(%rsi)
	jne	opf_cmd_line_lib
	lea	opf_S_size, %rdx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_lib:
	cmpb	$'l', opf_char_size(%rsi)
	jne	opf_cmd_line_end
	add	$(2*opf_char_size), %rsi
	mov	%rsi, (%rsp)
	push	$0
	jmp	opf_cmd_line_next
opf_cmd_line_end:
	cmpw	$0x002D, opf_char_size(%rsi)
	jne	opf_bad_word_abort
	# vvvvv fall through vvvvv

opf_cmd_line_input_from_stdin:
	call	opf_cmd_line_setup_args
	mov	$opf_stdin, %rax
	call	opf_input_from_fd_code
	jmp	opf_exit


opf_cmd_line_input_from_file:
	mov	opf_argv, %rcx
	mov	%rbx, opf_argv
	sub	%rcx, %rbx
	shr	$2, %rbx
	sub	%rbx, opf_argc
	call	opf_cmd_line_setup_args
	mov	%rsi, %rbx
	call	opf_boot_from_file
	# vvvv fall through vvvv

opf_exit:
	mov	$opf_syscall_exit, %rax
	mov	$opf_exit_success, %rbx
	int	$opf_syscall


opf_cmd_line_parse_int:
	push	%rdx
	xor	%rcx, %rcx
	dec	%rcx
	push	%rsi
	add	$(2*opf_char_size), %rsi
	push	%rbx
	call	opf_atou
	pop	%rbx
	pop	%rsi
	pop	%rdx
	mov	%rdi, (%rdx)
	test	%rcx, %rcx
	jz	opf_cmd_line_next
	neg	%rcx
	add	$(2*opf_char_size), %rcx
	jmp	opf_bad_word_abort


opf_cmd_line_setup_args:
	lea	opf_C, %rcx
	call	opf_anon_mmap
	lea	opf_H, %rcx
	call	opf_anon_mmap
	lea	opf_S, %rcx
	call	opf_anon_mmap
	mov	opf_S_size, %rbp
	add	%rax, %rbp
	ret


opf_text_interpreter:
	call	opf_in_wsw
	test	%rcx, %rcx
	jle	opf_text_interpreter_end
	lea	opf_defined_vector, %rbx
	call	opf_dict_find	
	call	*(%rbx)
	jmp	opf_text_interpreter
opf_text_interpreter_end:
	ret


opf_defined_interpret:
	jmp	*opf_h_code(%rdx)


opf_defined_compile:
	jmp	*opf_h_comp(%rdx)


opf_number_convert:
	push	%rcx
	push	%rsi
	mov	opf_number_vector, %rbx
	call	*%rbx
	pop	%rsi
	test	%rcx, %rcx
	jne	opf_number_convert_fail
	pop	%rcx
	ret
opf_number_convert_fail:
	mov	opf_not_number_vector, %rbx
	pop	%rcx
	jmp	*%rbx


opf_bad_word_abort:
	mov	%rcx, %rdx
	mov	%rsi, %rcx
	mov	$opf_stderr, %rbx
	mov	$opf_syscall_write, %rax
	int	$opf_syscall
	mov	$3, %rdx
	lea	opf_word_fail_msg, %rcx
	mov	$opf_syscall_write, %rax
	int	$opf_syscall
	mov	$opf_error_bad_word, %rax
	jmp	opf_abort


opf_number_interpret:
	call	opf_number_convert
	mov	%rax, -opf_cell_size(%rbp)
	sub	$opf_cell_size, %rbp
	mov	%rdi, %rax
	ret	

opf_number_compile:
	call	opf_number_convert
	# vvvv fall through vvvvv

opf_number_plant_literal:
	mov	opf_Qi, %rbx
	lea	opf_Q, %rcx
	add	%rbx, %rcx
	mov	opf_q_head(%rcx), %rbx
	cmp	$opf_drop_head, %rbx
	je	opf_number_plant_literal_after_drop
	mov	opf_C, %rbx
	movl	$0xF8458948, (%rbx)
	movw	$0xb848, 4(%rbx)
	mov	%rdi, 6(%rbx)
	movl	$0x08ED8348, (%rbx)
	mov	$opf_q_head_lit, %rdx
	mov	%rbx, %rdi
	call	opf_Q_add
	add	$(4+10+4), %rbx
	mov	%rbx, opf_C
	ret

opf_number_plant_literal_after_drop:
	mov	opf_q_code(%rcx), %rbx
	movb	$0xB8, (%rbx)
	mov	%rdi, opf_char_size(%rbx)
	add	$(opf_char_size+opf_cell_size), %rbx
	movl	$opf_q_head_drop_lit, opf_q_head(%rcx)
	mov	%rbx, opf_C
	ret


opf_compile_call:
	mov	opf_C, %rdi
	call	opf_Q_add
	movb	$opf_opcode_call, (%rdi)
	add	$(opf_call_size), %rdi
	mov	opf_h_code(%rdx), %rbx
	sub	%rdi, %rbx
	mov	%rdi, opf_C
	mov	%rbx, -opf_cell_size(%rdi)
	ret

opf_compile_inline:
	mov	opf_C, %rdi
	call	opf_Q_add
	xor	%rcx, %rcx
	mov	opf_h_code(%rdx), %rsi
	movb	opf_h_inline(%rdx), %cl
	rep
	movsb
	mov	%rdi, opf_C
	ret


opf_Q_add:
	mov	opf_Qi, %rsi
	lea	opf_Q, %rcx
	add	$opf_q__size, %rsi
	and	$opf_q_mask, %rsi
	mov	%rdx, opf_q_head(%rcx, %rsi)
	mov	%rdi, opf_q_code(%rcx, %rsi)
	mov	%rsi, opf_Qi
	ret


opf_abort:
	mov	opf_abort_vector, %rbx
	jmp	*%rbx


opf_abort_default:
	mov	%rax, %rbx
	mov	$opf_syscall_exit, %rax
	int	$opf_syscall


opf_in_wsw:	
	mov	opf_H, %rdi
	mov	opf_I, %rbx
	push	%rdi
opf_in_wsw_restart:
	mov	opf_in_p(%rbx), %rsi
opf_in_wsw_find_start:
	movb	(%rsi), %cl
	inc	%rsi
	cmpb	$' ', %cl
	je	opf_in_wsw_find_start
	cmpb	$'\n', %cl
	je	opf_in_wsw_nl_in_ws
opf_in_wsw_found_start: 
	movb	%cl, (%rdi)
	inc	%rdi
opf_in_wsw_next_word_char:
	movb	(%rsi), %cl
	inc	%rsi
	cmpb	$'\n', %cl
	je	opf_in_wsw_nl_in_word
	cmpb	$' ', %cl
	jne	opf_in_wsw_found_start
opf_in_wsw_found_end:
	mov	%rsi, opf_in_p(%rbx)
	pop	%rsi
	mov	%rdi, %rcx
	sub	%rsi, %rcx
	ret
opf_in_wsw_nl_in_ws:
	cmp	%rsi, opf_in_e(%rbx)
	jne	opf_in_wsw_find_start
	call	*opf_in_refill(%rbx)
	test	%rdx, %rdx
	jg	opf_in_wsw_restart
	pop	%rdi
	mov	%rdx, %rcx
	ret
opf_in_wsw_nl_in_word:
	cmp	%rsi, opf_in_e(%rbx)
	jne	opf_in_wsw_nl_in_word_end
	call	*opf_in_refill(%rbx)
	mov	opf_in_p(%rbx), %rsi
	test	%rdx, %rdx
	jg	opf_in_wsw_next_word_char
	pop	%rdi
	mov	%rdx, %rcx
	ret
opf_in_wsw_nl_in_word_end:
	dec	%rsi
	jmp	opf_in_wsw_found_end


opf_in_fd_refill:
	push	%rax
	mov	opf_in_s(%rbx), %rcx
	mov	%rcx, opf_in_p(%rbx)
	mov	opf_in_fd_bs(%rbx), %rdx
	push	%rbx
	mov	opf_in_fd_fd(%rbx), %rbx
	mov	$opf_syscall_read, %rax
	int	$opf_syscall
	pop	%rbx
	mov	%rax, %rdx
	test	%rax, %rax
	jle	opf_in_fd_refill_end
	add	%rax, %rcx
	movb	$'\n', (%rcx)
	inc	%rcx
	mov	%rcx, opf_in_e(%rbx)
opf_in_fd_refill_end:
	pop	%rax
	ret


opf_in_skip:
	mov	opf_I, %rbx
opf_in_skip_again:
	mov	opf_in_p(%rbx), %rsi
opf_in_skip_next:
	movb	(%rsi), %dl
	inc	%rsi
	cmpb	$'\n', %dl
	je	opf_in_skip_nl
opf_in_skip_check_char:
	cmpb	%cl, %dl
	jne	opf_in_skip_next
opf_in_skip_found:
	mov	%rsi, opf_in_p(%rbx)	
	ret
opf_in_skip_nl:
	cmp	%rsi, opf_in_e(%rbx)
	jne	opf_in_skip_check_char
	push	%rcx
	call	*opf_in_refill(%rbx)
	pop	%rcx
	test	%rdx, %rdx
	jg	opf_in_skip_again
	ret


opf_atou:
	push	%rax
	xor	%rdi, %rdi
	mov	opf_B, %rbx
opf_atou_loop:
	lodsb
	testb	%al, %al
	jz	opf_atou_nul
	subb	$'0', %al
	jl	opf_atou_not_digit
	cmpb	$('9'-'0'+1), %al
	jl	opf_atou_digit
	subb	$7, %al		      # map 'A' .. 'F' down to 10 .. 15
	jl	opf_atou_not_digit
	cmpb	$16, %al
	jl	opf_atou_digit
	subb	$32, %al	      # map 'a' .. 'f' down to 10 .. 15
	jl	opf_atou_not_digit
	cmpb	$16, %al
	jge	opf_atou_not_digit
opf_atou_digit:
	cbw
	cwde
	cmp	%rbx, %rax
	jge	opf_atou_not_digit
	xchg	%rdi, %rax			 # slow instruction!
	mul	%rbx
	add	%rax, %rdi
	dec	%rcx
	jne	opf_atou_loop
opf_atou_nul:
	xor	%rcx, %rcx
opf_atou_not_digit:
	pop	%rax
	ret


opf_dict_find:
	mov	opf_D, %rdx   
	push	%rax
opf_dict_find_next:
	test	%rdx, %rdx
	je	opf_dict_find_fail
	cmpb	%cl, (%rdx)
	je	opf_dict_find_check_str
	mov	opf_h_next(%rdx), %rdx
	jmp	opf_dict_find_next
opf_dict_find_check_str:
	push	%rsi
	push	%rcx
	mov	%rdx, %rdi
	sub	%rcx, %rdi
	repe
	cmpsb
	je	opf_dict_find_found
	pop	%rcx
	pop	%rsi
	mov	opf_h_next(%rdx), %rdx
	jmp	opf_dict_find_next
opf_dict_find_found:
	pop	%rcx
	pop	%rdi		 # arbitrary register.
	pop	%rax
	ret
opf_dict_find_fail:
	xor	%rdx, %rdx
	add	$opf_cell_size, %rbx
	pop	%rax
	ret


opf_in_word_code:
	call	opf_in_wsw
	test	%rcx, %rcx
	jle	opf_abort
	mov	%rax, -opf_cell_size(%rbp)
	mov	%rsi, -(2*opf_cell_size)(%rbp)
	mov	%rcx, %rax
	sub	$(opf_cell_size*2), %rbp
	ret


opf_vars_code:
opf_debug_break:
	lea	opf_argc, %rbx
	lea	(%rbx, %rax, 4), %rax
	ret


opf_line_comment_code:
	movb	$'\n', %cl
	jmp	opf_in_skip


opf_dict_store_word_code:
	mov	opf_C, %rdi
	stosl
	mov	(%rbp), %rax
	mov	%rdi, opf_C
	add	$opf_cell_size, %rbp
	ret

	opf_input_stack_adjust = opf_in_fd__size+opf_in_fd_block_size+1

opf_input_from_fd_code:
	xor	%rbx, %rbx		# null file-name
opf_input_from_fd:
	push	%rax
	push	opf_I
	lea	-opf_in_fd__size(%rsp), %rdi
	mov	%rdi, opf_I
	lea	-opf_input_stack_adjust(%rsp), %rcx
	lea	opf_in_fd_refill, %rax
	mov	%rax, opf_in_refill(%rdi)
	mov	%rbx, opf_in_name(%rdi)
	mov	%rcx, %rax
	mov	%rax, opf_in_p(%rdi)
	mov	%rax, opf_in_s(%rdi)
	movb	$'\n', (%rax)
	inc	%rax
	mov	%rax, opf_in_e(%rdi)
	mov	4(%rsp), %rax		# opf_in_fd_fd
	movl	$opf_in_fd_block_size, opf_in_fd_bs(%rdi)
	mov	%rax, opf_in_fd_fd(%rdi)
	mov	%rcx, %rsp
	call	opf_text_interpreter
	add	$opf_input_stack_adjust, %rsp
	pop	opf_I
	pop	%rax
	ret


opf_input_from_file_code:
	call	opf_in_wsw
	test	%rcx, %rcx
	jle	opf_abort
	movb	$0, (%rdi)
	mov	%rsi, %rbx
	# vvvv fall through vvvv

opf_boot_from_file:
	push	%rax
	push	%rbx
	cmpb	$'/', (%rbx)
	je	opf_boot_from_file_absolute
	mov	opf_L, %rcx
opf_boot_from_file_next:
	mov	(%rsp), %rbx
	mov	(%rcx), %rsi
	test	%rsi, %rsi
	je	opf_boot_from_file_not_found
	mov	opf_C, %rdi
	push	%rdi
	call	opf_strcpy
	movl	$'/', (%rdi)
	inc	%rdi
	mov	%rbx, %rsi
	call	opf_strcpy
	movb	$0, (%rdi)
	pop	%rbx
	push	%rcx
	xor	%rcx, %rcx
	mov	$opf_syscall_open, %rax
	int	$opf_syscall
	pop	%rcx
	test	%rax, %rax
	jg	opf_boot_from_file_eval
	sub	$opf_cell_size, %rcx
	jmp	opf_boot_from_file_next


opf_boot_from_file_absolute:
	xor	%rcx, %rcx
	mov	$opf_syscall_open, %rax
	int	$opf_syscall
	test	%rax, %rax
	jl	opf_boot_from_file_not_found
	# vvvv fall through vvvvv

opf_boot_from_file_eval:
	call	opf_input_from_fd
	mov	%rax, %rbx
	mov	$opf_syscall_close, %rax
	int	$opf_syscall
	add	$opf_cell_size, %rsp
	pop	%rax
	ret

opf_boot_from_file_not_found:
	add	$(2*opf_cell_size), %rsp
	mov	%rbx, %rsi
	call	opf_strlen
	mov	%rbx, %rsi
	jmp	opf_bad_word_abort


opf_strcpy:
	movb	(%rsi), %al
	testb	%al, %al
	jz	opf_strcpy_finished
	movb	%al, (%rdi)
	inc	%rsi
	inc	%rdi
	jmp	opf_strcpy
opf_strcpy_finished:
	ret


opf_strlen:
	xor	%rcx, %rcx
opf_strlen_next:
	cmpb	$0, (%rsi)
	je	opf_strlen_finished
	inc	%rcx
	inc	%rsi
	jmp	opf_strlen_next
opf_strlen_finished:
	ret


opf_double_code:
	shl	$1, %rax
opf_double_code_end:
	ret


opf_halve_code:
	shr	$1, %rax
opf_halve_code_end:
	ret


opf_dup_code:
	mov	%rax, -opf_cell_size(%rbp)
	sub	$opf_cell_size, %rbp
opf_dup_code_end:
	ret


opf_drop_code:
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
opf_drop_code_end:
	ret


opf_over_code:
	mov	%rax, -opf_cell_size(%rbp)
	mov	(%rbp), %rax
	sub	$opf_cell_size, %rbp
opf_over_code_end:
	ret


opf_nip_code:
	add	$opf_cell_size, %rbp
opf_nip_code_end:
	ret


opf_tuck_code:
	mov	(%rbp), %rbx
	mov	%rax, (%rbp)
	mov	%rbx, -opf_cell_size(%rbp)
	sub	$opf_cell_size, %rbp
opf_tuck_code_end:
	ret

opf_swap_code:
	xchg	(%rbp), %rax
opf_swap_code_end:
	ret


opf_push_code:
	push	%rax
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
opf_push_code_end:
	ret


opf_pop_code:
	mov	%rax, -opf_cell_size(%rbp)
	pop	%rax
	sub	$opf_cell_size, %rbp
opf_pop_code_end:
	ret


opf_sum_code:
	add	(%rbp), %rax
	add	$opf_cell_size, %rbp
opf_sum_code_end:
	ret


opf_sub_code:
	mov	(%rbp), %rbx
	sub	%rax, %rbx
	mov	%rbx, %rax
	add	$opf_cell_size, %rbp
opf_sub_code_end:
	ret


opf_compile_add_sub:
	mov	opf_Qi, %rbx
	lea	opf_Q, %rcx
	add	%rbx, %rcx
	mov	opf_q_head(%rcx), %rbx
	cmp	$opf_q_head_lit, %rbx
	jne	opf_compile_inline
	push	%rax
	mov	opf_q_code(%rcx), %rsi
	mov	opf_cell_size(%rsi), %rbx
	lea	opf_h_add_sub_table(%rdx), %rdi
	cmp	$0xFF, %rbx
	ja	opf_compile_add_subl
	cmp	$1, %rbx
	jne	opf_compile_add_subb
	movb	opf_add_sub_one(%rdi), %al
	movb	%al, (%rsi)
	inc	%rsi
	jmp	opf_compile_add_sub_adjust_q
opf_compile_add_subb:
	movl	opf_add_subb(%rdi), %eax
	movl	%eax, (%rsi)
	movb	%bl, opf_add_subb_delta(%rsi)
	add	$opf_add_subb_size, %rsi
	jmp	opf_compile_add_sub_adjust_q
opf_compile_add_subl:
	movw	opf_add_subl(%rdi), %ax
	movw	%ax, (%rsi)
	movl	%ebx, opf_add_subl_delta(%rsi)
	add	$opf_add_subl_size, %rsi
opf_compile_add_sub_adjust_q:
	xor	%rdx, %rdx
	mov	%rdx, opf_q_head(%rcx)
	mov	%rsi, opf_C
	pop	%rax
	ret


opf_eq_code:
	xor	(%rbp), %rax
	not	%rax
	je	opf_eq_code_end
	xor	%rax, %rax
opf_eq_code_end:
	add	$opf_cell_size, %rbp
	ret

opf_le_code:
	sub	(%rbp), %rax
	not	%rax
	shr	$31, %rax
	add	$opf_cell_size, %rbp
	ret

opf_gt_code:
	sub	(%rbp), %rax
	shr	$31, %rax
	add	$opf_cell_size, %rbp
opf_gt_code_end:
	ret


opf_and_code:
	and	(%rbp), %rax
	add	$opf_cell_size, %rbp
opf_and_code_end:
	ret


opf_or_code:
	or	(%rbp), %rax
	add	$opf_cell_size, %rbp
opf_or_code_end:
	ret


opf_xor_code:
	xor	(%rbp), %rax
	add	$opf_cell_size, %rbp
opf_xor_code_end:
	ret

opf_char_store_code:
	movb    (%rbp), %bl
	movb    %bl, (%rax)
	mov	opf_cell_size(%rbp), %rax
	add	$(2*opf_cell_size), %rbp
	ret

opf_char_fetch_code:
	xor	%rbx, %rbx
	movb    (%rax), %bl
	mov	%rbx, %rax
opf_char_fetch_code_end:
	ret
	
opf_store_code:
	mov	(%rbp), %rbx
	mov	%rbx, (%rax)
	mov	opf_cell_size(%rbp), %rax
	add	$(2*opf_cell_size), %rbp
	ret

opf_fetch_code:
	mov	(%rax), %rax
opf_fetch_code_end:
	ret


opf_swap_state_code:
	lea	opf_defined_vector, %rsi
	lea	opf_defined_vector_cache, %rdi
	fldl	(%rdi)
	fldl	(%rsi)
	fstpl	(%rdi)
	fstpl	(%rsi)
	ret


opf_return_code:
	mov	opf_Qi, %rbx
	lea	opf_Q, %rcx
	mov	opf_D, %rdx
	add	%rbx, %rcx
	mov	opf_q_code(%rcx), %rbx
	mov	opf_h_code(%rdx), %rsi
	cmpb	$opf_opcode_call, (%rbx)
	jne	opf_return_code_inline_or_ret
	cmp	%rbx, %rsi
	je	opf_return_code_alias
	movb	$opf_opcode_jmp, (%rbx)
	ret
opf_return_code_inline_or_ret:
	mov	opf_C, %rdi
	cmp	%rbx, %rsi
	je	opf_return_code_inline
opf_return_code_ret:
	lea	opf_return_head, %rdx
	movb	$opf_opcode_ret, (%rdi)
	call	opf_Q_add
	inc	%rdi
	mov	%rdi, opf_C
	ret
opf_return_code_inline:
	mov	%rdi, %rbx	  
	sub	%rsi, %rbx
	mov	%rbx, opf_h_inline(%rdx)
	mov	opf_q_head(%rcx), %rbx
	lea	opf_compile_inline, %rsi
	incl	opf_H
	mov	%rsi, opf_h_comp(%rdx)
	cmp	$opf_q_head_max, %rbx
	jl	opf_return_code_ret
opf_return_code_inline_alias:
	mov	opf_h_code(%rdx), %rsi
	mov	opf_h_code(%rbx), %rdi
	mov	%rsi, opf_C
	mov	%rdi, opf_h_code(%rdx)
opf_Q_remove:
	mov	opf_Qi, %rbx
	sub	$opf_q__size, %rbx
	and	$opf_q_mask, %rbx
	mov	%rbx, opf_Qi	    
	ret
opf_return_code_alias:
	mov	-opf_cell_size(%rdi), %rcx
	add	%rdi, %rcx		# possibly replace with 
	sub	$opf_call_size, %rdi	# lea -opf_call_size(%rdi,%rcx), %rcx
	mov	%rcx, opf_h_code(%rdx)
	mov	%rdi, opf_C
	jmp	opf_Q_remove


opf_def_code:
	call	opf_in_wsw
	test	%rcx, %rcx
	jle	opf_abort
	mov	opf_D, %rbx
	mov	%rdi, opf_D
	movb	%cl, (%rdi)
	mov	%rbx, opf_h_next(%rdi)
	mov	opf_C, %rbx
	mov	opf_X, %rcx
	mov	%rbx, opf_h_code(%rdi)
	mov	%rcx, opf_h_comp(%rdi)
	add	$opf_h__size, %rdi
	mov	%rdi, opf_H
	ret


opf_u_to_string:
	mov	opf_B, %rcx
	mov	%rbx, %rsi
opf_u_to_string_loop:
	dec	%rbx
	xor	%rdx, %rdx
	div	%rcx, %rax
	addb	$'0', %dl
	cmpb	$'9', %dl
	jle	opf_u_to_string_digit
	addb	$('A'-'9'-1), %dl
opf_u_to_string_digit:
	movb	%dl, (%rbx)
	test	%rax, %rax
	jne	opf_u_to_string_loop
	sub	%rbx, %rsi
	ret


opf_emit_code:
	push	%rax
	mov	%rsp, %rcx
	mov	$opf_char_size, %rdx
	mov	$opf_stdout, %rbx
	mov	$opf_syscall_write, %rax
	int	$opf_syscall
	add	$opf_cell_size, %rsp
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
	ret


opf_type_code:
	mov	%rax, %rdx
	mov	(%rbp), %rcx
	mov	$opf_stdout, %rbx
	mov	$opf_syscall_write, %rax
	int	$opf_syscall
	mov	opf_cell_size(%rbp), %rax
	add	$(2*opf_cell_size), %rbp
	ret


opf_dot_code:
	mov	%rsp, %rbx
	sub	$opf_pad_size, %rsp
	call	opf_u_to_string
	mov	%rsi, %rdx
	mov	%rbx, %rcx
	mov	$opf_stdout, %rbx
	mov	$opf_syscall_write, %rax
	int	$opf_syscall
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
	add	$opf_pad_size, %rsp
	ret

opf_lif_cond_table:
	.long opf_gt_code
	.byte opf_opcode_jle
	.long opf_le_code
	.byte opf_opcode_jg
	.long opf_xor_code
	.byte opf_opcode_jz
	.long 0

opf_lif_code:
	mov	opf_Qi, %rbx
	lea	opf_Q, %rcx
	add	%rbx, %rcx
	mov	opf_q_head(%rcx), %rbx
	cmp	$opf_q_head_max, %rbx
	jb	opf_lif_code_default
	lea	opf_lif_cond_table, %rdi
	mov	opf_h_code(%rbx), %rsi
opf_lif_code_find_cond:
	mov	opf_lif_cond_code_addr(%rdi), %rbx
	test	%rbx, %rbx
	jz	opf_lif_code_default
	add	$opf_lif_cond__size, %rdi
	cmp	%rbx, %rsi
	jne	opf_lif_code_find_cond
	mov	%rax, -opf_cell_size(%rbp)
	mov	opf_q_code(%rcx), %rax
	sub	$opf_cell_size, %rbp
	movl	$0x4D8BC389, (%rax)
	movl	$0x04458B00, opf_cell_size(%rax)
	movl	$0x3908C583, (2*opf_cell_size)(%rax)
	movb	$0xD9, (3*opf_cell_size)(%rax)
	movb	(-opf_lif_cond__size+opf_lif_cond_opcode)(%rdi), %bl
	movb	%bl, (opf_char_size+3*opf_cell_size)(%rax)
	xor	%rdx, %rdx
	mov	%rdx, opf_q_head(%rcx)
	add	$(4*opf_cell_size-opf_char_size), %rax
	mov	%rax, opf_C
	ret

opf_lif_code_default:
	mov	%rax, -opf_cell_size(%rbp)
	mov	opf_C, %rax
	sub	$opf_cell_size, %rbp
	movl	$0x458BC389, (%rax)
	movl	$0x04C58300, opf_cell_size(%rax)
	movl	$0x0074db85, (2*opf_cell_size)(%rax)
	xor	%rdx, %rdx
	mov	%rax, %rdi
	call	opf_Q_add
	add	$(3*opf_cell_size), %rax
	mov	%rax, opf_C
	ret


opf_if_code:
	mov	%rax, -opf_cell_size(%rbp)
	mov	opf_C, %rax
	sub	$opf_cell_size, %rbp
	movl	$0x0074C085, (%rax)
	xor	%rdx, %rdx
	mov	%rax, %rdi
	call	opf_Q_add
	add	$opf_cell_size, %rax
	mov	%rax, opf_C
	ret

opf_then_code:
	mov	opf_C, %rbx
	sub	%rax, %rbx
	movb	%bl, -1(%rax)
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
	ret

opf_literal_code:
	mov	%rax, %rdi
	call	opf_number_plant_literal
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
	ret


opf_string_code:
	mov	%rax, -opf_cell_size(%rbp)
	mov	$'"', %rax
	sub	$opf_cell_size, %rbp
	# vvvvv fall through vvvvv

opf_parse_code:
	mov	opf_H, %rdi
	mov	opf_I, %rbx
	mov	%rax, %rcx
	mov	%rdi, -opf_cell_size(%rbp)
	push	%rdi
	sub	$opf_cell_size, %rbp
opf_parse_restart:
	mov	opf_in_p(%rbx), %rsi
opf_parse_next:
	lodsb
	stosb
	cmpb	$'\n', %al
	je	opf_parse_nl
	cmpb	%cl, %al
	jne	opf_parse_next
opf_parse_found:
	mov	%rsi, opf_in_p(%rbx)
	movb	$0, -opf_char_size(%rdi)
	mov	%rdi, opf_H
	lea	-opf_char_size(%rdi), %rax
	pop	%rbx
	sub	%rbx, %rax
	ret
opf_parse_nl:
	cmp	%rsi, opf_in_e(%rbx)
	jne	opf_parse_next
	dec	%rdi
	push	%rcx
	call	*opf_in_refill(%rbx)
	pop	%rcx
	test	%rdx, %rdx
	jg	opf_parse_restart
	mov	$opf_error_eoi, %rax
	jmp	opf_abort


opf_tick_code:
	mov	%rax, -opf_cell_size(%rbp)
	sub	$opf_cell_size, %rbp
	call	opf_in_wsw
	test	%rcx, %rcx
	jle	opf_abort
	call	opf_dict_find
	mov	%rdx, %rax
	ret


opf_compile_code:
	mov	%rax, %rdx
	mov	(%rbp), %rax
	add	$opf_cell_size, %rbp
	jmp	*opf_h_comp(%rdx)


opf_trap_n_code:
	mov	%rax, %rdi
	mov	(%rbp), %rax
	cmp	$3, %rdi
	jg	opf_trap_n_code_on_stack
	lea	opf_trap_0_code, %rbx
	mov	%rdi, %rsi
	neg	%rsi
	lea	(%rbx, %rsi, 4), %rbx
	jmp	*%rbx
opf_trap_n_code_on_stack:
	lea	opf_cell_size(%rbp), %rbx
	jmp	opf_trap_0_code
opf_trap_3_code:
	mov	(3*opf_cell_size)(%rbp), %rdx
	nop
opf_trap_2_code:
	mov	(2*opf_cell_size)(%rbp), %rcx
	nop
opf_trap_1_code:
	mov	(1*opf_cell_size)(%rbp), %rbx
	nop
opf_trap_0_code:
	lea	opf_cell_size(%rbp, %rdi, 4), %rbp
	int	$opf_syscall
	ret


opf_anon_mmap:
	xor	%rax, %rax
	push	%rax
	push	%rax
	push	$(opf_mmap_map_private|opf_mmap_map_anonymous)
	push	$(opf_mmap_prot_read|opf_mmap_prot_write|opf_mmap_prot_exec)
	push	opf_cell_size(%rcx)
	push	%rax
	mov	$opf_syscall_mmap, %rax
	mov	%rsp, %rbx
	int	$opf_syscall
	add	$(6*opf_cell_size), %rsp
	cmp	$0xfffff000, %eax
	ja	opf_abort
	mov	%rax, (%rcx)
	ret

opf_strlen_code:
	mov	%rax, %rsi
	call	opf_strlen
	mov	%rcx, %rax
	ret


	.ascii "abort"
opf_abort_head:
	.byte 5
	.long 0
	.long opf_abort
	.long opf_compile_call

	.ascii "#%"
opf_vars_head:
	.byte 2
	.long opf_abort_head
	.long opf_vars_code
	.long opf_compile_call

	.ascii "#*"
opf_trap_n_head:
	.byte 2
	.long opf_vars_head
	.long opf_trap_n_code
	.long opf_compile_call

	.ascii "#{"
opf_input_from_fd_head:
	.byte 2
	.long opf_trap_n_head
	.long opf_input_from_fd_code
	.long opf_compile_call

	.ascii "\"#"
opf_strlen_head:
	.byte 2
	.long opf_input_from_fd_head
	.long opf_strlen_code
	.long opf_compile_call

	.ascii "#!"
opf_line_comment_head:
	.byte 2
	.long opf_strlen_head
	.long opf_line_comment_code
	.long opf_compile_call

	.ascii "#<"
opf_input_from_file_head:
	.byte 2
	.long opf_line_comment_head
	.long opf_input_from_file_code
	.long opf_compile_call

	.ascii "parse"
opf_parse_head:
	.byte 5
	.long opf_input_from_file_head
	.long opf_parse_code
	.long opf_compile_call

	.ascii "compile,"
opf_compile_head:
	.byte 8
	.long opf_parse_head
	.long opf_compile_code
	.long opf_compile_call

	.ascii "'"
opf_tick_head:
	.byte 1
	.long opf_compile_head
	.long opf_tick_code
	.long opf_compile_call

	.ascii "and"
opf_and_head:
	.byte 3
	.long opf_tick_head
	.long opf_and_code
	.long opf_compile_inline
	.byte opf_and_code_end - opf_and_code

	.ascii "or"
opf_or_head:
	.byte 2
	.long opf_and_head
	.long opf_or_code
	.long opf_compile_inline
	.byte opf_or_code_end - opf_or_code

	.ascii "xor"
opf_xor_head:
	.byte 3
	.long opf_or_head
	.long opf_xor_code
	.long opf_compile_inline
	.byte opf_xor_code_end - opf_xor_code

	.ascii "\""
opf_string_head:
	.byte 1
	.long opf_xor_head
	.long opf_string_code
	.long opf_compile_call

        .ascii "c!"
opf_char_store_head:
	.byte 2
	.long opf_string_head
	.long opf_char_store_code
	.long opf_compile_call
	
	.ascii "c@"
opf_char_fetch_head:
	.byte 2
	.long opf_char_store_head
	.long opf_char_fetch_code
	.long opf_compile_inline
	.byte opf_char_fetch_code_end - opf_char_fetch_code
	
	.ascii "!"
opf_store_head:
	.byte 1
	.long opf_char_fetch_head
	.long opf_store_code
	.long opf_compile_call

	.ascii "@"
opf_fetch_head:
	.byte 1
	.long opf_store_head
	.long opf_fetch_code
	.long opf_compile_inline
	.byte opf_fetch_code_end - opf_fetch_code

	.ascii "type"
opf_type_head:
	.byte 4
	.long opf_fetch_head
	.long opf_type_code
	.long opf_compile_call

	.ascii "emit"
opf_emit_head:
	.byte 4
	.long opf_type_head
	.long opf_emit_code
	.long opf_compile_call

	.ascii "."
opf_dot_head:
	.byte 1
	.long opf_emit_head
	.long opf_dot_code
	.long opf_compile_call

	.ascii "nip"
opf_nip_head:
	.byte 3
	.long opf_dot_head
	.long opf_nip_code
	.long opf_compile_inline
	.byte opf_nip_code_end - opf_nip_code

	.ascii "tuck"
opf_tuck_head:
	.byte 4
	.long opf_nip_head
	.long opf_tuck_code
	.long opf_compile_inline
	.byte opf_tuck_code_end - opf_tuck_code

	.ascii ","
opf_dict_store_word_head:
	.byte 1
	.long opf_tuck_head
	.long opf_dict_store_word_code
	.long opf_compile_call

	.ascii "#,"
opf_literal_head:
	.byte 2
	.long opf_dict_store_word_head
	.long opf_literal_code
	.long opf_compile_call

	.ascii "2/"
opf_halve_head:
	.byte 2
	.long opf_literal_head
	.long opf_halve_code
	.long opf_compile_inline
	.byte opf_halve_code_end - opf_halve_code

	.ascii "2*"
opf_double_head:
	.byte 2
	.long opf_halve_head
	.long opf_double_code
	.long opf_compile_inline
	.byte opf_double_code_end - opf_double_code

	.ascii "pop"
opf_pop_head:
	.byte 3
	.long opf_double_head
	.long opf_pop_code
	.long opf_compile_inline
	.byte opf_pop_code_end - opf_pop_code

	.ascii "push"
opf_push_head:
	.byte 4
	.long opf_pop_head
	.long opf_push_code
	.long opf_compile_inline
	.byte opf_push_code_end - opf_push_code

	.ascii "="
opf_eq_head:
	.byte 1
	.long opf_push_head
	.long opf_eq_code
	.long opf_compile_call

	.ascii "<="
opf_le_head:
	.byte 2
	.long opf_eq_head
	.long opf_le_code
	.long opf_compile_call

	.ascii ">"
opf_gt_head:
	.byte 1
	.long opf_le_head
	.long opf_gt_code
	.long opf_compile_call

	.ascii "-"
opf_sub_head:
	.byte 1
	.long opf_gt_head
	.long opf_sub_code
	.long opf_compile_add_sub
	.byte opf_sub_code_end-opf_sub_code
opf_sub_opcodes:
	.long opf_opcode_dec_rax
	.long opf_opcode_subb_rax
	.word opf_opcode_subl_rax

	.ascii "+"
opf_add_head:
	.byte 1
	.long opf_sub_head
	.long opf_sum_code
	.long opf_compile_add_sub
	.byte opf_sum_code_end-opf_sum_code
opf_add_opcodes:
	.long opf_opcode_inc_rax
	.long opf_opcode_addb_rax
	.word opf_opcode_addl_rax

	.ascii "then"
opf_then_head:
	.byte 4
	.long opf_add_head
	.long opf_then_code
	.long opf_compile_call

	.ascii "!if"
opf_lif_head:
	.byte 3
	.long opf_then_head
	.long opf_lif_code
	.long opf_compile_call

	.ascii "if"
opf_if_head:
	.byte 2
	.long opf_lif_head
	.long opf_if_code
	.long opf_compile_call

	.ascii "over"
opf_over_head:
	.byte 4
	.long opf_if_head
	.long opf_over_code
	.long opf_compile_inline
	.byte opf_over_code_end - opf_over_code

	.ascii "swap"
opf_swap_head:
	.byte 4
	.long opf_over_head
	.long opf_swap_code
	.long opf_compile_inline
	.byte opf_swap_code_end - opf_swap_code

	.ascii "drop"
opf_drop_head:
	.byte 4
	.long opf_swap_head
	.long opf_drop_code
	.long opf_compile_inline
	.byte opf_drop_code_end - opf_drop_code

	.ascii "dup"
opf_dup_head:
	.byte 3
	.long opf_drop_head
	.long opf_dup_code
	.long opf_compile_inline
	.byte opf_dup_code_end - opf_dup_code

	.ascii ";"
opf_return_head:
	.byte 1
	.long opf_dup_head
	.long opf_return_code
	.long opf_compile_call

	.ascii "{"
opf_left_brace_head:
	.byte 1
	.long opf_return_head
	.long opf_swap_state_code
	.long opf_compile_call

	.ascii "}"
opf_right_brace_head:
	.byte 1
	.long opf_left_brace_head
	.long opf_swap_state_code
	.long opf_swap_state_code

	.ascii ":"
opf_def_head:
	.byte 1
	.long opf_right_brace_head
	.long opf_def_code
	.long opf_compile_call

	opf_D_top = opf_def_head
