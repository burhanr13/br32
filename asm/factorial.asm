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

; outp | addr | data (base 16)

;   0:0 |    0 |             ; main:
;   0:0 |    0 | 92 00 00 00 ; movi a0, 0
;   4:0 |    4 | 4f 05 00 00 ; jl factorial
;   8:0 |    8 | 7e 04 42 00 ; mov s0, a0
;   c:0 |    c | 92 00 01 00 ; movi a0, 1
;  10:0 |   10 | 8f 04 00 00 ; jl factorial
;  14:0 |   14 | be 04 42 00 ; mov s1, a0
;  18:0 |   18 | 92 00 02 00 ; movi a0, 2
;  1c:0 |   1c | cf 03 00 00 ; jl factorial
;  20:0 |   20 | fe 04 42 00 ; mov s2, a0
;  24:0 |   24 | 92 00 03 00 ; movi a0, 3
;  28:0 |   28 | 0f 03 00 00 ; jl factorial
;  2c:0 |   2c | 3e 05 42 00 ; mov s3, a0
;  30:0 |   30 | 92 00 04 00 ; movi a0, 4
;  34:0 |   34 | 4f 02 00 00 ; jl factorial
;  38:0 |   38 | 7e 05 42 00 ; mov s4, a0
;  3c:0 |   3c | 92 00 05 00 ; movi a0, 5
;  40:0 |   40 | 8f 01 00 00 ; jl factorial
;  44:0 |   44 | be 05 42 00 ; mov s5, a0
;  48:0 |   48 | 92 00 06 00 ; movi a0, 6
;  4c:0 |   4c | cf 00 00 00 ; jl factorial
;  50:0 |   50 | fe 05 42 00 ; mov s6, a0
;  54:0 |   54 |             ; .spin:
;  54:0 |   54 | 0e 00 00 00 ; jp .spin
;  58:0 |   58 |             ; factorial:
;  58:0 |   58 | be 02 42 00 ; mov t0, a0
;  5c:0 |   5c | 92 00 01 00 ; movi a0, 1
;  60:0 |   60 |             ; .outer:
;  60:0 |   60 | 12 03 00 00 ; movi t2, 0
;  64:0 |   64 | d2 02 00 00 ; movi t1, 0
;  68:0 |   68 |             ; .inner:
;  68:0 |   68 | 3e 63 02 00 ; add t2, t2, a0
;  6c:0 |   6c | d0 5a 01 00 ; addi t1, t1, 1
;  70:0 |   70 | 3e 58 8a 04 ; scmp t1, t0
;  74:0 |   74 | 4c ff ff ff ; blt .inner
;  78:0 |   78 | be 00 4c 00 ; mov a0, t2
;  7c:0 |   7c | 94 52 01 00 ; subi t0, t0, 1
;  80:0 |   80 | 38 51 00 00 ; scmpi t0, 0
;  84:0 |   84 | c8 fd ff ff ; bgt .outer
;  88:0 |   88 | 38 fc 00 00 ; ret