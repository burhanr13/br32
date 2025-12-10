#include "defs.asm"

main:
    stw lr, -4(sp)
    subi sp, sp, 4

.t1:
    movi a0, 1
    adr t1, fail
    adr t0, .t2
    stw t1, -4(sp)
    stw t0, -4(sp)
    ldw t2, -4(sp)
    jpr t2
    jp fail
    jp fail
    jp fail
.t2:
    movi a0, 2
    stw zr, -4(sp)
    ldw t0, -4(sp)
    tst t0, t0
    bne fail
    jp .t3
    jp fail
    jp fail
.t3:
    movi a0, 3
    ucmpi zr, 1
    mfcr t0
    ucmpi t0, 2
    bne fail
    jp .t4
    jp fail
    jp fail
.t4:
    movi a0, 4
    stw zr, -4(sp)
    ldw t0, -4(sp)
    tst t0, t0
    beq .t5
    jp fail
    jp fail
    jp fail
.t5:
    movi a0, 5
    ucmpi zr, 1
    mfcr t0
    ucmpi t0, 2
    beq success
    jp fail
    jp fail
    jp fail

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
