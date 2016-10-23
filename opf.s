#
# see ./Makefile for instructions on how to compile the code.
# see ./opf.txt for documentation.
#
	opf_C_default_size   = 4096
	opf_H_default_size   = 4096
	opf_S_default_size   = 4096
	opf_Q_size	     = 4
	opf_in_fd_block_size = 256

	opf_cell_size = 4
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

	opf_opcode_addl_eax =	    0x03
	opf_opcode_addl_eax_short = 0xC083
	opf_opcode_call =	    0xE8
	opf_opcode_decl_eax =	    0x48
	opf_opcode_incl_eax =	    0x40
	opf_opcode_jg =		    0x7F
	opf_opcode_jge =	    0x7D
	opf_opcode_jl =		    0x7C
	opf_opcode_jle =	    0x7E
	opf_opcode_jmp =	    0xE9
	opf_opcode_jne =	    0x75
	opf_opcode_jz =		    0x74
	opf_opcode_ret =	    0xC3
	opf_opcode_subl_eax =	    0x2D
	opf_opcode_subl_eax_short = 0xE883

	opf_call_size = 5

	opf_add_sub_one =   0
	opf_add_sub_short = 1
	opf_add_sub_long =  3

	opf_add_sub_short_delta = 2

	opf_add_sub_short_size =  3
	opf_add_sub_long_size =	  5

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
	pop	%eax
	mov	%eax, opf_argc
	mov	%esp, opf_argv
	mov	%esp, %ebx
	push	$0
	mov	%esp, opf_L
opf_cmd_line_next:
	add	$opf_cell_size, %ebx
	dec	%eax
	jz	opf_cmd_line_input_from_stdin
	mov	(%ebx), %esi
	cmpb	$'-', (%esi)
	jne	opf_cmd_line_input_from_file
	mov	$2, %ecx
opf_cmd_line_base:
	cmpb	$'b', opf_char_size(%esi)
	jne	opf_cmd_line_code_size
	lea	opf_B, %edx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_code_size:
	cmpb	$'c', opf_char_size(%esi)
	jne	opf_cmd_line_header_size
	lea	opf_C_size, %edx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_header_size:
	cmpb	$'h', opf_char_size(%esi)
	jne	opf_cmd_line_param_size
	lea	opf_H_size, %edx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_param_size:
	cmpb	$'s', opf_char_size(%esi)
	jne	opf_cmd_line_lib
	lea	opf_S_size, %edx
	jmp	opf_cmd_line_parse_int
opf_cmd_line_lib:
	cmpb	$'l', opf_char_size(%esi)
	jne	opf_cmd_line_end
	add	$(2*opf_char_size), %esi
	mov	%esi, (%esp)
	push	$0
	jmp	opf_cmd_line_next
opf_cmd_line_end:
	cmpw	$0x002D, opf_char_size(%esi)
	jne	opf_bad_word_abort
	# vvvvv fall through vvvvv

opf_cmd_line_input_from_stdin:
	call	opf_cmd_line_setup_args
	mov	$opf_stdin, %eax
	call	opf_input_from_fd_code
	jmp	opf_exit


opf_cmd_line_input_from_file:
	mov	opf_argv, %ecx
	mov	%ebx, opf_argv
	sub	%ecx, %ebx
	shr	$2, %ebx
	sub	%ebx, opf_argc
	call	opf_cmd_line_setup_args
	mov	%esi, %ebx
	call	opf_boot_from_file
	# vvvv fall through vvvv

opf_exit:
	mov	$opf_syscall_exit, %eax
	mov	$opf_exit_success, %ebx
	int	$opf_syscall


opf_cmd_line_parse_int:
	push	%edx
	xor	%ecx, %ecx
	dec	%ecx
	push	%esi
	add	$(2*opf_char_size), %esi
	push	%ebx
	call	opf_atou
	pop	%ebx
	pop	%esi
	pop	%edx
	mov	%edi, (%edx)
	test	%ecx, %ecx
	jz	opf_cmd_line_next
	neg	%ecx
	add	$(2*opf_char_size), %ecx
	jmp	opf_bad_word_abort


