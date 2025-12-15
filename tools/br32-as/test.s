addi t0, t1, 0x1234
subi t0, t1, 0x1234
addi t0, t1, 0x12345678
subi t0, t1, 12341234

andi t0, t1, 0x1234
ori t0, t1, 0x12340000
xori t0, t1, 0xffff1234
xori t0, t1, 0x1234ffff
andi t0, t1, 0x12345678
ori t0, t1, 0x12345678

movi t0, 0
movi t0, -1
movi t0, 0x12345678

scmpi t0, 0
ucmpi t0, 0
scmpi t0, 0x8000_0000
tsti t0, 0xfafaffff

jpr t0
jlr t0
ret

uxb t0, t1
sxb t0, t1
uxh t0, t1
sxh t0, t1
srli t0, t1, 10
slli t0, t1, 20
srai t0, t1, 5
rori t0, t1, 15
roli t0, t1, 1

add t0, t1, t2
and t0, t1, t2
or t0, t1, t2
xor t0, t1, t2
sub t0, t1, t2
andn t0, t1, t2
orn t0, t1, t2
xorn t0, t1, t2
srl t0, t1, t2
sll t0, t1, t2
sra t0, t1, t2
ror t0, t1, t2
rol t0, t1, t2
tst a0, a1
ucmp s0, s1
scmp sp, lr
tstn fp, sp
mov r0, r1
not r0, r1
neg a0, a1
nop

selgt a0, a1, a2
moveq a0, a1
setlt a0

ldb t0, (t1)
ldbs t0, 1(t1)
stb t0, 0x7fff(t1)
ldh t0, -4(t1)
ldhs t0, -10(t1)
sth t0, 2(t1)
ldw lr, -4(sp)
stw lr, -4(sp)

ldbx t0, (t1, t2)
ldbsx t0, (t1, t2, 1)
stbx t0, (t1, t2)
ldhx t0, (t1, t2, 2)
ldhsx t0, (t1, t2)
sthx t0, (t1, t2, 2)
ldwx t0, (t1, t2)
stwx t0, (t1, t2, 4)

addx t0, (t1, t2, 1)
addx t0, (t1, t2, 2)
addx t0, (t1, t2, 4)

movi t0, (~0<<16^2<<3+4*5)+(1<<16)

.set IO_SIODAT, 0x1011
mtio t0, IO_SIODAT

.string "abcd"
.align 4
mfio t0, IO_SIODAT-1

scall 0x1234
eret
mfsr t0, elr
mtsr zr, ie
mfcr t0
mtcr t0
udf

l1:
jp .1
.1:
jp .2
.2:
bne .1
l2:
jp .1
.1:
jp .2
.2:
jl l1

l3:
.word l1
.word l2+4
.word .-l3
.word l4-l3

l4:
adr t0, .
adr t0, .-10
adr t0, .+4
jp .+4
jp .-20
jp l4


.include "test.inc"

movi a0, A+B+C
