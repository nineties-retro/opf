#
# see ./Makefile for instructions on how to compile the code.
# see ./opf.txt for documentation.
#
        opf_C_default_size   = 4096
        opf_H_default_size   = 4096
        opf_S_default_size   = 4096
        opf_Q_size           = 4
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

        opf_mmap_prot_none =     0x00
        opf_mmap_prot_read =     0x01
        opf_mmap_prot_write =    0x02
        opf_mmap_prot_exec =     0x04
        opf_mmap_map_shared =    0x01
        opf_mmap_map_private =   0x02
        opf_mmap_map_fixed =     0x10
        opf_mmap_map_anonymous = 0x20

        opf_stdin =  0
        opf_stdout = 1
        opf_stderr = 2

        opf_h_len    =        0
        opf_h_next   =        opf_h_len  + opf_char_size
        opf_h_code   =        opf_h_next + opf_cell_size
        opf_h_comp   =        opf_h_code + opf_cell_size
        opf_h__size  =        opf_h_comp + opf_cell_size
        opf_h_inline =        opf_h__size
        opf_h_add_sub_table = opf_h_inline + opf_char_size

        opf_opcode_addl_eax =       0x03
        opf_opcode_addl_eax_short = 0xC083
        opf_opcode_call =           0xE8
        opf_opcode_decl_eax =       0x48
        opf_opcode_incl_eax =       0x40
        opf_opcode_jg =             0x7F
        opf_opcode_jge =            0x7D
        opf_opcode_jl =             0x7C
        opf_opcode_jle =            0x7E
        opf_opcode_jmp =            0xE9
        opf_opcode_jne =            0x75
        opf_opcode_jz =             0x74
        opf_opcode_ret =            0xC3
        opf_opcode_subl_eax =       0x2D
        opf_opcode_subl_eax_short = 0xE883

        opf_call_size = 5

        opf_add_sub_one =   0
        opf_add_sub_short = 1
        opf_add_sub_long =  3

        opf_add_sub_short_delta = 2

        opf_add_sub_short_size =  3
        opf_add_sub_long_size =   5

        opf_lif_cond_code_addr = 0
        opf_lif_cond_opcode =    opf_cell_size
        opf_lif_cond__size =     opf_cell_size+opf_char_size

        opf_in_refill    = 0
        opf_in_name      = opf_in_refill    + opf_cell_size
        opf_in_p         = opf_in_name      + opf_cell_size
        opf_in_s         = opf_in_p         + opf_cell_size
        opf_in_e         = opf_in_s         + opf_cell_size
        opf_in__size     = opf_in_e         + opf_cell_size

        opf_in_fd_fd    = opf_in__size
        opf_in_fd_bs    = opf_in_fd_fd + opf_cell_size
        opf_in_fd__size = opf_in_fd_bs + opf_cell_size

        opf_q_head  = 0
        opf_q_code  = opf_q_head + opf_cell_size
        opf_q__size = opf_q_code + opf_cell_size
        opf_q_mask  = ((1<<(opf_Q_size+1))-1)

        opf_q_head_drop_lit = 3
        opf_q_head_lit = 2
        opf_q_head_max = 0x10000

        opf_error_eoi =      1
        opf_error_bad_word = 2

opf_argc:                       .space opf_cell_size
opf_argv:                       .space opf_cell_size
opf_B:                          .long 16
opf_C:                          .space opf_cell_size
opf_C_size:                     .long opf_C_default_size
opf_H:                          .space opf_cell_size
opf_H_size:                     .long opf_H_default_size
opf_S:                          .space opf_cell_size
opf_S_size:                     .long opf_S_default_size
opf_D:                          .long opf_D_top
opf_I:                          .space opf_cell_size
opf_X:                          .long opf_compile_call
opf_L:                          .space opf_cell_size
opf_Q:                          .long 0, 0
                                .long 0, 0
                                .long 0, 0
                                .long 0, opf_vars_code
opf_Qi:                         .long opf_q__size*(opf_Q_size-1)
opf_defined_vector:             .long opf_defined_interpret
opf_undefined_vector:           .long opf_number_interpret
opf_number_vector:              .long opf_atou
opf_not_number_vector:          .long opf_bad_word_abort
opf_abort_vector:               .long opf_abort_default
opf_defined_vector_cache:       .long opf_defined_compile
                                .long opf_number_compile
opf_word_fail_msg:              .ascii " ?\n"


        .global _start