opf_cmd_line_setup_args:
	lea	opf_C, %ecx
	call	opf_anon_mmap
	lea	opf_H, %ecx
	call	opf_anon_mmap
	lea	opf_S, %ecx
	call	opf_anon_mmap
	mov	opf_S_size, %ebp
	add	%eax, %ebp
	ret


opf_text_interpreter:
	call	opf_in_wsw
	test	%ecx, %ecx
	jle	opf_text_interpreter_end
	lea	opf_defined_vector, %ebx
	call	opf_dict_find	
	call	*(%ebx)
	jmp	opf_text_interpreter
opf_text_interpreter_end:
	ret


opf_defined_interpret:
	jmp	*opf_h_code(%edx)


opf_defined_compile:
	jmp	*opf_h_comp(%edx)


opf_number_convert:
	push	%ecx
	push	%esi
	mov	opf_number_vector, %ebx
	call	*%ebx
	pop	%esi
	test	%ecx, %ecx
	jne	opf_number_convert_fail
	pop	%ecx
	ret
opf_number_convert_fail:
	mov	opf_not_number_vector, %ebx
	pop	%ecx
	jmp	*%ebx


opf_bad_word_abort:
	mov	%ecx, %edx
	mov	%esi, %ecx
	mov	$opf_stderr, %ebx
	mov	$opf_syscall_write, %eax
	int	$opf_syscall
	mov	$3, %edx
	lea	opf_word_fail_msg, %ecx
	mov	$opf_syscall_write, %eax
	int	$opf_syscall
	mov	$opf_error_bad_word, %eax
	jmp	opf_abort


opf_number_interpret:
	call	opf_number_convert
	mov	%eax, -opf_cell_size(%ebp)
	sub	$opf_cell_size, %ebp
	mov	%edi, %eax
	ret	

opf_number_compile:
	call	opf_number_convert
	# vvvv fall through vvvvv

opf_number_plant_literal:
	mov	opf_Qi, %ebx
	lea	opf_Q, %ecx
	add	%ebx, %ecx
	mov	opf_q_head(%ecx), %ebx
	cmp	$opf_drop_head, %ebx
	je	opf_number_plant_literal_after_drop
	mov	opf_C, %ebx
	movl	$0xB8FC4589, (%ebx)
	mov	%edi, opf_cell_size(%ebx)
	movl	$0x0004ED83, (2*opf_cell_size)(%ebx)
	mov	$opf_q_head_lit, %edx
	mov	%ebx, %edi
	call	opf_Q_add
	add	$(opf_cell_size+opf_cell_size+opf_cell_size-1), %ebx
	mov	%ebx, opf_C
	ret

opf_number_plant_literal_after_drop:
	mov	opf_q_code(%ecx), %ebx
	movb	$0xB8, (%ebx)
	mov	%edi, opf_char_size(%ebx)
	add	$(opf_char_size+opf_cell_size), %ebx
	movl	$opf_q_head_drop_lit, opf_q_head(%ecx)
	mov	%ebx, opf_C
	ret


opf_compile_call:
	mov	opf_C, %edi
	call	opf_Q_add
	movb	$opf_opcode_call, (%edi)
	add	$(opf_call_size), %edi
	mov	opf_h_code(%edx), %ebx
	sub	%edi, %ebx
	mov	%edi, opf_C
	mov	%ebx, -opf_cell_size(%edi)
	ret

opf_compile_inline:
	mov	opf_C, %edi
	call	opf_Q_add
	xor	%ecx, %ecx
	mov	opf_h_code(%edx), %esi
	movb	opf_h_inline(%edx), %cl
	rep
	movsb
	mov	%edi, opf_C
	ret


opf_Q_add:
	mov	opf_Qi, %esi
	lea	opf_Q, %ecx
	add	$opf_q__size, %esi
	and	$opf_q_mask, %esi
	mov	%edx, opf_q_head(%ecx, %esi)
	mov	%edi, opf_q_code(%ecx, %esi)
	mov	%esi, opf_Qi
	ret


