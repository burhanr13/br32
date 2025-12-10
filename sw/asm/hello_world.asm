#include "defs.asm"

main:
    movi t0, message_len
    movi t1, message
    movi t2, 0
    .loop:
        ldbx t3, (t1, t2)
        mtio t3, COUT
        addi t2, t2, 1
        ucmp t2, t0
        blt .loop

    ret

message:
    #d "hello world\n"
message_len = $ - message