_start: 
        popl    %eax
        movl    %eax, opf_argc
        movl    %esp, opf_argv
        movl    %esp, %ebx
        pushl   $0
        movl    %esp, opf_L
opf_cmd_line_next:
        addl    $opf_cell_size, %ebx
        decl    %eax
        jz      opf_cmd_line_input_from_stdin
        movl    (%ebx), %esi
        cmpb    $'-', (%esi)
        jne     opf_cmd_line_input_from_file
        movl    $2, %ecx
opf_cmd_line_base:
        cmpb    $'b', opf_char_size(%esi)
        jne     opf_cmd_line_code_size
        leal    opf_B, %edx
        jmp     opf_cmd_line_parse_int
opf_cmd_line_code_size:
        cmpb    $'c', opf_char_size(%esi)
        jne     opf_cmd_line_header_size
        leal    opf_C_size, %edx
        jmp     opf_cmd_line_parse_int
opf_cmd_line_header_size:
        cmpb    $'h', opf_char_size(%esi)
        jne     opf_cmd_line_param_size
        leal    opf_H_size, %edx
        jmp     opf_cmd_line_parse_int
opf_cmd_line_param_size:
        cmpb    $'s', opf_char_size(%esi)
        jne     opf_cmd_line_lib
        leal    opf_S_size, %edx
        jmp     opf_cmd_line_parse_int
opf_cmd_line_lib:
        cmpb    $'l', opf_char_size(%esi)
        jne     opf_cmd_line_end
        addl    $(2*opf_char_size), %esi
        movl    %esi, (%esp)
        pushl   $0
        jmp     opf_cmd_line_next
opf_cmd_line_end:
        cmpw    $0x002D, opf_char_size(%esi)
        jne     opf_bad_word_abort
        # vvvvv fall through vvvvv

opf_cmd_line_input_from_stdin:
        call    opf_cmd_line_setup_args
        movl    $opf_stdin, %eax
        call    opf_input_from_fd_code
        jmp     opf_exit


opf_cmd_line_input_from_file:
        movl    opf_argv, %ecx
        movl    %ebx, opf_argv
        subl    %ecx, %ebx
        shrl    $2, %ebx
        subl    %ebx, opf_argc
        call    opf_cmd_line_setup_args
        movl    %esi, %ebx
        call    opf_boot_from_file
        # vvvv fall through vvvv

opf_exit:
        movl    $opf_syscall_exit, %eax
        movl    $opf_exit_success, %ebx
        int     $opf_syscall


opf_cmd_line_parse_int:
        pushl   %edx
        xorl    %ecx, %ecx
        decl    %ecx
        pushl   %esi
        addl    $(2*opf_char_size), %esi
        pushl   %ebx
        call    opf_atou
        popl    %ebx
        popl    %esi
        popl    %edx
        movl    %edi, (%edx)
        testl   %ecx, %ecx
        jz      opf_cmd_line_next
        negl    %ecx
        addl    $(2*opf_char_size), %ecx
        jmp     opf_bad_word_abort


opf_cmd_line_setup_args:
        leal    opf_C, %ecx
        call    opf_anon_mmap
        leal    opf_H, %ecx
        call    opf_anon_mmap
        leal    opf_S, %ecx
        call    opf_anon_mmap
        movl    opf_S_size, %ebp
        addl    %eax, %ebp
        ret


opf_text_interpreter:
        call    opf_in_wsw
        testl   %ecx, %ecx
        jle     opf_text_interpreter_end
        leal    opf_defined_vector, %ebx
        call    opf_dict_find   
        call    *(%ebx)
        jmp     opf_text_interpreter
opf_text_interpreter_end:
        ret


opf_defined_interpret:
        jmp     *opf_h_code(%edx)


opf_defined_compile:
        jmp     *opf_h_comp(%edx)


opf_number_convert:
        pushl   %ecx
        pushl   %esi
        movl    opf_number_vector, %ebx
        call    *%ebx
        popl    %esi
        testl   %ecx, %ecx
        jne     opf_number_convert_fail
        popl    %ecx
        ret
opf_number_convert_fail:
        movl    opf_not_number_vector, %ebx
        popl    %ecx
        jmp     *%ebx


opf_bad_word_abort:
        movl    %ecx, %edx
        movl    %esi, %ecx
        movl    $opf_stderr, %ebx
        movl    $opf_syscall_write, %eax
        int     $opf_syscall
        movl    $3, %edx
        leal    opf_word_fail_msg, %ecx
        movl    $opf_syscall_write, %eax
        int     $opf_syscall
        movl    $opf_error_bad_word, %eax
        jmp     opf_abort


