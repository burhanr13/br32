#subruledef reg {
    zr => 0`5
    sp => 1`5
    a{ai: u5} => {assert(ai < 8), (2+ai)`5}
    t{ti: u5} => {assert(ti < 7), (10+ti)`5}
    s{si: u5} => {assert(si < 14), (17+si)`5}
    lr => 31`5
    r{ri: u5} => {assert(ri != 0, "access zero register with zr"), ri}
}

#subruledef logic_imm {
    andi => 0x11
    ori => 0x12
    xori => 0x13
}

#subruledef cmp_imm {
    scmpi => 0x04
    ucmpi => 0x05
}

#subruledef rotm_imm {
    rormi => 0x00
    rolmi => 0x04
    rorsmi => 0x08
}

#subruledef imm16 {
    {i} => {
        i = i`32
        assert(i[31:16] == 0, "invalid immediate")
        i[15:0]
    }
}
#subruledef imm16h {
    {i} => {
        i = i`32
        assert(i[15:0] == 0, "invalid immediate")
        assert(i[31:16] != 0)
        i[31:16]
    }
}
#subruledef imm16n {
    {i} => {
        i = !i`32
        assert(i[31:16] == 0, "invalid immediate")
        assert(i[15:0] != 0xffff)
        i[15:0]
    }
}
#subruledef imm16hn {
    {i} => {
        i = !i`32
        assert(i[15:0] == 0, "invalid immediate")
        assert(i[31:16] != 0xffff)
        assert(i[31:16] != 0)
        i[31:16]
    }
}
#subruledef imm16m {
    {i} => {
        i = -i`32
        assert(i[31:16] == 0, "invalid immediate")
        assert(i != 0)
        i[15:0]
    }
}
#subruledef imm16hm {
    {i} => {
        i = -i`32
        assert(i[15:0] == 0, "invalid immediate")
        assert(i[31:16] != 0)
        i[31:16]
    }
}

#subruledef br_imm {
    bgt => 0x8
    ble => 0x9
    beq => 0xa
    bne => 0xb
    blt => 0xc
    bge => 0xd
    jp => 0xe
    jl => 0xf
}

#subruledef br_reg {
    jpr => 0x10
    jlr => 0x11
}

#subruledef jmpdst {
    {i} => {
        off = i - $
        assert(off & 3 == 0, "misaligned branch")
        assert(-(1<<27) <= off && off < 1<<27, "branch too far")
        off[27:2]
    }
}

#subruledef alu_reg {
    add => 0x00
    and => 0x01
    or => 0x02
    xor => 0x03
    sub => 0x04
    andn => 0x05
    orn => 0x06
    xorn => 0x07
    srl => 0x10
    sll => 0x11
    sra => 0x12
    ror => 0x14
    rol => 0x15
}

#subruledef cmp_reg {
    tst => 0x22
    scmp => 0x24
    ucmp => 0x25
    tstn => 0x26
}

