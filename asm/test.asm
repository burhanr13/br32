#include "rules.asm"

#include "defs.asm"

main:
    stw lr, -4(sp)
    ldw lr, -4(sp)
    ret