opf_number_interpret:
        call    opf_number_convert
        movl    %eax, -opf_cell_size(%ebp)
        subl    $opf_cell_size, %ebp
        movl    %edi, %eax
        ret     

opf_number_compile:
        call    opf_number_convert
        # vvvv fall through vvvvv

opf_number_plant_literal:
        movl    opf_Qi, %ebx
        leal    opf_Q, %ecx
        addl    %ebx, %ecx
        movl    opf_q_head(%ecx), %ebx
        cmpl    $opf_drop_head, %ebx
        je      opf_number_plant_literal_after_drop
        movl    opf_C, %ebx
        movl    $0xB8FC4589, (%ebx)
        movl    %edi, opf_cell_size(%ebx)
        movl    $0x0004ED83, (2*opf_cell_size)(%ebx)
        movl    $opf_q_head_lit, %edx
        movl    %ebx, %edi
        call    opf_Q_add
        addl    $(opf_cell_size+opf_cell_size+opf_cell_size-1), %ebx
        movl    %ebx, opf_C
        ret

opf_number_plant_literal_after_drop:
        movl    opf_q_code(%ecx), %ebx
        movb    $0xB8, (%ebx)
        movl    %edi, opf_char_size(%ebx)
        addl    $(opf_char_size+opf_cell_size), %ebx
        movl    $opf_q_head_drop_lit, opf_q_head(%ecx)
        movl    %ebx, opf_C
        ret


opf_compile_call:
        movl    opf_C, %edi
        call    opf_Q_add
        movb    $opf_opcode_call, (%edi)
        addl    $(opf_call_size), %edi
        movl    opf_h_code(%edx), %ebx
        subl    %edi, %ebx
        movl    %edi, opf_C
        movl    %ebx, -opf_cell_size(%edi)
        ret

opf_compile_inline:
        movl    opf_C, %edi
        call    opf_Q_add
        xorl    %ecx, %ecx
        movl    opf_h_code(%edx), %esi
        movb    opf_h_inline(%edx), %cl
        rep
        movsb
        movl    %edi, opf_C
        ret


opf_Q_add:
        movl    opf_Qi, %esi
        leal    opf_Q, %ecx
        addl    $opf_q__size, %esi
        andl    $opf_q_mask, %esi
        movl    %edx, opf_q_head(%ecx, %esi)
        movl    %edi, opf_q_code(%ecx, %esi)
        movl    %esi, opf_Qi
        ret


opf_abort:
        movl    opf_abort_vector, %ebx
        jmp     *%ebx


opf_abort_default:
        movl    %eax, %ebx
        movl    $opf_syscall_exit, %eax
        int     $opf_syscall


opf_in_wsw:     
        movl    opf_H, %edi
        movl    opf_I, %ebx
        pushl   %edi
opf_in_wsw_restart:
        movl    opf_in_p(%ebx), %esi
opf_in_wsw_find_start:
        movb    (%esi), %cl
        incl    %esi
        cmpb    $' ', %cl
        je      opf_in_wsw_find_start
        cmpb    $'\n', %cl
        je      opf_in_wsw_nl_in_ws
opf_in_wsw_found_start: 
        movb    %cl, (%edi)
        incl    %edi
opf_in_wsw_next_word_char:
        movb    (%esi), %cl
        incl    %esi
        cmpb    $'\n', %cl
        je      opf_in_wsw_nl_in_word
        cmpb    $' ', %cl
        jne     opf_in_wsw_found_start
opf_in_wsw_found_end:
        movl    %esi, opf_in_p(%ebx)
        popl    %esi
        movl    %edi, %ecx
        subl    %esi, %ecx
        ret
opf_in_wsw_nl_in_ws:
        cmp     %esi, opf_in_e(%ebx)
        jne     opf_in_wsw_find_start
        call    *opf_in_refill(%ebx)
        testl   %edx, %edx
        jg      opf_in_wsw_restart
        popl    %edi
        movl    %edx, %ecx
        ret
opf_in_wsw_nl_in_word:
        cmpl    %esi, opf_in_e(%ebx)
        jne     opf_in_wsw_nl_in_word_end
        call    *opf_in_refill(%ebx)
        movl    opf_in_p(%ebx), %esi
        testl   %edx, %edx
        jg      opf_in_wsw_next_word_char
        popl    %edi
        movl    %edx, %ecx
        ret
opf_in_wsw_nl_in_word_end:
        decl    %esi
        jmp     opf_in_wsw_found_end


