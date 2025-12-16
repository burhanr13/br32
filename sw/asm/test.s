    .global main
main:
    stw lr, -4(sp)
    subi sp, sp, 8
    movi t0, 1
    mtsr t0, ie
    mtsr t0, sie
    mtsr t0, scr
    movi t0, 0x1234
    mtsr t0, elr
    mtsr t0, einfo

    adr a0, .str
    mfsr a1, ie
    mfsr a2, sie
    mfsr a3, scr
    mfsr a4, elr
    mfsr t0, einfo
    stw t0, (sp)
    jl printf
    addi sp, sp, 8
    ldw lr, -4(sp)
    ret
.str: .string "%x %x %x %x %x"
