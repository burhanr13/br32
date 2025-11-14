  #include "defs.asm"
  #align 32
main:
  stw lr, -4(sp)
  subi sp, sp, 4
.B2:
  adr t0, __L2
  mov a0, t0
  jl printf
  movi t0, 0
  mov a0, t0
  addi sp, sp, 4
  ldw lr, -4(sp)
  ret

  #align 8
__L2:
  db 0x68
  db 0x65
  db 0x6c
  db 0x6c
  db 0x6f
  db 0x20
  db 0x77
  db 0x6f
  db 0x72
  db 0x6c
  db 0x64
  db 0
  #align 8
__L1:
  db 0x6d
  db 0x61
  db 0x69
  db 0x6e
  db 0
  #align 8
__L0:
  db 0x6d
  db 0x61
  db 0x69
  db 0x6e
  db 0