opf_in_fd_refill:
        pushl   %eax
        movl    opf_in_s(%ebx), %ecx
        movl    %ecx, opf_in_p(%ebx)
        movl    opf_in_fd_bs(%ebx), %edx
        pushl   %ebx
        movl    opf_in_fd_fd(%ebx), %ebx
        movl    $opf_syscall_read, %eax
        int     $opf_syscall
        popl    %ebx
        movl    %eax, %edx
        testl   %eax, %eax
        jle     opf_in_fd_refill_end
        addl    %eax, %ecx
        movb    $'\n', (%ecx)
        incl    %ecx
        movl    %ecx, opf_in_e(%ebx)
opf_in_fd_refill_end:
        popl    %eax
        ret


opf_in_skip:
        movl    opf_I, %ebx
opf_in_skip_again:
        movl    opf_in_p(%ebx), %esi
opf_in_skip_next:
        movb    (%esi), %dl
        incl    %esi
        cmpb    $'\n', %dl
        je      opf_in_skip_nl
opf_in_skip_check_char:
        cmpb    %cl, %dl
        jne     opf_in_skip_next
opf_in_skip_found:
        movl    %esi, opf_in_p(%ebx)    
        ret
opf_in_skip_nl:
        cmpl    %esi, opf_in_e(%ebx)
        jne     opf_in_skip_check_char
        pushl   %ecx
        call    *opf_in_refill(%ebx)
        popl    %ecx
        testl   %edx, %edx
        jg      opf_in_skip_again
        ret


opf_atou:
        pushl   %eax
        xorl    %edi, %edi
        movl    opf_B, %ebx
opf_atou_loop:
        lodsb
        testb   %al, %al
        jz      opf_atou_nul
        subb    $'0', %al
        jl      opf_atou_not_digit
        cmpb    $('9'-'0'+1), %al
        jl      opf_atou_digit
        subb    $7, %al               # map 'A' .. 'F' down to 10 .. 15
        jl      opf_atou_not_digit
        cmpb    $16, %al
        jl      opf_atou_digit
        subb    $32, %al              # map 'a' .. 'f' down to 10 .. 15
        jl      opf_atou_not_digit
        cmpb    $16, %al
        jge     opf_atou_not_digit
opf_atou_digit:
        cbw
        cwde
        cmpl    %ebx, %eax
        jge     opf_atou_not_digit
        xchgl   %edi, %eax                       # slow instruction!
        mull    %ebx
        addl    %eax, %edi
        decl    %ecx
        jne     opf_atou_loop
opf_atou_nul:
        xorl    %ecx, %ecx
opf_atou_not_digit:
        popl    %eax
        ret


opf_dict_find:
        movl    opf_D, %edx   
        pushl   %eax
opf_dict_find_next:
        testl   %edx, %edx
        je      opf_dict_find_fail
        cmpb    %cl, (%edx)
        je      opf_dict_find_check_str
        movl    opf_h_next(%edx), %edx
        jmp     opf_dict_find_next
opf_dict_find_check_str:
        pushl   %esi
        pushl   %ecx
        movl    %edx, %edi
        subl    %ecx, %edi
        repe
        cmpsb
        je      opf_dict_find_found
        popl    %ecx
        popl    %esi
        movl    opf_h_next(%edx), %edx
        jmp     opf_dict_find_next
opf_dict_find_found:
        popl    %ecx
        popl    %edi             # arbitrary register.
        popl    %eax
        ret
opf_dict_find_fail:
        xorl    %edx, %edx
        addl    $opf_cell_size, %ebx
        popl    %eax
        ret


opf_in_word_code:
        call    opf_in_wsw
        testl   %ecx, %ecx
        jle     opf_abort
        movl    %eax, -opf_cell_size(%ebp)
        movl    %esi, -(2*opf_cell_size)(%ebp)
        movl    %ecx, %eax
        subl    $(opf_cell_size*2), %ebp
        ret


opf_vars_code:
opf_debug_break:
        leal    opf_argc, %ebx
        leal    (%ebx, %eax, 4), %eax
        ret


opf_line_comment_code:
        movb    $'\n', %cl
        jmp     opf_in_skip


opf_dict_store_word_code:
        movl    opf_C, %edi
        stosl
        movl    (%ebp), %eax
        movl    %edi, opf_C
        addl    $opf_cell_size, %ebp
        ret

        opf_input_stack_adjust = opf_in_fd__size+opf_in_fd_block_size+1

opf_input_from_fd_code:
        xorl    %ebx, %ebx              # null file-name
