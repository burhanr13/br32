#include "rules.asm"

main:
    movi a0, 0
    jl factorial
    mov s0, a0

    movi a0, 1
    jl factorial
    mov s1, a0

    movi a0, 2
    jl factorial
    mov s2, a0

    movi a0, 3
    jl factorial
    mov s3, a0

    movi a0, 4
    jl factorial
    mov s4, a0

    movi a0, 5
    jl factorial
    mov s5, a0

    movi a0, 6
    jl factorial
    mov s6, a0

.spin:
    jp .spin

factorial:
    mov t0, a0
    movi a0, 1
    .outer:
        movi t2, 0
        movi t1, 0
        .inner:
            add t2, t2, a0
            addi t1, t1, 1
            scmp t1, t0
            blt .inner
        mov a0, t2
        subi t0, t0, 1
        scmpi t0, 0
        bgt .outer
    ret