opf_abort:
	mov	opf_abort_vector, %ebx
	jmp	*%ebx


opf_abort_default:
	mov	%eax, %ebx
	mov	$opf_syscall_exit, %eax
	int	$opf_syscall


opf_in_wsw:	
	mov	opf_H, %edi
	mov	opf_I, %ebx
	push	%edi
opf_in_wsw_restart:
	mov	opf_in_p(%ebx), %esi
opf_in_wsw_find_start:
	movb	(%esi), %cl
	inc	%esi
	cmpb	$' ', %cl
	je	opf_in_wsw_find_start
	cmpb	$'\n', %cl
	je	opf_in_wsw_nl_in_ws
opf_in_wsw_found_start: 
	movb	%cl, (%edi)
	inc	%edi
opf_in_wsw_next_word_char:
	movb	(%esi), %cl
	inc	%esi
	cmpb	$'\n', %cl
	je	opf_in_wsw_nl_in_word
	cmpb	$' ', %cl
	jne	opf_in_wsw_found_start
opf_in_wsw_found_end:
	mov	%esi, opf_in_p(%ebx)
	pop	%esi
	mov	%edi, %ecx
	sub	%esi, %ecx
	ret
opf_in_wsw_nl_in_ws:
	cmp	%esi, opf_in_e(%ebx)
	jne	opf_in_wsw_find_start
	call	*opf_in_refill(%ebx)
	test	%edx, %edx
	jg	opf_in_wsw_restart
	pop	%edi
	mov	%edx, %ecx
	ret
opf_in_wsw_nl_in_word:
	cmp	%esi, opf_in_e(%ebx)
	jne	opf_in_wsw_nl_in_word_end
	call	*opf_in_refill(%ebx)
	mov	opf_in_p(%ebx), %esi
	test	%edx, %edx
	jg	opf_in_wsw_next_word_char
	pop	%edi
	mov	%edx, %ecx
	ret
opf_in_wsw_nl_in_word_end:
	dec	%esi
	jmp	opf_in_wsw_found_end


opf_in_fd_refill:
	push	%eax
	mov	opf_in_s(%ebx), %ecx
	mov	%ecx, opf_in_p(%ebx)
	mov	opf_in_fd_bs(%ebx), %edx
	push	%ebx
	mov	opf_in_fd_fd(%ebx), %ebx
	mov	$opf_syscall_read, %eax
	int	$opf_syscall
	pop	%ebx
	mov	%eax, %edx
	test	%eax, %eax
	jle	opf_in_fd_refill_end
	add	%eax, %ecx
	movb	$'\n', (%ecx)
	inc	%ecx
	mov	%ecx, opf_in_e(%ebx)
opf_in_fd_refill_end:
	pop	%eax
	ret


opf_in_skip:
	mov	opf_I, %ebx
opf_in_skip_again:
	mov	opf_in_p(%ebx), %esi
opf_in_skip_next:
	movb	(%esi), %dl
	inc	%esi
	cmpb	$'\n', %dl
	je	opf_in_skip_nl
opf_in_skip_check_char:
	cmpb	%cl, %dl
	jne	opf_in_skip_next
opf_in_skip_found:
	mov	%esi, opf_in_p(%ebx)	
	ret
opf_in_skip_nl:
	cmp	%esi, opf_in_e(%ebx)
	jne	opf_in_skip_check_char
	push	%ecx
	call	*opf_in_refill(%ebx)
	pop	%ecx
	test	%edx, %edx
	jg	opf_in_skip_again
	ret


opf_atou:
	push	%eax
	xor	%edi, %edi
	mov	opf_B, %ebx
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
	cmp	%ebx, %eax
	jge	opf_atou_not_digit
	xchg	%edi, %eax			 # slow instruction!
	mull	%ebx
	add	%eax, %edi
	dec	%ecx
	jne	opf_atou_loop
opf_atou_nul:
	xor	%ecx, %ecx
opf_atou_not_digit:
	pop	%eax
	ret


opf_dict_find:
	mov	opf_D, %edx   
	push	%eax
