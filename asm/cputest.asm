#include "defs.asm"

main:
    stw lr, -4(sp)
    subi sp, sp, 4

    ; BRANCHES
.t1:
    movi a0, 1
    jp $+8
    jp fail
.t2:
    movi a0, 2
    jp $+16
    jp fail
    jp .t3
    jp fail
    jp $-8
    jp fail
    jp fail
.t3:
    movi a0, 3
    adr t0, ..l1
    jl $+8
..l1:
    jp fail
    ucmp t0, lr
    bne fail
.t4:
    movi a0, 4
    ucmp zr, zr
    bne fail
    beq .t5
    jp fail
.t5:
    movi a0, 5
    ucmpi zr, 1
    bnl fail
    blt .t6
    jp fail
.t6:
    movi a0, 6
    scmpi zr, -1
    bng fail
    bgt .t20
    jp fail
.t7:
    movi a0, 7
    adr t0, .t8
    jpr t0
    jp fail
.t8:
    movi a0, 8
    adr t0, .t9
    jlr t0
..l1:
    jp fail
.t9:
    movi a0, 9
    adr t0, .t8.l1
    ucmp a0, lr
    bne fail

    ; ALU
.t20:
    movi a0, 20
    movi t0, 1234
    addi t1, t0, 1111
    ucmpi t1, 2345
    bne fail
.t21:
    movi a0, 21
    movi t0, 0x12340
    addi t1, t0, 0x56780000
    movi t2, 0x56792340
    ucmp t1, t2
    bne fail
.t22:
    movi a0, 22
    movi t0, 0x12356
    movi t1, 0x12356
    sub t2, t0, t1
    ucmp t2, zr
    bne fail
.t23:
    movi a0, 23
    movi t0, -1
    movi t1, 0x12345678
    or t0, t0, t1
    ucmpi t0, -1
    bne fail
.t24:
    movi a0, 24
    movi t0, 0xcccccccc
    movi t1, 0x33333333
    not t2, t0
    ucmp t1, t2
    bne fail
    xori t2, t0, -1
    ucmp t2, t1
    bne fail
.t25:
    movi a0, 25
    movi t0, 1<<20
    andni t0, t0, 1<<20
    tst t0, t0
    bne fail
.t26:
    movi a0, 26
    movi t0, 0xabcd
    tsti t0, 0x0bc0
    bng fail
.t27:
    movi a0, 27
    movi t0, 0
    movi t1, 1
    ucmp t0, t1
    bnl fail
    ucmp t1, t0
    bng fail
.t28:
    movi a0, 28
    scmp t0, t1
    bnl fail
    scmp t1, t0
    bng fail
.t29:
    movi a0, 29
    movi t0, 0
    movi t1, -1
    ucmp t0, t1
    bnl fail
    ucmp t1, t0
    bng fail
.t30:
    movi a0, 30
    scmp t0, t1
    bng fail
    scmp t1, t0
    bnl fail
.t31:
    movi a0, 31
    movi t0, 0x7fffffff
    ucmpi t0, 0x80000000
    bnl fail
    scmpi t0, 0x80000000
    bng fail
    subi t0, t0, 0xffff
    ucmpi t0, 0x7fff0000
    bne fail
.t32:
    movi a0, 32
    movi t0, 0x1234
    tsti t0, 1<<2|1<<9
    bng fail
.t33:
    movi a0, 33
    movi t0, 12345
    add zr, t0, t0
    ucmpi zr, 0
    bne fail
.t34:
    movi a0, 34
    movi t0, 0x12345678
    movi t1, 0x87654321
    add t2, t0, t1
    movi t3, 0x12345678+0x87654321
    ucmp t2, t3
    bne fail
.t35:
    movi a0, 35
    movi t0, 0x12345678
    movi t1, 0x87654321
    sub t2, t0, t1
    movi t3, 0x12345678-0x87654321
    ucmp t2, t3
    bne fail
.t36:
    movi a0, 36
    movi t0, 0x12345678
    movi t1, 0x87654321
    and t2, t0, t1
    movi t3, 0x12345678&0x87654321
    ucmp t2, t3
    bne fail
.t37:
    movi a0, 37
    movi t0, 0x12345678
    movi t1, 0x87654321
    andn t2, t0, t1
    movi t3, 0x12345678&!0x87654321
    ucmp t2, t3
    bne fail
.t38:
    movi a0, 38
    movi t0, 0x12345678
    movi t1, 0x87654321
    or t2, t0, t1
    movi t3, 0x12345678|0x87654321
    ucmp t2, t3
    bne fail
.t39:
    movi a0, 39
    movi t0, 0x12345678
    movi t1, 0x87654321
    orn t2, t0, t1
    movi t3, 0x12345678|!0x87654321
    ucmp t2, t3
    bne fail
.t40:
    movi a0, 40
    movi t0, 0x12345678
    movi t1, 0x87654321
    xor t2, t0, t1
    movi t3, 0x12345678^0x87654321
    ucmp t2, t3
    bne fail
