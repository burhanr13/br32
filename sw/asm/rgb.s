.set CLKSPEED, 27_000_000

.set LED, 0x1000
.set RGBLED, 0x1001

start:
    movi s0, 0
    adr s1, colors
.loop:
    ldwx t0, (s1, s0, 4)
    srli t0, t0, 2
    andni t0, t0, 0x3030
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
    .word 0x1e64ff
    .word 0xff641e
    .word 0x64ff1e
    .word 0x641eff
    .word 0xff1e64
    .word 0x1eff64