opf_dict_find_next:
	test	%edx, %edx
	je	opf_dict_find_fail
	cmpb	%cl, (%edx)
	je	opf_dict_find_check_str
	mov	opf_h_next(%edx), %edx
	jmp	opf_dict_find_next
opf_dict_find_check_str:
	push	%esi
	push	%ecx
	mov	%edx, %edi
	sub	%ecx, %edi
	repe
	cmpsb
	je	opf_dict_find_found
	pop	%ecx
	pop	%esi
	mov	opf_h_next(%edx), %edx
	jmp	opf_dict_find_next
opf_dict_find_found:
	pop	%ecx
	pop	%edi		 # arbitrary register.
	pop	%eax
	ret
opf_dict_find_fail:
	xor	%edx, %edx
	add	$opf_cell_size, %ebx
	pop	%eax
	ret


opf_in_word_code:
	call	opf_in_wsw
	test	%ecx, %ecx
	jle	opf_abort
	mov	%eax, -opf_cell_size(%ebp)
	mov	%esi, -(2*opf_cell_size)(%ebp)
	mov	%ecx, %eax
	sub	$(opf_cell_size*2), %ebp
	ret


opf_vars_code:
opf_debug_break:
	lea	opf_argc, %ebx
	lea	(%ebx, %eax, 4), %eax
	ret


opf_line_comment_code:
	movb	$'\n', %cl
	jmp	opf_in_skip


opf_dict_store_word_code:
	mov	opf_C, %edi
	stosl
	mov	(%ebp), %eax
	mov	%edi, opf_C
	add	$opf_cell_size, %ebp
	ret

	opf_input_stack_adjust = opf_in_fd__size+opf_in_fd_block_size+1

opf_input_from_fd_code:
	xor	%ebx, %ebx		# null file-name
opf_input_from_fd:
	push	%eax
	push	opf_I
	lea	-opf_in_fd__size(%esp), %edi
	mov	%edi, opf_I
	lea	-opf_input_stack_adjust(%esp), %ecx
	lea	opf_in_fd_refill, %eax
	mov	%eax, opf_in_refill(%edi)
	mov	%ebx, opf_in_name(%edi)
	mov	%ecx, %eax
	mov	%eax, opf_in_p(%edi)
	mov	%eax, opf_in_s(%edi)
	movb	$'\n', (%eax)
	inc	%eax
	mov	%eax, opf_in_e(%edi)
	mov	4(%esp), %eax		# opf_in_fd_fd
	movl	$opf_in_fd_block_size, opf_in_fd_bs(%edi)
	mov	%eax, opf_in_fd_fd(%edi)
	mov	%ecx, %esp
	call	opf_text_interpreter
	add	$opf_input_stack_adjust, %esp
	pop	opf_I
	pop	%eax
	ret


opf_input_from_file_code:
	call	opf_in_wsw
	test	%ecx, %ecx
	jle	opf_abort
	movb	$0, (%edi)
	mov	%esi, %ebx
	# vvvv fall through vvvv

opf_boot_from_file:
	push	%eax
	push	%ebx
	cmpb	$'/', (%ebx)
	je	opf_boot_from_file_absolute
	mov	opf_L, %ecx
opf_boot_from_file_next:
	mov	(%esp), %ebx
	mov	(%ecx), %esi
	test	%esi, %esi
	je	opf_boot_from_file_not_found
	mov	opf_C, %edi
	push	%edi
	call	opf_strcpy
	movl	$'/', (%edi)
	inc	%edi
	mov	%ebx, %esi
	call	opf_strcpy
	movb	$0, (%edi)
	pop	%ebx
	push	%ecx
	xor	%ecx, %ecx
	mov	$opf_syscall_open, %eax
	int	$opf_syscall
	pop	%ecx
	test	%eax, %eax
	jg	opf_boot_from_file_eval
	sub	$opf_cell_size, %ecx
	jmp	opf_boot_from_file_next


opf_boot_from_file_absolute:
	xor	%ecx, %ecx
	mov	$opf_syscall_open, %eax
	int	$opf_syscall
	test	%eax, %eax
	jl	opf_boot_from_file_not_found
	# vvvv fall through vvvvv

