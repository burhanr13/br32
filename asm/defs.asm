#once
#include "rules.asm"

#const HALT = 0x0000
#const COUT = 0x0001
#const CLK = 0x0002

start:
    movi sp, 0x10000
    jl main
    mtio zr, HALT

puts:
    ldb t0, (a0)
    tst t0, t0
    beq .end
    mtio t0, COUT
    addi a0, a0, 1
    jp puts
.end:
    movi t0, "\n"`8
    mtio t0, COUT
    ret

hexdigit:
    ucmpi a0, 9
    bge .letter
    addi a0, a0, "0"`8
    ret
.letter:
    addi a0, a0, "a" - 10
    ret

print_hex:
    stw lr, -4(sp)
    mov t0, a0
    ubfe a0, t0, 28, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 24, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 20, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 16, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 12, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 8, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 4, 4
    jl hexdigit
    mtio a0, COUT
    ubfe a0, t0, 0, 4
    jl hexdigit
    mtio a0, COUT
    ldw lr, -4(sp)
    ret

printf:
    stw a7, -4(sp)
    stw a6, -8(sp)
    stw a5, -12(sp)
    stw a4, -16(sp)
    stw a3, -20(sp)
    stw a2, -24(sp)
    stw a1, -28(sp)
    stw lr, -32(sp)
    stw s0, -36(sp)
    stw s1, -40(sp)
    subi s1, sp, 28 ; argument array
    mov s0, a0 ; string
    subi sp, sp, 40

.loop:
    ldb t0, (s0)
    tst t0, t0
    beq .end
    ucmpi t0, "%"`8
    bne .put
    addi s0, s0, 1
    ldb t0, (s0)
    ucmpi t0, "x"`8
    bne .notx
    ldw a0, (s1)
    addi s1, s1, 4
    jl print_hex
    addi s0, s0, 1
    jp .loop
.notx:
    movi t1, "%"`8
    mtio t1, COUT
.put:
    mtio t0, COUT
    addi s0, s0, 1
    jp .loop
.end:
    addi sp, sp, 40
    ldw s1, -40(sp)
    ldw s0, -36(sp)
    ldw lr, -32(sp)
    ret
    






