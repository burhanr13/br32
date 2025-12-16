
.set CLKSPEED, 27_000_000

.set LED, 0x1000

start:
    movi s0, 0
.loop:
    mtio s0, LED
    addi s0, s0, 1
    movi a0, CLKSPEED / 2
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