opf_boot_from_file_eval:
	call	opf_input_from_fd
	mov	%eax, %ebx
	mov	$opf_syscall_close, %eax
	int	$opf_syscall
	add	$opf_cell_size, %esp
	pop	%eax
	ret

opf_boot_from_file_not_found:
	add	$(2*opf_cell_size), %esp
	mov	%ebx, %esi
	call	opf_strlen
	mov	%ebx, %esi
	jmp	opf_bad_word_abort


opf_strcpy:
	movb	(%esi), %al
	testb	%al, %al
	jz	opf_strcpy_finished
	movb	%al, (%edi)
	inc	%esi
	inc	%edi
	jmp	opf_strcpy
opf_strcpy_finished:
	ret


opf_strlen:
	xor	%ecx, %ecx
opf_strlen_next:
	cmpb	$0, (%esi)
	je	opf_strlen_finished
	inc	%ecx
	inc	%esi
	jmp	opf_strlen_next
opf_strlen_finished:
	ret


opf_double_code:
	shl	$1, %eax
opf_double_code_end:
	ret


opf_halve_code:
	shr	$1, %eax
opf_halve_code_end:
	ret


opf_dup_code:
	mov	%eax, -opf_cell_size(%ebp)
	sub	$opf_cell_size, %ebp
opf_dup_code_end:
	ret


opf_drop_code:
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
opf_drop_code_end:
	ret


opf_over_code:
	mov	%eax, -opf_cell_size(%ebp)
	mov	(%ebp), %eax
	sub	$opf_cell_size, %ebp
opf_over_code_end:
	ret


opf_nip_code:
	add	$opf_cell_size, %ebp
opf_nip_code_end:
	ret


opf_tuck_code:
	mov	(%ebp), %ebx
	mov	%eax, (%ebp)
	mov	%ebx, -opf_cell_size(%ebp)
	sub	$opf_cell_size, %ebp
opf_tuck_code_end:
	ret

opf_swap_code:
	xchg	(%ebp), %eax
opf_swap_code_end:
	ret


opf_push_code:
	push	%eax
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
opf_push_code_end:
	ret


opf_pop_code:
	mov	%eax, -opf_cell_size(%ebp)
	pop	%eax
	sub	$opf_cell_size, %ebp
opf_pop_code_end:
	ret


opf_sum_code:
	add	(%ebp), %eax
	add	$opf_cell_size, %ebp
opf_sum_code_end:
	ret


opf_sub_code:
	mov	(%ebp), %ebx
	sub	%eax, %ebx
	mov	%ebx, %eax
	add	$opf_cell_size, %ebp
opf_sub_code_end:
	ret


opf_compile_add_sub:
	mov	opf_Qi, %ebx
	lea	opf_Q, %ecx
	add	%ebx, %ecx
	mov	opf_q_head(%ecx), %ebx
	cmp	$opf_q_head_lit, %ebx
	jne	opf_compile_inline
	push	%eax
	mov	opf_q_code(%ecx), %esi
	mov	opf_cell_size(%esi), %ebx
	lea	opf_h_add_sub_table(%edx), %edi
	cmp	$0xFF, %ebx
	ja	opf_compile_add_sub_long
	cmp	$1, %ebx
	jne	opf_compile_add_sub_short
	movb	opf_add_sub_one(%edi), %al
	movb	%al, (%esi)
	inc	%esi
	jmp	opf_compile_add_sub_adjust_q
opf_compile_add_sub_short:
	movw	opf_add_sub_short(%edi), %ax
	movw	%ax, (%esi)
	movb	%bl, opf_add_sub_short_delta(%esi)
	add	$opf_add_sub_short_size, %esi
	jmp	opf_compile_add_sub_adjust_q
opf_compile_add_sub_long:
	movb	opf_add_sub_long(%edi), %al
	movb	%al, (%esi)
	mov	%ebx, opf_char_size(%esi)
	add	$opf_add_sub_long_size, %esi