opf_input_from_fd:
        pushl   %eax
        pushl   opf_I
        leal    -opf_in_fd__size(%esp), %edi
        movl    %edi, opf_I
        leal    -opf_input_stack_adjust(%esp), %ecx
        leal    opf_in_fd_refill, %eax
        movl    %eax, opf_in_refill(%edi)
        movl    %ebx, opf_in_name(%edi)
        movl    %ecx, %eax
        movl    %eax, opf_in_p(%edi)
        movl    %eax, opf_in_s(%edi)
        movb    $'\n', (%eax)
        incl    %eax
        movl    %eax, opf_in_e(%edi)
        movl    4(%esp), %eax           # opf_in_fd_fd
        movl    $opf_in_fd_block_size, opf_in_fd_bs(%edi)
        movl    %eax, opf_in_fd_fd(%edi)
        movl    %ecx, %esp
        call    opf_text_interpreter
        addl    $opf_input_stack_adjust, %esp
        popl    opf_I
        popl    %eax
        ret


opf_input_from_file_code:
        call    opf_in_wsw
        testl   %ecx, %ecx
        jle     opf_abort
        movb    $0, (%edi)
        movl    %esi, %ebx
        # vvvv fall through vvvv

opf_boot_from_file:
        pushl   %eax
        pushl   %ebx
        cmpb    $'/', (%ebx)
        je      opf_boot_from_file_absolute
        movl    opf_L, %ecx
opf_boot_from_file_next:
        movl    (%esp), %ebx
        movl    (%ecx), %esi
        testl   %esi, %esi
        je      opf_boot_from_file_not_found
        movl    opf_C, %edi
        pushl   %edi
        call    opf_strcpy
        movl    $'/', (%edi)
        incl    %edi
        movl    %ebx, %esi
        call    opf_strcpy
        movb    $0, (%edi)
        popl    %ebx
        pushl   %ecx
        xorl    %ecx, %ecx
        movl    $opf_syscall_open, %eax
        int     $opf_syscall
        popl    %ecx
        testl   %eax, %eax
        jg      opf_boot_from_file_eval
        subl    $opf_cell_size, %ecx
        jmp     opf_boot_from_file_next


opf_boot_from_file_absolute:
        xorl    %ecx, %ecx
        movl    $opf_syscall_open, %eax
        int     $opf_syscall
        testl   %eax, %eax
        jl      opf_boot_from_file_not_found
        # vvvv fall through vvvvv

opf_boot_from_file_eval:
        call    opf_input_from_fd
        movl    %eax, %ebx
        movl    $opf_syscall_close, %eax
        int     $opf_syscall
        addl    $opf_cell_size, %esp
        popl    %eax
        ret

opf_boot_from_file_not_found:
        addl    $(2*opf_cell_size), %esp
        movl    %ebx, %esi
        call    opf_strlen
        movl    %ebx, %esi
        jmp     opf_bad_word_abort


opf_strcpy:
        movb    (%esi), %al
        testb   %al, %al
        jz      opf_strcpy_finished
        movb    %al, (%edi)
        incl    %esi
        incl    %edi
        jmp     opf_strcpy
opf_strcpy_finished:
        ret


opf_strlen:
        xorl    %ecx, %ecx
opf_strlen_next:
        cmpb    $0, (%esi)
        je      opf_strlen_finished
        incl    %ecx
        incl    %esi
        jmp     opf_strlen_next
opf_strlen_finished:
        ret


opf_double_code:
        shll    $1, %eax
opf_double_code_end:
        ret


opf_halve_code:
        shrl    $1, %eax
opf_halve_code_end:
        ret


opf_dup_code:
        movl    %eax, -opf_cell_size(%ebp)
        subl    $opf_cell_size, %ebp
opf_dup_code_end:
        ret


opf_drop_code:
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
opf_drop_code_end:
        ret


opf_over_code:
        movl    %eax, -opf_cell_size(%ebp)
        movl    (%ebp), %eax
        subl    $opf_cell_size, %ebp
opf_over_code_end:
        ret


opf_nip_code:
        addl    $opf_cell_size, %ebp
opf_nip_code_end:
        ret


opf_tuck_code:
        movl    (%ebp), %ebx
        movl    %eax, (%ebp)
        movl    %ebx, -opf_cell_size(%ebp)
        subl    $opf_cell_size, %ebp
opf_tuck_code_end:
        ret

opf_swap_code:
        xchgl   (%ebp), %eax
opf_swap_code_end:
        ret


