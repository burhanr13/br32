    .global main
main:
    stw lr, -4(sp)
    subi sp, sp, 4

    adr a0, .str
    jl puts

    ldw lr, (sp)
    addi sp, sp, 4
    ret 

.str: .string "hello world\n"
