#once
#include "rules.asm"

#const HALT = 0x0000
#const COUT = 0x0001
#const CLK = 0x0002
#const TMRCNT = 0x0003
#const TMRVAL = 0x0004

rst_vector:
    jp start
irq_vector:
    jp timer_handler
scall_vector:
    eret
udf_vector:
    jp udf_handler


start:
    movi sp, 0x10000
    jl setup_timer
    jl main
    mtio a0, HALT

divmod:
    ; a0 : dividend
    ; a1 : divisor
    ; return a0 : dividend/divisor
    ;        a1 : dividend%divisor
    xor t0, a0, a1
    tst a0, a0
    neg a2, a0
    movlt a0, a2
    tst a1, a1
    neg a2, a1
    movlt a1, a2
    ucmp a1, a0
    moveq a1, zr
    movgt a1, a0
    seteq a2
    movge a0, a2
    bge .divend
    tst a1, a1
    beq .divend
    mov a2, a1
.divloop1:
    slli a1, a1, 1
    ucmp a1, a0
    blt .divloop1
    movi a3, 0
.divloop2:
    ucmp a0, a1
    sub a4, a0, a1
    movge a0, a4
    setge a4
    slli a3, a3, 1
    or a3, a3, a4
    srli a1, a1, 1
    ucmp a1, a2
    bge .divloop2
    mov a1, a0
    mov a0, a3
.divend:
    tst t0, t0
    neg a2, a0
    movlt a0, a2
    neg a2, a1
    movlt a1, a2
    ret

puts:
    ldb t0, (a0)
    tst t0, t0
    beq .end
    mtio t0, COUT
    addi a0, a0, 1
    jp puts
.end:
    movi t0, "\n"
    mtio t0, COUT
    ret

hexdigit:
    ucmpi a0, 9
    addi a1, a0, "0"
    addi a2, a0, "a" - 10
    selgt a0, a2, a1
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

print_dec:
    stw lr, -4(sp)
    stw s0, -8(sp)
    stw s1, -12(sp)
    subi sp, sp, 24

    tst a0, a0
    neg a1, a0
    sellt s0, a1, a0
    bge .pos
    movi t0, "-"
    mtio t0, COUT
.pos:
    movi s1, 0
.digitloop:
    mov a0, s0
    movi a1, 10
    jl divmod
    mov s0, a0
    stbx a1, (sp, s1)
    ucmpi s0, 0
    beq .printloop
    addi s1, s1, 1
    jp .digitloop
.printloop:
    ldbx a0, (sp, s1)
    addi a0, a0, "0"
    mtio a0, COUT
    subi s1, s1, 1
    scmpi s1, 0
    bge .printloop

    addi sp, sp, 24
    ldw s1, -12(sp)
    ldw s0, -8(sp)
    ldw lr, -4(sp)
    ret

printf:
    stw a4, -4(sp)
    stw a3, -8(sp)
    stw a2, -12(sp)
    stw a1, -16(sp)
    stw lr, -20(sp)
    stw s0, -24(sp)
    stw s1, -28(sp)
    subi s1, sp, 16 ; argument array
    mov s0, a0 ; format string
    subi sp, sp, 28

.loop:
    ldb t0, (s0)
    tst t0, t0
    beq .end
    ucmpi t0, "%"
    bne .put
    addi s0, s0, 1
    ldb t0, (s0)
    ucmpi t0, "x"
    bne .notx
    ldw a0, (s1)
    addi s1, s1, 4
    jl print_hex
    addi s0, s0, 1
    jp .loop
.notx:
    ucmpi t0, "d"
    bne .notd
    ldw a0, (s1)
    addi s1, s1, 4
    jl print_dec
    addi s0, s0, 1
    jp .loop
.notd:
    movi t1, "%"
    mtio t1, COUT
.put:
    mtio t0, COUT
    addi s0, s0, 1
    jp .loop
.end:
    addi sp, sp, 28
    ldw s1, -28(sp)
    ldw s0, -24(sp)
    ldw lr, -20(sp)
    ret
    
timed:
    stw lr, -4(sp)
    stw s0, -8(sp)
    subi sp, sp, 8

    mov t0, a0
    mov a0, a1
    mov a1, a2
    mov a2, a3
    mov a3, a4

    mfio s0, CLK
    jlr t0
    mfio a1, CLK
    sub a1, a1, s0
    subi a1, a1, 3

    addi sp, sp, 8
    ldw s0, -8(sp)
    ldw lr, -4(sp)
    ret

udf_handler:
    stw lr, -4(sp)
    subi sp, sp, 4
    adr a0, .str0
    mfsr a1, einfo
    mfsr a2, elr
    subi a2, a2, 4
    jl printf
    addi sp, sp, 4
    ldw lr, -4(sp)
    eret
.str0: ds "undefined instruction %x at %x\n"

#align 32
setup_timer:
    movi t0, -500 
    mtio t0, TMRVAL
    movi t0, 0b1011 ; repeat, irq enable, timer enable
    mtio t0, TMRCNT
    mtsr t0, ie ; enable interrupts
    ret

timer_handler:
    stw a0, -4(sp)
    mfio a0, TMRCNT
    andni a0, a0, 0b100 ; acknowledge interrupt
    mtio a0, TMRCNT
    
    adr a0, user_timer_handler
    ldw a0, (a0)
    ucmp a0, zr
    beq .l1
    stw lr, -8(sp)
    subi sp, sp, 8
    jlr a0
    addi sp, sp, 8
    ldw lr, -8(sp)
.l1:
    ldw a0, -4(sp)
    eret

user_timer_handler:
    dw 0