opf_compile_add_sub_adjust_q:
	xor	%edx, %edx
	mov	%edx, opf_q_head(%ecx)
	mov	%esi, opf_C
	pop	%eax
	ret


opf_eq_code:
	xor	(%ebp), %eax
	not	%eax
	add	$opf_cell_size, %ebp
	ret

opf_le_code:
	sub	(%ebp), %eax
	not	%eax
	shr	$31, %eax
	add	$opf_cell_size, %ebp
	ret

opf_gt_code:
	sub	(%ebp), %eax
	shr	$31, %eax
	add	$opf_cell_size, %ebp
opf_gt_code_end:
	ret


opf_and_code:
	and	(%ebp), %eax
	add	$opf_cell_size, %ebp
opf_and_code_end:
	ret


opf_or_code:
	or	(%ebp), %eax
	add	$opf_cell_size, %ebp
opf_or_code_end:
	ret


opf_xor_code:
	xor	(%ebp), %eax
	add	$opf_cell_size, %ebp
opf_xor_code_end:
	ret


opf_store_code:
	mov	(%ebp), %ebx
	mov	%ebx, (%eax)
	mov	opf_cell_size(%ebp), %eax
	add	$(2*opf_cell_size), %ebp
	ret

opf_fetch_code:
	mov	(%eax), %eax
opf_fetch_code_end:
	ret


opf_swap_state_code:
	lea	opf_defined_vector, %esi
	lea	opf_defined_vector_cache, %edi
	fldl	(%edi)
	fldl	(%esi)
	fstpl	(%edi)
	fstpl	(%esi)
	ret


opf_return_code:
	mov	opf_Qi, %ebx
	lea	opf_Q, %ecx
	mov	opf_D, %edx
	add	%ebx, %ecx
	mov	opf_q_code(%ecx), %ebx
	mov	opf_h_code(%edx), %esi
	cmpb	$opf_opcode_call, (%ebx)
	jne	opf_return_code_inline_or_ret
	cmp	%ebx, %esi
	je	opf_return_code_alias
	movb	$opf_opcode_jmp, (%ebx)
	ret
opf_return_code_inline_or_ret:
	mov	opf_C, %edi
	cmp	%ebx, %esi
	je	opf_return_code_inline
opf_return_code_ret:
	lea	opf_return_head, %edx
	movb	$opf_opcode_ret, (%edi)
	call	opf_Q_add
	inc	%edi
	mov	%edi, opf_C
	ret
opf_return_code_inline:
	mov	%edi, %ebx	  
	sub	%esi, %ebx
	mov	%ebx, opf_h_inline(%edx)
	mov	opf_q_head(%ecx), %ebx
	lea	opf_compile_inline, %esi
	incl	opf_H
	mov	%esi, opf_h_comp(%edx)
	cmp	$opf_q_head_max, %ebx
	jl	opf_return_code_ret
opf_return_code_inline_alias:
	mov	opf_h_code(%edx), %esi
	mov	opf_h_code(%ebx), %edi
	mov	%esi, opf_C
	mov	%edi, opf_h_code(%edx)
opf_Q_remove:
	mov	opf_Qi, %ebx
	sub	$opf_q__size, %ebx
	and	$opf_q_mask, %ebx
	mov	%ebx, opf_Qi	    
	ret
opf_return_code_alias:
	mov	-opf_cell_size(%edi), %ecx
	add	%edi, %ecx		# possibly replace with 
	sub	$opf_call_size, %edi	# lea -opf_call_size(%edi,%ecx), %ecx
	mov	%ecx, opf_h_code(%edx)
	mov	%edi, opf_C
	jmp	opf_Q_remove


opf_def_code:
	call	opf_in_wsw
	test	%ecx, %ecx
	jle	opf_abort
	mov	opf_D, %ebx
	mov	%edi, opf_D
	movb	%cl, (%edi)
	mov	%ebx, opf_h_next(%edi)
	mov	opf_C, %ebx
	mov	opf_X, %ecx
	mov	%ebx, opf_h_code(%edi)
	mov	%ecx, opf_h_comp(%edi)
	add	$opf_h__size, %edi
	mov	%edi, opf_H
	ret