.t41:
    movi a0, 41
    movi t0, 0x12345678
    movi t1, 0x87654321
    xorn t2, t0, t1
    movi t3, 0x12345678^!0x87654321
    ucmp t2, t3
    bne fail
.t42:
    movi a0, 42
    movi t0, 0x88888888
    tst t0, t0
    bnl fail
.t43:
    movi a0, 43
    movi t0, 0x12345678
    movi t1, 4
    sll t2, t0, t1
    movi t3, 0x23456780
    ucmp t2, t3
    bne fail
    slli t1, t0, 8
    movi t2, 0x34567800
    ucmp t1, t2
    bne fail
.t44:
    movi a0, 44
    movi t1, 12
    srl t2, t0, t1
    movi t3, 0x12345
    ucmp t2, t3
    bne fail
    srli t2, t0, 12
    ucmp t2, t3
    bne fail
    srai t2, t0, 12
    ucmp t2, t3
    bne fail
    sra t2, t0, t1
    ucmp t2, t3
    bne fail
.t45:
    movi a0, 45
    movi t0, 0xcccccccc
    movi t1, 42
    movi t3, 0x333333
    movi t4, 0xfff33333
    srli t2, t0, 10
    ucmp t2, t3
    bne fail
    srl t2, t0, t1
    ucmp t2, t3
    bne fail
.t46:
    movi a0, 46
    srai t2, t0, 10
    ucmp t2, t4
    bne fail
    sra t2, t0, t1
    ucmp t2, t4
    bne fail
.t47:
    movi a0, 47
    movi t0, 0xaaaa
    movi t1, 5
    movi t3, 0x50000555
    rori t2, t0, 5
    ucmp t2, t3
    bne fail
    ror t2, t0, t1
    ucmp t2, t3
    bne fail
.t48:
    movi a0, 48
    neg t1, t1
    roli t2, t0, 27
    ucmp t2, t3
    bne fail
    rol t2, t0, t1
    ucmp t2, t3
    bne fail
.t49:
    movi a0, 49
    movi t0, 0x1234a688
    uxb t1, t0
    ucmpi t1, 0x88
    bne fail
    sxb t1, t0
    ucmpi t1, 0xffffff88
    bne fail
    uxh t1, t0
    ucmpi t1, 0xa688
    bne fail
    sxh t1, t0
    ucmpi t1, 0xffffa688
    bne fail
.t50:
    movi a0, 50
    rolmi t1, t0, 28, 24
    movi t2, 0x80000008
    ucmp t1, t2
    bne fail
    bfm t1, t0, 16, 8
    ucmpi t1, 0x00880000
    bne fail
.t51:
    movi a0, 51
    rormi t1, t0, 28, 24
    ucmpi t1, 0x81
    bne fail
    rorsmi t1, t0, 28, 24
    ucmpi t1, 0xffffff81
    bne fail
    ubfe t1, t0, 16, 8
    ucmpi t1, 0x34
    bne fail
    sbfe t1, t0, 4, 4
    ucmpi t1, 0xfffffff8
    bne fail
.t52:
    movi a0, 52
    movi t1, 1
    ucmpi zr, 1
    sellt t0, t1, zr
    ucmpi t0, 1
    bne fail
    ucmpi zr, 1
    selnl t0, t1, zr
    ucmpi t0, 0
    bne fail
.t53:
    movi a0, 53
    ucmpi zr, 1
    setlt t0
    ucmpi t0, 1
    bne fail
    ucmpi zr, 1
    setnl t0
    ucmpi t0, 0
    bne fail

    ; MEMORY
.t100:
    movi a0, 100
    adr t0, buffer
    movi t1, 0x89abcdef
    stw t1, (t0)
    ldw t2, (t0)
    ucmp t1, t2
    bne fail
.t101:
    movi a0, 101
    ldb t2, (t0)
    ucmpi t2, 0xef
    bne fail
    ldb t2, 1(t0)
    ucmpi t2, 0xcd
    bne fail
    ldb t2, 2(t0)
    ucmpi t2, 0xab
    bne fail
    ldb t2, 3(t0)
    ucmpi t2, 0x89
    bne fail
.t102:
    movi a0, 102
    ldh t2, (t0)
    ucmpi t2, 0xcdef
    bne fail
    ldh t2, 2(t0)
    ucmpi t2, 0x89ab
    bne fail
.t103:
    movi a0, 103
    ldbs t2, (t0)
    ucmpi t2, 0xffffffef
    bne fail
    ldhs t2, (t0)
    ucmpi t2, 0xffffcdef
    bne fail
.t104:
    movi a0, 104
    movi t1, 0xabcd
    stw zr, (t0)
    stb t1, (t0)
    ldw t2, (t0)
    ucmpi t2, 0xcd
    bne fail
    stw zr, (t0)
    stb t1, 1(t0)
    ldw t2, (t0)
    ucmpi t2, 0xcd00
    bne fail
    stw zr, (t0)
    stb t1, 2(t0)
    ldw t2, (t0)
    ucmpi t2, 0xcd0000
    bne fail
    stw zr, (t0)
    stb t1, 3(t0)
    ldw t2, (t0)
    ucmpi t2, 0xcd000000
    bne fail