opf_push_code:
        pushl   %eax
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
opf_push_code_end:
        ret


opf_pop_code:
        movl    %eax, -opf_cell_size(%ebp)
        popl    %eax
        subl    $opf_cell_size, %ebp
opf_pop_code_end:
        ret


opf_sum_code:
        addl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
opf_sum_code_end:
        ret


opf_sub_code:
        movl    (%ebp), %ebx
        subl    %eax, %ebx
        movl    %ebx, %eax
        addl    $opf_cell_size, %ebp
opf_sub_code_end:
        ret


opf_compile_add_sub:
        movl    opf_Qi, %ebx
        leal    opf_Q, %ecx
        addl    %ebx, %ecx
        movl    opf_q_head(%ecx), %ebx
        cmpl    $opf_q_head_lit, %ebx
        jne     opf_compile_inline
        pushl   %eax
        movl    opf_q_code(%ecx), %esi
        movl    opf_cell_size(%esi), %ebx
        leal    opf_h_add_sub_table(%edx), %edi
        cmpl    $0xFF, %ebx
        ja      opf_compile_add_sub_long
        cmpl    $1, %ebx
        jne     opf_compile_add_sub_short
        movb    opf_add_sub_one(%edi), %al
        movb    %al, (%esi)
        incl    %esi
        jmp     opf_compile_add_sub_adjust_q
opf_compile_add_sub_short:
        movw    opf_add_sub_short(%edi), %ax
        movw    %ax, (%esi)
        movb    %bl, opf_add_sub_short_delta(%esi)
        addl    $opf_add_sub_short_size, %esi
        jmp     opf_compile_add_sub_adjust_q
opf_compile_add_sub_long:
        movb    opf_add_sub_long(%edi), %al
        movb    %al, (%esi)
        movl    %ebx, opf_char_size(%esi)
        addl    $opf_add_sub_long_size, %esi
opf_compile_add_sub_adjust_q:
        xorl    %edx, %edx
        movl    %edx, opf_q_head(%ecx)
        movl    %esi, opf_C
        popl    %eax
        ret


opf_eq_code:
        xorl    (%ebp), %eax
        notl    %eax
        addl    $opf_cell_size, %ebp
        ret

opf_le_code:
        subl    (%ebp), %eax
        notl    %eax
        shrl    $31, %eax
        addl    $opf_cell_size, %ebp
        ret

opf_gt_code:
        subl    (%ebp), %eax
        shrl    $31, %eax
        addl    $opf_cell_size, %ebp
opf_gt_code_end:
        ret


opf_and_code:
        andl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
opf_and_code_end:
        ret


opf_or_code:
        orl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
opf_or_code_end:
        ret


opf_xor_code:
        xorl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
opf_xor_code_end:
        ret


opf_store_code:
        movl    (%ebp), %ebx
        movl    %ebx, (%eax)
        movl    opf_cell_size(%ebp), %eax
        addl    $(2*opf_cell_size), %ebp
        ret

opf_fetch_code:
        movl    (%eax), %eax
opf_fetch_code_end:
        ret


opf_swap_state_code:
        leal    opf_defined_vector, %esi
        leal    opf_defined_vector_cache, %edi
        fldl    (%edi)
        fldl    (%esi)
        fstpl   (%edi)
        fstpl   (%esi)
        ret


opf_return_code:
        movl    opf_Qi, %ebx
        leal    opf_Q, %ecx
        movl    opf_D, %edx
        addl    %ebx, %ecx
        movl    opf_q_code(%ecx), %ebx
        movl    opf_h_code(%edx), %esi
        cmpb    $opf_opcode_call, (%ebx)
        jne     opf_return_code_inline_or_ret
        cmpl    %ebx, %esi
        je      opf_return_code_alias
        movb    $opf_opcode_jmp, (%ebx)
        ret
opf_return_code_inline_or_ret:
        movl    opf_C, %edi
        cmpl    %ebx, %esi
        je      opf_return_code_inline
opf_return_code_ret:
        leal    opf_return_head, %edx
        movb    $opf_opcode_ret, (%edi)
        call    opf_Q_add
        incl    %edi
        movl    %edi, opf_C
        ret
opf_return_code_inline:
        movl    %edi, %ebx        
        subl    %esi, %ebx
        movl    %ebx, opf_h_inline(%edx)
        movl    opf_q_head(%ecx), %ebx
        leal    opf_compile_inline, %esi
        incl    opf_H
        movl    %esi, opf_h_comp(%edx)
        cmpl    $opf_q_head_max, %ebx
        jl      opf_return_code_ret
