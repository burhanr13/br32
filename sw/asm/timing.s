    .global main
main:
    stw lr, -4(sp)
    subi sp, sp, 4

    adr a0, nothing
    jl timed
    adr a0, s1
    jl printf

    adr a0, something
    jl timed
    adr a0, s2
    jl printf

    adr a0, mem
    jl timed
    adr a0, s3
    jl printf

    adr a0, systemcall
    jl timed
    adr a0, s3
    jl printf

    addi sp, sp, 4
    ldw lr, -4(sp)
    ret

nothing:
    ret

something:
    movi a0, 0
    movi a1, 100
    movi a2, 0
.loop:
    ucmp a2, a1
    bge .end
    addi a2, a2, 1
    add a0, a0, a2
    jp .loop
.end:
    ret

mem:
    ldw a0, (sp) ; 2
    addi a0, a0, 1 ; 2
    ldb a0, (sp) ; 2
    movi a1, 2 ; 1
    sub a0, a0, a1 ; 1
    sth a0, -2(sp) ; 2
    addi a0, a0, 1 ; 1
    ldb a0, (sp) ; 2
    stb a0, -2(sp) ; 2
    jp .+8 ; 2
    ldw a0, (sp) ; 0
    add a0, a0, a1 ; 1
    ldw zr, (sp) ; 2
    mov a0, zr ; 1
    ucmpi zr, 1 ; 1
    jp .+8 ; 2
    ucmpi zr, 0 ; 0
    bne .+16 ; 2
    ldw a0, (a0) ; 0
    ldw a0, (a0) ; 0
    ldw a0, (a0) ; 0
    ret ; 2

systemcall:
    scall 0
    ret

s1: .string "nothing takes %d\n"
s2: .string "something takes %d\n"
s3: .string "%d\n"