#ruledef rules {
    {op:br_imm} {i:jmpdst} => le(i @ 0b00 @ op`4)

    addi {rd:reg}, {ra:reg}, {i:imm16} => le(i @ ra @ rd @ 0x10`6)
    addi {rd:reg}, {ra:reg}, {i:imm16m} => le(i @ ra @ rd @ 0x14`6)
    addi {rd:reg}, {ra:reg}, {i:imm16h} => le(i @ ra @ rd @ 0x18`6)
    {op:logic_imm} {rd:reg}, {ra:reg}, {i:imm16} => le(i @ ra @ rd @ op`6)
    {op:logic_imm} {rd:reg}, {ra:reg}, {i:imm16n} => le(i @ ra @ rd @ (op | 0x4)`6)
    {op:logic_imm} {rd:reg}, {ra:reg}, {i:imm16h} => le(i @ ra @ rd @ (op | 0x8)`6)
    {op:logic_imm} {rd:reg}, {ra:reg}, {i:imm16hn} => le(i @ ra @ rd @ (op | 0xc)`6)
    subi {rd:reg}, {ra:reg}, {i} => asm {addi {rd}, {ra}, -{i}}
    andni {rd:reg}, {ra:reg}, {i} => asm {andi {rd}, {ra}, !{i}}
    
    movi {rd:reg}, {i:imm16} => asm {ori {rd}, zr, {i}}
    movi {rd:reg}, {i:imm16n} => asm {ori {rd}, zr, {i}}
    movi {rd:reg}, {i:imm16h} => asm {ori {rd}, zr, {i}}
    movi {rd:reg}, {i:imm16hn} => asm {ori {rd}, zr, {i}}
    movi {rd:reg}, {i} => asm {
        ori {rd}, zr, {i}[31:16] << 16
        ori {rd}, {rd}, {i}[15:0]
    }

    {op:cmp_imm} {ra:reg}, {i:imm16} => le(i @ ra @ op`5 @ 0b111000)
    {op:cmp_imm} {ra:reg}, {i:imm16m} => le(i @ ra @ (op ^ 0x4)`5 @ 0b111000)
    {op:cmp_imm} {ra:reg}, {i:imm16hm} => le(i @ ra @ (op | 0x8)`5 @ 0b111000)
    tsti {ra:reg}, {i:imm16} => le(i @ ra @ 0x2`5 @ 0b111000)
    tsti {ra:reg}, {i:imm16n} => le(i @ ra @ 0x6`5 @ 0b111000)
    tsti {ra:reg}, {i:imm16h} => le(i @ ra @ 0xa`5 @ 0b111000)
    tsti {ra:reg}, {i:imm16hn} => le(i @ ra @ 0xe`5 @ 0b111000)

    {op:br_reg} {ra:reg} => le(0`16 @ ra @ op`5 @ 0b111000)
    ret => asm {jpr lr}

    {op:rotm_imm} {rd:reg}, {ra:reg}, {i1:u5}, {i2:u5} => le(op`6 @ i2 @ i1 @ ra @ rd @ 0b111001)
    ubfe {rd:reg}, {ra:reg}, {lo}, {sz} => {assert(lo+sz <= 32, "invalid bitfield"), asm {rormi {rd}, {ra}, {lo}, 32-{sz}}}
    sbfe {rd:reg}, {ra:reg}, {lo}, {sz} => {assert(lo+sz <= 32, "invalid bitfield"), asm {rorsmi {rd}, {ra}, {lo}, 32-{sz}}}
    bfm {rd:reg}, {ra:reg}, {lo}, {sz} => {assert(lo+sz <= 32, "invalid bitfield"), asm {rolmi {rd}, {ra}, {lo}, 32-{sz}}}
    uxb {rd:reg}, {ra:reg} => asm {ubfe {rd}, {ra}, 0, 8}
    sxb {rd:reg}, {ra:reg} => asm {sbfe {rd}, {ra}, 0, 8}
    uxh {rd:reg}, {ra:reg} => asm {ubfe {rd}, {ra}, 0, 16}
    sxh {rd:reg}, {ra:reg} => asm {sbfe {rd}, {ra}, 0, 16}
    srli {rd:reg}, {ra:reg}, {i} => asm {rormi {rd}, {ra}, {i}, {i}}
    slli {rd:reg}, {ra:reg}, {i} => asm {rolmi {rd}, {ra}, {i}, {i}}
    srai {rd:reg}, {ra:reg}, {i} => asm {rorsmi {rd}, {ra}, {i}, {i}}
    rori {rd:reg}, {ra:reg}, {i} => asm {rormi {rd}, {ra}, {i}, 0}
    roli {rd:reg}, {ra:reg}, {i} => asm {rolmi {rd}, {ra}, {i}, 0}

    {op:alu_reg} {rd:reg}, {ra:reg}, {rb:reg} => le(op`11 @ rb @ ra @ rd @ 0b111110)
    {op:cmp_reg} {ra:reg}, {rb:reg} => le(op`11 @ rb @ ra @ 0`5 @ 0b111110)
    mov {rd:reg}, {rb:reg} => asm {or {rd}, zr, {rb}}
    not {rd:reg}, {rb:reg} => asm {orn {rd}, zr, {rb}}
    neg {rd:reg}, {rb:reg} => asm {sub {rd}, zr, {rb}}
    nop => asm {mov zr, zr}
}