opf_return_code_inline_alias:
        movl    opf_h_code(%edx), %esi
        movl    opf_h_code(%ebx), %edi
        movl    %esi, opf_C
        movl    %edi, opf_h_code(%edx)
opf_Q_remove:
        movl    opf_Qi, %ebx
        subl    $opf_q__size, %ebx
        andl    $opf_q_mask, %ebx
        movl    %ebx, opf_Qi        
        ret
opf_return_code_alias:
        movl    -opf_cell_size(%edi), %ecx
        addl    %edi, %ecx              # possibly replace with 
        subl    $opf_call_size, %edi    # leal -opf_call_size(%edi,%ecx), %ecx
        movl    %ecx, opf_h_code(%edx)
        movl    %edi, opf_C
        jmp     opf_Q_remove


opf_def_code:
        call    opf_in_wsw
        testl   %ecx, %ecx
        jle     opf_abort
        movl    opf_D, %ebx
        movl    %edi, opf_D
        movb    %cl, (%edi)
        movl    %ebx, opf_h_next(%edi)
        movl    opf_C, %ebx
        movl    opf_X, %ecx
        movl    %ebx, opf_h_code(%edi)
        movl    %ecx, opf_h_comp(%edi)
        addl    $opf_h__size, %edi
        movl    %edi, opf_H
        ret


opf_u_to_string:
        movl    opf_B, %ecx
        movl    %ebx, %esi
opf_u_to_string_loop:
        decl    %ebx
        xorl    %edx, %edx
        divl    %ecx, %eax
        addb    $'0', %dl
        cmpb    $'9', %dl
        jle     opf_u_to_string_digit
        addb    $('A'-'9'-1), %dl
opf_u_to_string_digit:
        movb    %dl, (%ebx)
        testl   %eax, %eax
        jne     opf_u_to_string_loop
        subl    %ebx, %esi
        ret


opf_emit_code:
        pushl   %eax
        movl    %esp, %ecx
        movl    $opf_char_size, %edx
        movl    $opf_stdout, %ebx
        movl    $opf_syscall_write, %eax
        int     $opf_syscall
        addl    $opf_cell_size, %esp
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
        ret


opf_type_code:
        movl    %eax, %edx
        movl    (%ebp), %ecx
        movl    $opf_stdout, %ebx
        movl    $opf_syscall_write, %eax
        int     $opf_syscall
        movl    opf_cell_size(%ebp), %eax
        addl    $(2*opf_cell_size), %ebp
        ret


opf_dot_code:
        movl    %esp, %ebx
        subl    $opf_pad_size, %esp
        call    opf_u_to_string
        movl    %esi, %edx
        movl    %ebx, %ecx
        movl    $opf_stdout, %ebx
        movl    $opf_syscall_write, %eax
        int     $opf_syscall
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
        addl    $opf_pad_size, %esp
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
        movl    opf_Qi, %ebx
        leal    opf_Q, %ecx
        addl    %ebx, %ecx
        movl    opf_q_head(%ecx), %ebx
        cmpl    $opf_q_head_max, %ebx
        jb      opf_lif_code_default
        leal    opf_lif_cond_table, %edi
        movl    opf_h_code(%ebx), %esi
opf_lif_code_find_cond:
        movl    opf_lif_cond_code_addr(%edi), %ebx
        testl   %ebx, %ebx
        jz      opf_lif_code_default
        addl    $opf_lif_cond__size, %edi
        cmpl    %ebx, %esi
        jne     opf_lif_code_find_cond
        movl    %eax, -opf_cell_size(%ebp)
        movl    opf_q_code(%ecx), %eax
        subl    $opf_cell_size, %ebp
        movl    $0x4D8BC389, (%eax)
        movl    $0x04458B00, opf_cell_size(%eax)
        movl    $0x3908C583, (2*opf_cell_size)(%eax)
        movb    $0xD9, (3*opf_cell_size)(%eax)
        movb    (-opf_lif_cond__size+opf_lif_cond_opcode)(%edi), %bl
        movb    %bl, (opf_char_size+3*opf_cell_size)(%eax)
        xorl    %edx, %edx
        movl    %edx, opf_q_head(%ecx)
        addl    $(4*opf_cell_size-opf_char_size), %eax
        movl    %eax, opf_C
        ret

