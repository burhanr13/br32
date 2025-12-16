  .align 4
  .global cond
cond:
.B0:
  ucmpi a0, 0
  beq .B9
.B5:
  mov a3, a1
  jp .B13
.B9:
  mov a3, a2
.B13:
  mov a0, a3
.B16:
  ret

  .align 4
  .global aaaa
aaaa:
.B0:
  mov a2, zr
  ucmpi a0, 0
  beq .B13
.B7:
  ucmpi a1, 0
  setne a2
.B13:
  mov a0, a2
.B16:
  ret

  .align 4
  .global dummy
dummy:
.B0:
  mov a0, zr
.B2:
  ret

  .align 4
  .global xxxx
xxxx:
  stw lr, -4(sp)
  stw s0, -8(sp)
  subi sp, sp, 8
  mov s0, a0
.B0:
.B1:
  ucmpi s0, 0
  bne .B19
.B6:
  ucmpi s0, 0
  beq .B22
.B11:
  ucmpi s0, 0
  beq .B19
.B16:
  jl dummy
  jp .B11
.B19:
  jl dummy
  jp .B27
.B22:
  jl dummy
  jl dummy
  jp .B1
.B27:
  addi sp, sp, 8
  ldw s0, -8(sp)
  ldw lr, -4(sp)
  ret

  .align 4
  .global bbbbbb
bbbbbb:
.B0:
  movi a0, 1
  movi a1, 2
  stb a1, -1(fp)
  movi a1, 3
  stb a1, 0(fp)
  sxb a0, a0
.B14:
  ret

  .align 4
  .global send
send:
.B0:
  addi a4, a2, 7
  srai a3, a4, 3
  andi a4, a2, 0x7
  ucmpi a4, 8
  bge .B91
  adr t0, .switch_B0
  ldwx t1, (t0, a4, 4)
  add t0, t0, t1
  jpr t0
.switch_B0:
  .word .B82-.switch_B0
  .word .B66-.switch_B0
  .word .B57-.switch_B0
  .word .B48-.switch_B0
  .word .B39-.switch_B0
  .word .B30-.switch_B0
  .word .B21-.switch_B0
  .word .B12-.switch_B0
.B12:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
.B21:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
.B30:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
.B39:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
.B48:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
.B57:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
.B66:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
  subi a3, a3, 1
  scmpi a3, 0
  ble .B91
.B82:
  mov a4, a1
  addi a1, a4, 2
  ldh a4, (a4)
  sth a4, (a0)
  jp .B12
.B91:
  ret

  .align 4
  .global word
word:
.B0:
  ucmpi a0, 11
  bge .B9
  adr a1, .switch_B0
  ldwx a2, (a1, a0, 4)
  add a1, a1, a2
  jpr a1
.switch_B0:
  .word .B3-.switch_B0
  .word .B5-.switch_B0
  .word .B7-.switch_B0
  .word .B9-.switch_B0
  .word .B9-.switch_B0
  .word .B9-.switch_B0
  .word .B9-.switch_B0
  .word .B9-.switch_B0
  .word .B11-.switch_B0
  .word .B13-.switch_B0
  .word .B15-.switch_B0
.B3:
  adr a0, __L24
  jp .B17
.B5:
  adr a0, __L26
  jp .B17
.B7:
  adr a0, __L28
  jp .B17
.B9:
  adr a0, __L36
  jp .B17
.B11:
  adr a0, __L30
  jp .B17
.B13:
  adr a0, __L32
  jp .B17
.B15:
  adr a0, __L34
.B17:
  ret

  .align 4
  .global strcpy
strcpy:
.B0:
.B1:
  ldb a2, (a1)
  ucmpi a2, 0
  beq .B19
.B7:
  mov a2, a1
  addi a1, a2, 1
  mov a3, a0
  addi a0, a3, 1
  ldb a2, (a2)
  stb a2, (a3)
  jp .B1
.B19:
  ret

  .align 4
  .global main
main:
.B0:
  mov a0, zr
.B2:
  ret

__L0:
  .string "cond"
__L1:
  .string "aaaa"
__L2:
  .string "dummy"
__L3:
  .string "xxxx"
__L8:
  .string "bbbbbb"
__L9:
  .string "send"
__L21:
  .string "word"
__L24:
  .string "zero"
__L26:
  .string "one"
__L28:
  .string "two"
__L30:
  .string "eight"
__L32:
  .string "nine"
__L34:
  .string "ten"
__L36:
  .string "i cant count that high"
__L37:
  .string "strcpy"
__L40:
  .string "main"
