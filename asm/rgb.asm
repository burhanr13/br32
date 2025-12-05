#include "rules.asm"

#const CLKSPEED = 27_000_000

#const LED = 0x1000
#const RGBLED = 0x1001

start:
    movi s0, 0
    adr s1, colors
.loop:
    ldwx t0, (s1, s0, 4)
    srli t0, t0, 1
    andni t0, t0, 0x1010
    ori t0, t0, 1<<24
    mtio t0, RGBLED
    addi s0, s0, 1
    ucmpi s0, 6
    movge s0, zr
    movi a0, CLKSPEED
    jl delay
    jp .loop

delay:
    mfsr t0, sysclk
    add a0, a0, t0
.loop:
    mfsr t0, sysclk
    ucmp t0, a0
    blt .loop
    ret

colors:
    dw 0x1e64ff
    dw 0xff641e
    dw 0x64ff1e
    dw 0x641eff
    dw 0xff1e64
    dw 0x1eff64
