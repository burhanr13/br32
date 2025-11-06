#include "defs.asm"

main:
    stw lr, -4(sp)
    subi sp, sp, 4

    mtio zr, TMRCNT

.t1:
    movi a0, 1
    movi t0, -1
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ucmpi zr, 1
    blt .t2
    jp fail
.t2:
    movi a0, 2
    movi t0, -2
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ucmpi zr, 1
    blt .t3
    jp fail
.t3:
    movi a0, 3
    movi t0, -3
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ucmpi zr, 1
    blt .t4
    jp fail
.t4:
    movi a0, 4
    movi t0, -4
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ucmpi zr, 1
    blt .t5
    jp fail
.t5:
    movi a0, 5
    adr t2, main
    ldw t3, (t2)
    addi t3, t3, 3
    movi t0, -1
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ldw t1, (t2)
    addi t1, t1, 1
    addi t1, t1, 1
    addi t1, t1, 1
    ucmp t1, t3
    bne fail
.t6:
    movi a0, 6
    movi t0, -2
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ldw t1, (t2)
    addi t1, t1, 1
    addi t1, t1, 1
    addi t1, t1, 1
    ucmp t1, t3
    bne fail
.t7:
    movi a0, 7
    movi t0, -3
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ldw t1, (t2)
    addi t1, t1, 1
    addi t1, t1, 1
    addi t1, t1, 1
    ucmp t1, t3
    bne fail
.t8:
    movi a0, 8
    movi t0, -4
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ldw t1, (t2)
    addi t1, t1, 1
    addi t1, t1, 1
    addi t1, t1, 1
    ucmp t1, t3
    bne fail
.t9:
    movi a0, 9
    movi t0, -5
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    ldw t1, (t2)
    addi t1, t1, 1
    addi t1, t1, 1
    addi t1, t1, 1
    ucmp t1, t3
    bne fail
.t10:
    movi a0, 10
    movi t0, -1
    mtio t0, TMRVAL
    movi t0, 3
    mtio t0, TMRCNT
    mtsr zr, ie
    mfsr t0, ie
    tst t0, t0
    bne fail
    movi t0, 1
    mtsr t0, ie

success:
    adr a0, msg_success
    jl printf
    movi a0, 0
    addi sp, sp, 4
    ldw lr, -4(sp)
    ret

fail:
    mov a1, a0
    adr a0, msg_fail
    jl printf
    movi a0, 1
    addi sp, sp, 4
    ldw lr, -4(sp)
    ret


msg_success: ds "all tests passed\n"
msg_fail: ds "failed test %d\n"
