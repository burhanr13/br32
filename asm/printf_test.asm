#include "defs.asm"

main:
    stw lr, -4(sp)
    subi sp, sp, 4

    adr a0, .str0
    movi a1, 0x1234
    rori a2, a1, 8
    movi a3, 0x12340000
    or a4, a1, a3
    neg a5, a1
    jl printf

    adr a0, .str1
    movi a1, 0
    movi a2, 11
    movi a3, -1
    movi a4, 0x7fffffff
    movi a5, 0x10000
    jl printf

    addi sp, sp, 4
    ldw lr, -4(sp)
    ret

.str0: ds "a1=%x a2=%x a3=%x a4=%x a5=%x\n"
.str1: ds "%d %d %d %d %d\n"
