.include "constants.inc"
    
    .global main
main:
    adr t0, message_len
    ldw t0, (t0)
    adr t1, message
    movi t2, 0
    .loop:
        ldbx t3, (t1, t2)
        mtio t3, COUT
        addi t2, t2, 1
        ucmp t2, t0
        blt .loop

    ret

message:
    .string "hello world\n"
message_len: .word . - message
