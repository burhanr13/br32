  #align 32
qqq:
.B0:
  andi a1, a0, 0x400
  ucmpi a1, 0
  bne .B9
.B7:
  mov a0, zr
  jp .B11
.B9:
  movi a0, 1
.B11:
  ret

  #align 32
lol:
.B0:
  movi a0, 5
.B2:
  ret

  #align 32
main:
  stw lr, -4(sp)
  stw s0, -8(sp)
  stw s1, -12(sp)
  subi sp, sp, 12
.B0:
  movi a0, 69
  jl aaa
  mov s1, a0
  movi a0, 420
  jl aaa
  mov a1, a0
  mov a0, s1
  jl bbb
  mov s0, a0
  mov a0, zr
.B11:
  addi sp, sp, 12
  ldw s1, -12(sp)
  ldw s0, -8(sp)
  ldw lr, -4(sp)
  ret

  #align 32
bbb:
.B0:
  addi a2, a0, 4
  add a0, a2, a1
.B5:
  ret

  #align 32
aaa:
.B0:
  scmpi a0, 2
  blt .B10
.B5:
  subi a0, a0, 10
  jp .B15
.B10:
  addi a0, a0, 5
.B15:
  ret

  #align 32
ddd:
.B0:
  ldb a4, (a0)
  ldh t0, (a2)
  add a4, a4, t0
  ldbs t0, (a1)
  add a4, a4, t0
  ldhs t0, (a3)
  add a0, a4, t0
.B20:
  ret

__L11:
  ds "qqq"
__L10:
  ds "qqq"
__L9:
  ds "lol"
__L8:
  ds "lol"
__L7:
  ds "main"
__L6:
  ds "main"
__L5:
  ds "bbb"
__L4:
  ds "bbb"
__L3:
  ds "aaa"
__L2:
  ds "aaa"
__L1:
  ds "ddd"
__L0:
  ds "ddd"