opf_u_to_string:
	mov	opf_B, %ecx
	mov	%ebx, %esi
opf_u_to_string_loop:
	dec	%ebx
	xor	%edx, %edx
	div	%ecx, %eax
	addb	$'0', %dl
	cmpb	$'9', %dl
	jle	opf_u_to_string_digit
	addb	$('A'-'9'-1), %dl
opf_u_to_string_digit:
	movb	%dl, (%ebx)
	test	%eax, %eax
	jne	opf_u_to_string_loop
	sub	%ebx, %esi
	ret


opf_emit_code:
	push	%eax
	mov	%esp, %ecx
	mov	$opf_char_size, %edx
	mov	$opf_stdout, %ebx
	mov	$opf_syscall_write, %eax
	int	$opf_syscall
	add	$opf_cell_size, %esp
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
	ret


opf_type_code:
	mov	%eax, %edx
	mov	(%ebp), %ecx
	mov	$opf_stdout, %ebx
	mov	$opf_syscall_write, %eax
	int	$opf_syscall
	mov	opf_cell_size(%ebp), %eax
	add	$(2*opf_cell_size), %ebp
	ret


opf_dot_code:
	mov	%esp, %ebx
	sub	$opf_pad_size, %esp
	call	opf_u_to_string
	mov	%esi, %edx
	mov	%ebx, %ecx
	mov	$opf_stdout, %ebx
	mov	$opf_syscall_write, %eax
	int	$opf_syscall
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
	add	$opf_pad_size, %esp
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
	mov	opf_Qi, %ebx
	lea	opf_Q, %ecx
	add	%ebx, %ecx
	mov	opf_q_head(%ecx), %ebx
	cmp	$opf_q_head_max, %ebx
	jb	opf_lif_code_default
	lea	opf_lif_cond_table, %edi
	mov	opf_h_code(%ebx), %esi
opf_lif_code_find_cond:
	mov	opf_lif_cond_code_addr(%edi), %ebx
	test	%ebx, %ebx
	jz	opf_lif_code_default
	add	$opf_lif_cond__size, %edi
	cmp	%ebx, %esi
	jne	opf_lif_code_find_cond
	mov	%eax, -opf_cell_size(%ebp)
	mov	opf_q_code(%ecx), %eax
	sub	$opf_cell_size, %ebp
	movl	$0x4D8BC389, (%eax)
	movl	$0x04458B00, opf_cell_size(%eax)
	movl	$0x3908C583, (2*opf_cell_size)(%eax)
	movb	$0xD9, (3*opf_cell_size)(%eax)
	movb	(-opf_lif_cond__size+opf_lif_cond_opcode)(%edi), %bl
	movb	%bl, (opf_char_size+3*opf_cell_size)(%eax)
	xor	%edx, %edx
	mov	%edx, opf_q_head(%ecx)
	add	$(4*opf_cell_size-opf_char_size), %eax
	mov	%eax, opf_C
	ret

opf_lif_code_default:
	mov	%eax, -opf_cell_size(%ebp)
	mov	opf_C, %eax
	sub	$opf_cell_size, %ebp
	movl	$0x458BC389, (%eax)
	movl	$0x04C58300, opf_cell_size(%eax)
	movl	$0x0074db85, (2*opf_cell_size)(%eax)
	xor	%edx, %edx
	mov	%eax, %edi
	call	opf_Q_add
	add	$(3*opf_cell_size), %eax
	mov	%eax, opf_C
	ret


opf_if_code:
	mov	%eax, -opf_cell_size(%ebp)
	mov	opf_C, %eax
	sub	$opf_cell_size, %ebp
	movl	$0x0074C085, (%eax)
	xor	%edx, %edx
	mov	%eax, %edi
	call	opf_Q_add
	add	$opf_cell_size, %eax
	mov	%eax, opf_C
	ret

opf_then_code:
	mov	opf_C, %ebx
	sub	%eax, %ebx
	movb	%bl, -1(%eax)
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
	ret

opf_literal_code:
	mov	%eax, %edi
	call	opf_number_plant_literal
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
	ret


