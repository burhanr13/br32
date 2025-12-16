.include "constants.inc"

rst_vector:
    jp start
irq_vector:
    jp timer_handler
scall_vector:
    eret
udf_vector:
    jp udf_handler

    .global start
start:
    movi sp, 0x10000
    jl main
    mtio a0, HALT
    jp .

    .global __mul
__mul:
    movi a2, 0
.mulloop:
    ucmpi a0, 0
    beq .mulend
    tsti a0, 1
    add a3, a2, a1
    movne a2, a3
    srli a0, a0, 1
    slli a1, a1, 1
    jp .mulloop
.mulend:
    mov a0, a2
    ret

    .global __div
__div:
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

    .global __mod
__mod:
    stw lr, -4(sp)
    subi sp, sp, 4
    jl __div
    mov a0, a1
    addi sp, sp, 4
    ldw lr, -4(sp)
    ret

    .global putc
putc:
    mtio a0, SIODAT
.wait:
    mfio a0, SIOCNT
    tsti a0, 1
    bne .wait
    ret

    .global puts
puts:
    stw lr, -4(sp)
    subi sp, sp, 4
    mov t0, a0
.loop:
    ldb a0, (t0)
    tst a0, a0
    beq .end
    jl putc
    addi t0, t0, 1
    jp .loop
.end:
    movi a0, '\n'
    jl putc
    addi sp, sp, 4
    ldw lr, -4(sp)
    ret

hexdigit:
    ucmpi a0, 9
    addi a1, a0, '0'
    addi a2, a0, 'a' - 10
    selgt a0, a2, a1
    ret

print_hex:
    stw lr, -4(sp)
    mov t0, a0
    ubfe a0, t0, 28, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 24, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 20, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 16, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 12, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 8, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 4, 4
    jl hexdigit
    jl putc
    ubfe a0, t0, 0, 4
    jl hexdigit
    jl putc
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
    movi a0, '-'
    jl putc
.pos:
    movi s1, 0
.digitloop:
    mov a0, s0
    movi a1, 10
    jl __div
    mov s0, a0
    stbx a1, (sp, s1)
    ucmpi s0, 0
    beq .printloop
    addi s1, s1, 1
    jp .digitloop
.printloop:
    ldbx a0, (sp, s1)
    addi a0, a0, '0'
    jl putc
    subi s1, s1, 1
    scmpi s1, 0
    bge .printloop

    addi sp, sp, 24
    ldw s1, -12(sp)
    ldw s0, -8(sp)
    ldw lr, -4(sp)
    ret

    .global printf
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
    ldb a0, (s0)
    tst a0, a0
    beq .end
    ucmpi a0, '%'
    bne .put
    addi s0, s0, 1
    ldb t0, (s0)
    ucmpi t0, 'x'
    bne .notx
    ldw a0, (s1)
    addi s1, s1, 4
    jl print_hex
    addi s0, s0, 1
    jp .loop
.notx:
    ucmpi t0, 'd'
    bne .notd
    ldw a0, (s1)
    addi s1, s1, 4
    jl print_dec
    addi s0, s0, 1
    jp .loop
.notd:
    mov t0, a0
    movi a0, '%'
    jl putc
    mov a0, t0
.put:
    jl putc
    addi s0, s0, 1
    jp .loop
.end:
    addi sp, sp, 28
    ldw s1, -28(sp)
    ldw s0, -24(sp)
    ldw lr, -20(sp)
    ret
    
    .global timed
timed:
    stw lr, -4(sp)
    stw s0, -8(sp)
    subi sp, sp, 8

    mov t0, a0
    mov a0, a1
    mov a1, a2
    mov a2, a3
    mov a3, a4

    mfsr s0, sysclk
    jlr t0
    mfsr a1, sysclk
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
.str0: .string "undefined instruction %x at %x\n"

    .align 4
setup_timer:
    movi t0, -500 
    mtio t0, TMRVAL
    movi t0, 0b1011 ; repeat, irq enable, timer enable
    mtio t0, TMRCNT
    mtsr t0, ie ; enable interrupts
    ret

    .global set_timer
set_timer: ; void set_timer(int period, bool repeat, bool enableIrq)
    slli t0, a1, 3
    slli a2, a2, 1
    or t0, t0, a2
    ori t0, t0, 1
    neg a0, a0
    mtio a0, TMRVAL
    mtio t0, TMRCNT
    ret

    .global stop_timer
stop_timer:
    mtio zr, TMRCNT
    ret

    .global delay
delay:
    mfsr t0, sysclk
    add a0, a0, t0
.loop:
    mfsr t0, sysclk
    ucmp t0, a0
    blt .loop
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

    .global user_timer_handler
user_timer_handler:
    .res 4