opf_lif_code_default:
        movl    %eax, -opf_cell_size(%ebp)
        movl    opf_C, %eax
        subl    $opf_cell_size, %ebp
        movl    $0x458BC389, (%eax)
        movl    $0x04C58300, opf_cell_size(%eax)
        movl    $0x0074db85, (2*opf_cell_size)(%eax)
        xorl    %edx, %edx
        movl    %eax, %edi
        call    opf_Q_add
        addl    $(3*opf_cell_size), %eax
        movl    %eax, opf_C
        ret


opf_if_code:
        movl    %eax, -opf_cell_size(%ebp)
        movl    opf_C, %eax
        subl    $opf_cell_size, %ebp
        movl    $0x0074C085, (%eax)
        xorl    %edx, %edx
        movl    %eax, %edi
        call    opf_Q_add
        addl    $opf_cell_size, %eax
        movl    %eax, opf_C
        ret

opf_then_code:
        movl    opf_C, %ebx
        subl    %eax, %ebx
        movb    %bl, -1(%eax)
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
        ret

opf_literal_code:
        movl    %eax, %edi
        call    opf_number_plant_literal
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
        ret


opf_string_code:
        movl    %eax, -opf_cell_size(%ebp)
        movl    $'"', %eax
        subl    $opf_cell_size, %ebp
        # vvvvv fall through vvvvv

opf_parse_code:
        movl    opf_H, %edi
        movl    opf_I, %ebx
        movl    %eax, %ecx
        movl    %edi, -opf_cell_size(%ebp)
        pushl   %edi
        subl    $opf_cell_size, %ebp
opf_parse_restart:
        movl    opf_in_p(%ebx), %esi
opf_parse_next:
        lodsb
        stosb
        cmpb    $'\n', %al
        je      opf_parse_nl
        cmpb    %cl, %al
        jne     opf_parse_next
opf_parse_found:
        movl    %esi, opf_in_p(%ebx)
        movb    $0, -opf_char_size(%edi)
        movl    %edi, opf_H
        leal    -opf_char_size(%edi), %eax
        popl    %ebx
        subl    %ebx, %eax
        ret
opf_parse_nl:
        cmpl    %esi, opf_in_e(%ebx)
        jne     opf_parse_next
        decl    %edi
        pushl   %ecx
        call    *opf_in_refill(%ebx)
        popl    %ecx
        testl   %edx, %edx
        jg      opf_parse_restart
        movl    $opf_error_eoi, %eax
        jmp     opf_abort


opf_tick_code:
        movl    %eax, -opf_cell_size(%ebp)
        subl    $opf_cell_size, %ebp
        call    opf_in_wsw
        testl   %ecx, %ecx
        jle     opf_abort
        call    opf_dict_find
        movl    %edx, %eax
        ret


opf_compile_code:
        movl    %eax, %edx
        movl    (%ebp), %eax
        addl    $opf_cell_size, %ebp
        jmp     *opf_h_comp(%edx)


opf_trap_n_code:
        movl    %eax, %edi
        movl    (%ebp), %eax
        cmpl    $3, %edi
        jg      opf_trap_n_code_on_stack
        leal    opf_trap_0_code, %ebx
        movl    %edi, %esi
        negl    %esi
        leal    (%ebx, %esi, 4), %ebx
        jmp     *%ebx
opf_trap_n_code_on_stack:
        leal    opf_cell_size(%ebp), %ebx
        jmp     opf_trap_0_code
opf_trap_3_code:
        movl    (3*opf_cell_size)(%ebp), %edx
        nop
opf_trap_2_code:
        movl    (2*opf_cell_size)(%ebp), %ecx
        nop
opf_trap_1_code:
        movl    (1*opf_cell_size)(%ebp), %ebx
        nop
opf_trap_0_code:
        leal    opf_cell_size(%ebp, %edi, 4), %ebp
        int     $opf_syscall
        ret


opf_anon_mmap:
        xorl    %eax, %eax
        pushl   %eax
        pushl   %eax
        pushl   $(opf_mmap_map_private|opf_mmap_map_anonymous)
        pushl   $(opf_mmap_prot_read|opf_mmap_prot_write|opf_mmap_prot_exec)
        pushl   opf_cell_size(%ecx)
        pushl   %eax
        movl    $opf_syscall_mmap, %eax
        movl    %esp, %ebx
        int     $opf_syscall
        addl    $(6*4), %esp
        cmpl    $0xfffff000, %eax
        ja      opf_abort
        movl    %eax, (%ecx)
        ret

opf_strlen_code:
        movl    %eax, %esi
        call    opf_strlen
        movl    %ecx, %eax
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