opf_string_code:
	mov	%eax, -opf_cell_size(%ebp)
	mov	$'"', %eax
	sub	$opf_cell_size, %ebp
	# vvvvv fall through vvvvv

opf_parse_code:
	mov	opf_H, %edi
	mov	opf_I, %ebx
	mov	%eax, %ecx
	mov	%edi, -opf_cell_size(%ebp)
	push	%edi
	sub	$opf_cell_size, %ebp
opf_parse_restart:
	mov	opf_in_p(%ebx), %esi
opf_parse_next:
	lodsb
	stosb
	cmpb	$'\n', %al
	je	opf_parse_nl
	cmpb	%cl, %al
	jne	opf_parse_next
opf_parse_found:
	mov	%esi, opf_in_p(%ebx)
	movb	$0, -opf_char_size(%edi)
	mov	%edi, opf_H
	lea	-opf_char_size(%edi), %eax
	pop	%ebx
	sub	%ebx, %eax
	ret
opf_parse_nl:
	cmp	%esi, opf_in_e(%ebx)
	jne	opf_parse_next
	dec	%edi
	push	%ecx
	call	*opf_in_refill(%ebx)
	pop	%ecx
	test	%edx, %edx
	jg	opf_parse_restart
	mov	$opf_error_eoi, %eax
	jmp	opf_abort


opf_tick_code:
	mov	%eax, -opf_cell_size(%ebp)
	sub	$opf_cell_size, %ebp
	call	opf_in_wsw
	test	%ecx, %ecx
	jle	opf_abort
	call	opf_dict_find
	mov	%edx, %eax
	ret


opf_compile_code:
	mov	%eax, %edx
	mov	(%ebp), %eax
	add	$opf_cell_size, %ebp
	jmp	*opf_h_comp(%edx)


opf_trap_n_code:
	mov	%eax, %edi
	mov	(%ebp), %eax
	cmp	$3, %edi
	jg	opf_trap_n_code_on_stack
	lea	opf_trap_0_code, %ebx
	mov	%edi, %esi
	neg	%esi
	lea	(%ebx, %esi, 4), %ebx
	jmp	*%ebx
opf_trap_n_code_on_stack:
	lea	opf_cell_size(%ebp), %ebx
	jmp	opf_trap_0_code
opf_trap_3_code:
	mov	(3*opf_cell_size)(%ebp), %edx
	nop
opf_trap_2_code:
	mov	(2*opf_cell_size)(%ebp), %ecx
	nop
opf_trap_1_code:
	mov	(1*opf_cell_size)(%ebp), %ebx
	nop
opf_trap_0_code:
	lea	opf_cell_size(%ebp, %edi, 4), %ebp
	int	$opf_syscall
	ret


opf_anon_mmap:
	xor	%eax, %eax
	push	%eax
	push	%eax
	push	$(opf_mmap_map_private|opf_mmap_map_anonymous)
	push	$(opf_mmap_prot_read|opf_mmap_prot_write|opf_mmap_prot_exec)
	push	opf_cell_size(%ecx)
	push	%eax
	mov	$opf_syscall_mmap, %eax
	mov	%esp, %ebx
	int	$opf_syscall
	add	$(6*opf_cell_size), %esp
	cmp	$0xfffff000, %eax
	ja	opf_abort
	mov	%eax, (%ecx)
	ret

opf_strlen_code:
	mov	%eax, %esi
	call	opf_strlen
	mov	%ecx, %eax
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

	.ascii "!"
opf_store_head:
	.byte 1
	.long opf_string_head
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
	.byte opf_opcode_decl_eax
	.word opf_opcode_subl_eax_short
	.byte opf_opcode_subl_eax

	.ascii "+"
opf_add_head:
	.byte 1
	.long opf_sub_head
	.long opf_sum_code
	.long opf_compile_add_sub
	.byte opf_sum_code_end-opf_sum_code
opf_add_opcodes:
	.byte opf_opcode_incl_eax
	.word opf_opcode_addl_eax_short
	.byte opf_opcode_addl_eax

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