.t105:
    movi a0, 105
    stw zr, (t0)
    sth t1, (t0)
    ldw t2, (t0)
    ucmpi t2, 0xabcd
    bne fail
    stw zr, (t0)
    sth t1, 2(t0)
    ldw t2, (t0)
    ucmpi t2, 0xabcd0000
    bne fail
.t106:
    movi a0, 106
    addi t1, t0, 256
    addi t2, t0, 128
    movi t3, 0x12345678
    stw t3, (t2)
    ldw t4, 128(t0)
    ucmp t3, t4
    bne fail
    ldw t4, -128(t1)
    ucmp t3, t4
    bne fail
.t107:
    movi a0, 107
    movi t1, 12
    movi t2, 0x12345678
    stb t2, 12(t0)
    ldbx t3, (t0, t1)
    ucmpi t3, 0x78
    bne fail
    sth t2, 12(t0)
    ldhx t3, (t0, t1)
    ucmpi t3, 0x5678
    bne fail
    stw t2, 12(t0)
    ldwx t3, (t0, t1)
    ucmp t3, t2
    bne fail
.t108:
    movi a0, 108
    stb t2, 12(t0)
    ldbx t3, (t0, t1, 1)
    ucmpi t3, 0x78
    bne fail
    sth t2, 24(t0)
    ldhx t3, (t0, t1, 2)
    ucmpi t3, 0x5678
    bne fail
    stw t2, 48(t0)
    ldwx t3, (t0, t1, 4)
    ucmp t3, t2
    bne fail
.t109:
    movi a0, 109
    movi t1, 0xcccccccc
    movi t2, 40
    stwx t1, (t0, t2)
    ldbsx t3, (t0, t2)
    ucmpi t3, 0xffffffcc
    bne fail
    ldhsx t3, (t0, t2)
    ucmpi t3, 0xffffcccc
    bne fail
.t110:
    movi a0, 110
    movi t0, 0x12340000
    movi t1, 3
    addx t2, (t0, t1, 2)
    sub t2, t2, t0
    ucmpi t2, 6
    bne fail
    addx t2, (t0, t1, 4)
    sub t2, t2, t0
    ucmpi t2, 12
    bne fail

    ; MISC
.t150:
    movi a0, 150
    scmpi zr, -1
    mfcr t0
    ucmpi t0, 0
    bne fail
    scmpi zr, 0
    mfcr t0
    ucmpi t0, 1
    bne fail
    scmpi zr, 1
    mfcr t0
    ucmpi t0, 2
    bne fail
.t151:
    movi a0, 151
    mtcr zr
    bng fail
    movi t0, 1
    mtcr t0
    bne fail
    movi t0, 2
    mtcr t0
    bnl fail
.t152:
    movi a0, 152
    
    mtio zr, TMRCNT
    mfsr t5, ie

    mtsr zr, scr
    movi t0, 2
    mtcr t0
    mtsr zr, sie
    movi t0, 1
    mtsr t0, ie
    scall 0x1234
..l1:
    bnl fail
    mfsr t0, elr
    adr t1, ..l1
    ucmp t0, t1
    bne fail
    mfsr t0, einfo
    ucmpi t0, 0x1234
    bne fail
    mfsr t0, scr
    ucmpi t0, 2
    bne fail
    mfsr t0, ie
    ucmpi t0, 1
    bne fail
    mfsr t0, sie
    ucmpi t0, 1
    bne fail
.t153:
    movi a0, 153
    udf
..l2:
    movi a0, 153
    mfsr t0, elr
    adr t1, ..l2
    ucmp t0, t1
    bne fail
    mfsr t0, einfo
    ucmpi t0, -1
    bne fail
    mtsr t5, ie
    movi t0, 0b1011
    mtio t0, TMRCNT
.t154:
    movi a0, 154
    movi t0, 0xabcd
    mtsr t0, elr
    mtsr t0, einfo
    mfsr t1, einfo
    mfsr t2, elr
    ucmpi t1, 0xabcd
    bne fail
    ucmpi t2, 0xabcd
    bne fail
.t155:
    movi a0, 155
    movi t0, 0
    scall 0
    addi t0, t0, 1
    addi t0, t0, 1
    addi t0, t0, 1
    ucmpi t0, 3
    bne fail
    jp $+12
    scall 0
    jp fail
.t156:
    movi a0, 156
    movi t0, 0
    mtcr t0
    bng fail
    movi t0, 2
    mtsr t0, scr
    adr t0, ..l1
    mtsr t0, elr
    eret
    jp fail
    jp fail
    jp fail
..l1:
    bnl fail

    
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

#align 32
buffer: #res 256

