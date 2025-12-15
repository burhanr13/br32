use std::{
    fs::File,
    io::{BufReader, Write},
    mem,
    path::Path,
};

use crate::{State, tokenize::Token};

pub struct Sym {
    addr: usize,
    name: String,
}

#[derive(PartialEq)]
enum PatchKind {
    Jmp26,
    Adr21,
    Abs32,
    Rel32,
}

pub struct Patch {
    kind: PatchKind,
    file: String,
    line: u32,
    addr: usize,
    sym: String,
    addend: i32,
}

#[macro_export]
macro_rules! error {
    ($s:expr, $m:expr $(,$args:expr)*) => {
        panic!(concat!("assembler error at {}:{}: ", $m), $s.file, $s.line $(,$args)*)
    };
}

macro_rules! check {
    ($s:expr) => {
        None
    };
    ($s:expr, $t:ident $(($v:tt))? $(, $ts:ident)*) => {
        if matches!($s.nexttok, Some(Token::$t $(($v))?)) {
            $s.advance()
        } else {
            check!($s $(,$ts)*)
        }
    };
}

macro_rules! expect {
    ($s:expr, $t:ident $(($v:tt))?) => {
        if let Some(Token::$t$(($v))?) = $s.advance() {
            $($v)?
        } else {error!($s, "expected {}", stringify!($t));}
    };
}

fn sreg_of_str(x: &str) -> Option<u32> {
    Some(match x {
        "sysclk" => 0x0000,
        "ie" => 0x1000,
        "sie" => 0x1001,
        "scr" => 0x1002,
        "elr" => 0x1003,
        "einfo" => 0x1004,
        _ => return None,
    })
}

impl State {
    fn advance(&mut self) -> Option<Token> {
        let t = self.nexttok.take();
        self.nexttok = self.next_token();
        if t == Some(Token::NewLine) {
            self.line += 1
        };
        t
    }

    fn reg(&mut self) -> u32 {
        let rn = expect!(self, Ident(rn));
        match rn.as_str() {
            "zr" => 0,
            "sp" => 1,
            "fp" => 30,
            "lr" => 31,
            _ => {
                if let Ok(n) = rn[1..].parse::<u32>() {
                    match &rn[..1] {
                        "r" => {
                            if n < 32 {
                                return n;
                            }
                        }
                        "a" => {
                            if n < 5 {
                                return 2 + n;
                            }
                        }
                        "t" => {
                            if n < 10 {
                                return 7 + n;
                            }
                        }
                        "s" => {
                            if n < 14 {
                                return 17 + n;
                            }
                        }
                        _ => {}
                    }
                }
                error!(self, "unknown register {}", rn);
            }
        }
    }

    fn expr_primary(&mut self) -> u32 {
        if check!(self, Sub).is_some() {
            self.expr_primary().wrapping_neg()
        } else if check!(self, Not).is_some() {
            !self.expr_primary()
        } else if check!(self, LParen).is_some() {
            let i = self.expr();
            expect!(self, RParen);
            i
        } else if let Some(Token::IntLit(i)) = check!(self, IntLit(_)) {
            i
        } else if let Some(Token::Ident(x)) = check!(self, Ident(_)) {
            if let Some(&v) = self.constants.get(&x) {
                v
            } else {
                error!(self, "unexpected label or undefined constant '{}'", x)
            }
        } else {
            error!(self, "expected constant expression")
        }
    }

    fn expr_prod(&mut self) -> u32 {
        let mut i = self.expr_primary();
        while let Some(t) = check!(self, Mul, Div, Mod) {
            let rhs = self.expr_primary();
            match t {
                Token::Mul => i *= rhs,
                Token::Div => i /= rhs,
                Token::Mod => i %= rhs,
                _ => unreachable!(),
            }
        }
        i
    }

    fn expr_sum2(&mut self, mut i: u32) -> u32 {
        while let Some(t) = check!(self, Add, Sub) {
            let rhs = self.expr_prod();
            match t {
                Token::Add => i += rhs,
                Token::Sub => i -= rhs,
                _ => unreachable!(),
            }
        }
        i
    }

    fn expr_sum(&mut self) -> u32 {
        let i = self.expr_prod();
        self.expr_sum2(i)
    }

    fn expr_shift(&mut self) -> u32 {
        let mut i = self.expr_sum();
        while let Some(t) = check!(self, Shl, Shr) {
            let rhs = self.expr_sum();
            match t {
                Token::Shl => i <<= rhs,
                Token::Shr => i >>= rhs,
                _ => unreachable!(),
            }
        }
        i
    }

    fn expr_bitwise(&mut self) -> u32 {
        let mut i = self.expr_shift();
        while let Some(t) = check!(self, And, Or, Xor) {
            let rhs = self.expr_shift();
            match t {
                Token::And => i &= rhs,
                Token::Or => i |= rhs,
                Token::Xor => i ^= rhs,
                _ => unreachable!(),
            }
        }
        i
    }

    fn expr(&mut self) -> u32 {
        self.expr_bitwise()
    }

    fn check_label(&mut self) -> bool {
        if let Some(Token::Ident(x)) = self.nexttok.as_ref()
            && !self.constants.contains_key(x)
        {
            true
        } else {
            false
        }
    }

    fn label_expr(&mut self, mut k: PatchKind) -> Patch {
        if !self.check_label() {
            error!(self, "expected label");
        }
        let Some(Token::Ident(l)) = self.advance() else {
            unreachable!()
        };
        let mut addend: i32 = 0;
        if let Some(t) = check!(self, Add, Sub) {
            match t {
                Token::Add => {
                    addend += self.expr() as i32;
                }
                Token::Sub => {
                    if let Some(Token::Ident(x)) = self.nexttok.as_ref()
                        && !self.constants.contains_key(x)
                        && k == PatchKind::Abs32
                        && let Some(sa) = self.sym_addr(x)
                    {
                        self.advance();
                        k = PatchKind::Rel32;
                        addend -= sa as i32;
                    } else {
                        addend -= self.expr_prod() as i32;
                    }
                    addend = self.expr_sum2(addend as u32) as i32;
                }
                _ => unreachable!(),
            }
        }
        Patch {
            file: self.file.clone(),
            line: self.line,
            kind: k,
            addr: self.code.len(),
            sym: l,
            addend,
        }
    }

    fn sreg(&mut self) -> u32 {
        if let Some(Token::Ident(x)) = self.nexttok.as_ref()
            && let Some(i) = sreg_of_str(x)
        {
            self.advance();
            i
        } else {
            self.expr()
        }
    }

    fn parse_rri(&mut self) -> (u32, u32, u32) {
        let rd = self.reg();
        expect!(self, Comma);
        let ra = self.reg();
        expect!(self, Comma);
        let i = self.expr();
        (rd, ra, i)
    }

    fn parse_ri(&mut self) -> (u32, u32) {
        let ra = self.reg();
        expect!(self, Comma);
        let i = self.expr();
        (ra, i)
    }

    fn parse_rrii(&mut self) -> (u32, u32, u32, u32) {
        let rd = self.reg();
        expect!(self, Comma);
        let ra = self.reg();
        expect!(self, Comma);
        let i1 = self.expr();
        expect!(self, Comma);
        let i2 = self.expr();
        (rd, ra, i1, i2)
    }

    fn parse_rrr(&mut self) -> (u32, u32, u32) {
        let rd = self.reg();
        expect!(self, Comma);
        let ra = self.reg();
        expect!(self, Comma);
        let rb = self.reg();
        (rd, ra, rb)
    }

    fn parse_rr(&mut self) -> (u32, u32) {
        let ra = self.reg();
        expect!(self, Comma);
        let rb = self.reg();
        (ra, rb)
    }

    fn parse_mem(&mut self) -> (u32, u32, u32) {
        let rt = self.reg();
        expect!(self, Comma);
        let i;
        if check!(self, LParen).is_some() {
            i = 0;
        } else {
            i = self.expr();
            expect!(self, LParen);
        }
        let ra = self.reg();
        expect!(self, RParen);
        (rt, ra, i)
    }

    fn parse_memx(&mut self) -> (u32, u32, u32, u32) {
        let rt = self.reg();
        expect!(self, Comma);
        expect!(self, LParen);
        let ra = self.reg();
        expect!(self, Comma);
        let rb = self.reg();
        let i = if check!(self, Comma).is_some() {
            self.expr()
        } else {
            1
        };
        expect!(self, RParen);
        (rt, ra, rb, i)
    }

    fn parse(&mut self, file: &str) {
        self.file = file.to_string();
        self.line = 0;
        let Ok(fp) = File::open(&self.file).map(BufReader::new) else {
            error!(self, "cannot open file")
        };
        self.fp = Some(fp);

        self.advance();
        while self.nexttok.is_some() {
            if check!(self, NewLine).is_some() {
                continue;
            }
            let id = expect!(self, Ident(id));

            match id.as_str() {
                "addi" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.add_imm(rd, ra, i)
                }
                "subi" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.add_imm(rd, ra, i.wrapping_neg())
                }
                "andi" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.logic_imm(0x11, rd, ra, i);
                }
                "andni" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.logic_imm(0x11, rd, ra, !i);
                }
                "ori" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.logic_imm(0x12, rd, ra, i);
                }
                "xori" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.logic_imm(0x13, rd, ra, i);
                }
                "movi" => {
                    let (rd, i) = self.parse_ri();
                    self.logic_imm(0x12, rd, 0, i);
                }
                "scmpi" => self.cmp_imm(4),
                "ucmpi" => self.cmp_imm(5),
                "tsti" => self.tst_imm(),

                "jpr" => {
                    let rd = self.reg();
                    self.emit_ri(0x10, rd, 0);
                }
                "jlr" => {
                    let rd = self.reg();
                    self.emit_ri(0x11, rd, 0);
                }
                "ret" => self.emit_ri(0x10, 31, 0),

                "rormi" => {
                    let (rd, ra, i1, i2) = self.parse_rrii();
                    self.emit_rrii(0, rd, ra, i1, i2);
                }
                "rolmi" => {
                    let (rd, ra, i1, i2) = self.parse_rrii();
                    self.emit_rrii(4, rd, ra, i1, i2);
                }
                "rorsmi" => {
                    let (rd, ra, i1, i2) = self.parse_rrii();
                    self.emit_rrii(8, rd, ra, i1, i2);
                }
                "ubfe" => {
                    let (rd, ra, i1, i2) = self.parse_rrii();
                    self.emit_rrii(0, rd, ra, i1, 32 - i2);
                }
                "sbfe" => {
                    let (rd, ra, i1, i2) = self.parse_rrii();
                    self.emit_rrii(8, rd, ra, i1, 32 - i2);
                }
                "uxb" => {
                    let (rd, ra) = self.parse_rr();
                    self.emit_rrii(0, rd, ra, 0, 24);
                }
                "uxh" => {
                    let (rd, ra) = self.parse_rr();
                    self.emit_rrii(0, rd, ra, 0, 16);
                }
                "sxb" => {
                    let (rd, ra) = self.parse_rr();
                    self.emit_rrii(8, rd, ra, 0, 24);
                }
                "sxh" => {
                    let (rd, ra) = self.parse_rr();
                    self.emit_rrii(8, rd, ra, 0, 16);
                }
                "srli" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.emit_rrii(0, rd, ra, i, i);
                }
                "slli" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.emit_rrii(4, rd, ra, i, i);
                }
                "srai" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.emit_rrii(8, rd, ra, i, i);
                }
                "rori" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.emit_rrii(0, rd, ra, i, 0);
                }
                "roli" => {
                    let (rd, ra, i) = self.parse_rri();
                    self.emit_rrii(4, rd, ra, i, 0);
                }

                "add" => self.alu_reg(0),
                "and" => self.alu_reg(1),
                "or" => self.alu_reg(2),
                "xor" => self.alu_reg(3),
                "sub" => self.alu_reg(4),
                "andn" => self.alu_reg(5),
                "orn" => self.alu_reg(6),
                "xorn" => self.alu_reg(7),
                "mov" => self.alu_reg_a0(2),
                "not" => self.alu_reg_a0(6),
                "neg" => self.alu_reg_a0(4),
                "nop" => self.emit_rrr(2, 0, 0, 0),

                "srl" => self.alu_reg(0x10),
                "sll" => self.alu_reg(0x11),
                "sra" => self.alu_reg(0x12),
                "ror" => self.alu_reg(0x14),
                "rol" => self.alu_reg(0x15),

                "tst" => self.alu_reg_d0(0x22),
                "scmp" => self.alu_reg_d0(0x24),
                "ucmp" => self.alu_reg_d0(0x25),
                "tstn" => self.alu_reg_d0(0x26),

                "selgt" => self.alu_reg(0x30),
                "selle" => self.alu_reg(0x31),
                "selng" => self.alu_reg(0x31),
                "seleq" => self.alu_reg(0x32),
                "selne" => self.alu_reg(0x33),
                "sellt" => self.alu_reg(0x34),
                "selge" => self.alu_reg(0x35),
                "selnl" => self.alu_reg(0x35),

                "movgt" => self.alu_reg_ad(0x30),
                "movle" => self.alu_reg_ad(0x31),
                "movng" => self.alu_reg_ad(0x31),
                "moveq" => self.alu_reg_ad(0x32),
                "movne" => self.alu_reg_ad(0x33),
                "movlt" => self.alu_reg_ad(0x34),
                "movge" => self.alu_reg_ad(0x35),
                "movnl" => self.alu_reg_ad(0x35),

                "sincgt" => self.alu_reg(0x38),
                "sincle" => self.alu_reg(0x39),
                "sincng" => self.alu_reg(0x39),
                "sinceq" => self.alu_reg(0x3a),
                "sincne" => self.alu_reg(0x3b),
                "sinclt" => self.alu_reg(0x3c),
                "sincge" => self.alu_reg(0x3d),
                "sincnl" => self.alu_reg(0x3d),

                "incgt" => self.alu_reg_aa(0x38),
                "incle" => self.alu_reg_aa(0x39),
                "incng" => self.alu_reg_aa(0x39),
                "inceq" => self.alu_reg_aa(0x3a),
                "incne" => self.alu_reg_aa(0x3b),
                "inclt" => self.alu_reg_aa(0x3c),
                "incge" => self.alu_reg_aa(0x3d),
                "incnl" => self.alu_reg_aa(0x3d),

                "setgt" => self.alu_reg_0(0x38),
                "setle" => self.alu_reg_0(0x39),
                "setng" => self.alu_reg_0(0x39),
                "seteq" => self.alu_reg_0(0x3a),
                "setne" => self.alu_reg_0(0x3b),
                "setlt" => self.alu_reg_0(0x3c),
                "setge" => self.alu_reg_0(0x3d),
                "setnl" => self.alu_reg_0(0x3d),

                "ldb" => self.mem_imm(0x20),
                "ldbs" => self.mem_imm(0x21),
                "stb" => self.mem_imm(0x22),
                "ldh" => self.mem_imm(0x24),
                "ldhs" => self.mem_imm(0x25),
                "sth" => self.mem_imm(0x26),
                "ldw" => self.mem_imm(0x28),
                "stw" => self.mem_imm(0x2a),

                "ldbx" => self.mem_reg(0x7c0),
                "ldbsx" => self.mem_reg(0x7c1),
                "stbx" => self.mem_reg(0x7c2),
                "ldhx" => self.mem_reg(0x7c4),
                "ldhsx" => self.mem_reg(0x7c5),
                "sthx" => self.mem_reg(0x7c6),
                "ldwx" => self.mem_reg(0x7c8),
                "stwx" => self.mem_reg(0x7ca),

                "addx" => {
                    let (rt, ra, rb, sc) = self.parse_memx();
                    if !sc.is_power_of_two() || sc > 4 {
                        error!(self, "invalid scale");
                    }
                    self.emit_rrr(0x7d3 | sc.trailing_zeros() << 2, rt, ra, rb);
                }

                "mfio" => self.io(0x30),
                "mtio" => self.io(0x31),

                "scall" => {
                    let i = self.expr();
                    self.emit_special(0, 0, i);
                }
                "eret" => {
                    self.emit_special(1, 0, 0);
                }
                "mfsr" => {
                    let rt = self.reg();
                    expect!(self, Comma);
                    let sr = self.sreg();
                    self.emit_special(4, rt, sr);
                }
                "mtsr" => {
                    let rt = self.reg();
                    expect!(self, Comma);
                    let sr = self.sreg();
                    self.emit_special(5, rt, sr);
                }
                "mfcr" => {
                    let rt = self.reg();
                    self.emit_special(6, rt, 0);
                }
                "mtcr" => {
                    let rt = self.reg();
                    self.emit_special(7, rt, 0);
                }
                "udf" => self.emitw(0xffff_ffff),

                "bgt" => self.jmp(0x8),
                "ble" => self.jmp(0x9),
                "bng" => self.jmp(0x9),
                "beq" => self.jmp(0xa),
                "bne" => self.jmp(0xb),
                "blt" => self.jmp(0xc),
                "bge" => self.jmp(0xd),
                "bnl" => self.jmp(0xd),
                "jp" => self.jmp(0xe),
                "jl" => self.jmp(0xf),

                "adr" => self.adr(),

                ".set" => {
                    let x = expect!(self, Ident(x));
                    if x == "." {
                        error!(self, "cannot use this name");
                    }
                    expect!(self, Comma);
                    let v = self.expr();
                    self.constants.insert(x, v);
                }
                ".align" => {
                    let a = self.expr();
                    self.align(a as usize);
                }
                ".byte" => loop {
                    if let Some(Token::StringLit(v)) = check!(self, StringLit(_)) {
                        self.code.extend(v);
                    } else {
                        let b = self.expr();
                        self.emitb(b as u8);
                    }
                    if check!(self, Comma).is_none() {
                        break;
                    }
                },
                ".string" => {
                    let v = expect!(self, StringLit(v));
                    self.code.extend(v);
                    self.code.push(0);
                }
                ".half" => loop {
                    let h = self.expr();
                    self.emith(h as u16);
                    if check!(self, Comma).is_none() {
                        break;
                    }
                },
                ".word" => loop {
                    if self.check_label() {
                        let p = self.label_expr(PatchKind::Abs32);
                        self.add_patch(p);
                        self.emitw(0);
                    } else {
                        let w = self.expr();
                        self.emitw(w);
                    }
                    if check!(self, Comma).is_none() {
                        break;
                    }
                },
                ".global" => {
                    let x = expect!(self, Ident(x));
                    if x.starts_with('.') {
                        error!(self, "cannot make this global");
                    }
                    if let Some(i) = self.locals.remove(&x) {
                        self.globals.insert(x, Some(i));
                    } else {
                        self.globals.entry(x).or_default();
                    }
                }
                ".include" => {
                    let ifile = expect!(self, StringLit(ifile));
                    let fullpath = Path::new(file)
                        .parent()
                        .unwrap()
                        .join(str::from_utf8(&ifile).unwrap());
                    let oldfp = self.fp.take();
                    let oldfile = mem::take(&mut self.file);
                    let oldline = self.line;
                    let oldnextchr = self.nextchar.take();
                    let oldnexttok = self.nexttok.take();
                    self.parse(fullpath.to_str().unwrap());
                    self.fp = oldfp;
                    self.file = oldfile;
                    self.line = oldline;
                    self.nextchar = oldnextchr;
                    self.nexttok = oldnexttok;
                }
                l => {
                    expect!(self, Colon);

                    if l == "." {
                        error!(self, "cannot use this name");
                    }

                    let idx = self.symt.len();
                    if l.starts_with('.') {
                        if self.locals.contains_key(l) {
                            error!(self, "duplicate label '{}'", l);
                        }
                        self.locals.insert(l.to_string(), idx);
                    } else {
                        let ps = std::mem::take(&mut self.localpatches);
                        for p in ps {
                            if !self.apply_patch(&p) {
                                error!(p, "undefined label '{}'", p.sym);
                            }
                        }
                        self.locals.clear();

                        if self.globals.contains_key(l) {
                            if self.globals[l].is_some() {
                                error!(self, "duplicate label '{}'", l);
                            }
                            self.globals.insert(l.to_string(), Some(idx));
                        } else {
                            if self.filelocals.contains_key(l) {
                                error!(self, "duplicate label '{}'", l);
                            }
                            self.filelocals.insert(l.to_string(), idx);
                        }
                    }
                    self.symt.push(Sym {
                        addr: self.code.len(),
                        name: l.to_string(),
                    });
                }
            }

            expect!(self, NewLine);
        }
    }

    pub fn assemble(&mut self, file: &str) {
        self.parse(file);

        let ps = std::mem::take(&mut self.localpatches);
        for p in ps {
            if !self.apply_patch(&p) {
                error!(p, "undefined label '{}'", p.sym);
            }
        }
        self.locals.clear();

        let ps = std::mem::take(&mut self.filepatches);
        for p in ps {
            if !self.apply_patch(&p) {
                self.globalpatches.push(p);
            }
        }
        self.filelocals.clear();

        self.constants.clear();
    }

    pub fn output(&mut self, file: String, emitsyms: bool) {
        let ps = std::mem::take(&mut self.globalpatches);
        for p in ps {
            if !self.apply_patch(&p) {
                error!(p, "undefined label '{}'", p.sym);
            }
        }

        std::fs::write(&file, &self.code).unwrap();

        if emitsyms {
            let mut f = File::create(format!("{}.syms", file)).unwrap();
            for sym in &self.symt {
                writeln!(f, "{:08x}: {}", sym.addr, sym.name).unwrap();
            }
        }
    }

    fn emitb(&mut self, b: u8) {
        self.code.push(b)
    }

    fn emith(&mut self, h: u16) {
        self.code.extend(h.to_le_bytes())
    }

    fn emitw(&mut self, w: u32) {
        self.code.extend(w.to_le_bytes())
    }

    fn align(&mut self, amt: usize) {
        while !self.code.len().is_multiple_of(amt) {
            self.code.push(0);
        }
    }

    fn emit_rri(&mut self, opc: u32, rd: u32, ra: u32, imm: u32) {
        self.emitw(imm << 16 | ra << 11 | rd << 6 | opc)
    }

    fn emit_ri(&mut self, opc: u32, ra: u32, imm: u32) {
        self.emitw(imm << 16 | ra << 11 | opc << 6 | 0x38)
    }

    fn emit_rrii(&mut self, opc: u32, rd: u32, ra: u32, imm1: u32, imm2: u32) {
        if imm1 >= 32 || imm2 >= 32 {
            error!(self, "immediate out of range");
        }
        self.emitw(opc << 26 | imm2 << 21 | imm1 << 16 | ra << 11 | rd << 6 | 0x39);
    }

    fn emit_rrr(&mut self, opc: u32, rd: u32, ra: u32, rb: u32) {
        self.emitw(opc << 21 | rb << 16 | ra << 11 | rd << 6 | 0x3e);
    }

    fn emit_special(&mut self, opc: u32, rd: u32, imm: u32) {
        if imm > u16::MAX as u32 {
            error!(self, "immediate out of range");
        }
        self.emitw(imm << 16 | opc << 11 | rd << 6 | 0x3d);
    }

    fn add_imm(&mut self, rd: u32, ra: u32, imm: u32) {
        let nimm = imm.wrapping_neg();
        if imm & 0xffff0000 == 0 {
            self.emit_rri(0x10, rd, ra, imm);
        } else if imm & 0x0000ffff == 0 {
            self.emit_rri(0x18, rd, ra, imm >> 16);
        } else if nimm & 0xffff0000 == 0 {
            self.emit_rri(0x14, rd, ra, nimm);
        } else {
            self.emit_rri(0x10, rd, ra, imm & 0xffff);
            self.emit_rri(0x18, rd, rd, imm >> 16);
        }
    }

    fn logic_imm(&mut self, opc: u32, rd: u32, ra: u32, imm: u32) {
        if imm & 0xffff0000 == 0 {
            self.emit_rri(opc, rd, ra, imm);
        } else if imm & 0x0000ffff == 0 {
            self.emit_rri(opc | 8, rd, ra, imm >> 16);
        } else if !imm & 0xffff0000 == 0 {
            self.emit_rri(opc | 4, rd, ra, !imm);
        } else if !imm & 0x0000ffff == 0 {
            self.emit_rri(opc | 0xc, rd, ra, !imm >> 16);
        } else if opc == 0x11 {
            self.emit_rri(opc | 4, rd, ra, !imm & 0xffff);
            self.emit_rri(opc | 0xc, rd, rd, !imm >> 16);
        } else {
            self.emit_rri(opc, rd, ra, imm & 0xffff);
            self.emit_rri(opc | 8, rd, rd, imm >> 16);
        }
    }

    fn cmp_imm(&mut self, opc: u32) {
        let (ra, imm) = self.parse_ri();
        let nimm = imm.wrapping_neg();
        if imm & 0xffff0000 == 0 {
            self.emit_ri(opc, ra, imm);
        } else if imm & 0x0000ffff == 0 {
            self.emit_ri(opc | 8, ra, imm >> 16);
        } else if nimm & 0xffff0000 == 0 {
            self.emit_ri(opc ^ 4, ra, nimm);
        } else {
            error!(self, "immediate out of range");
        }
    }

    fn tst_imm(&mut self) {
        let (ra, imm) = self.parse_ri();
        if imm & 0xffff0000 == 0 {
            self.emit_ri(0x2, ra, imm);
        } else if imm & 0x0000ffff == 0 {
            self.emit_ri(0xa, ra, imm >> 16);
        } else if !imm & 0xffff0000 == 0 {
            self.emit_ri(0x6, ra, !imm);
        } else if !imm & 0x0000ffff == 0 {
            self.emit_ri(0xe, ra, !imm >> 16);
        } else {
            error!(self, "immediate out of range");
        }
    }

    fn alu_reg(&mut self, opc: u32) {
        let (rd, ra, rb) = self.parse_rrr();
        self.emit_rrr(opc, rd, ra, rb);
    }

    fn alu_reg_a0(&mut self, opc: u32) {
        let (rd, rb) = self.parse_rr();
        self.emit_rrr(opc, rd, 0, rb);
    }

    fn alu_reg_d0(&mut self, opc: u32) {
        let (ra, rb) = self.parse_rr();
        self.emit_rrr(opc, 0, ra, rb);
    }

    fn alu_reg_aa(&mut self, opc: u32) {
        let (rd, ra) = self.parse_rr();
        self.emit_rrr(opc, rd, ra, ra);
    }

    fn alu_reg_ad(&mut self, opc: u32) {
        let (rd, ra) = self.parse_rr();
        self.emit_rrr(opc, rd, ra, rd);
    }

    fn alu_reg_0(&mut self, opc: u32) {
        let rd = self.reg();
        self.emit_rrr(opc, rd, 0, 0);
    }

    fn mem_imm(&mut self, opc: u32) {
        let (rt, ra, imm) = self.parse_mem();
        let simm = imm as i32;
        if simm < i16::MIN as i32 || simm > i16::MAX as i32 {
            error!(self, "immediate out of range");
        }
        self.emit_rri(opc, rt, ra, imm & 0xffff);
    }

    fn io(&mut self, opc: u32) {
        let rt = self.reg();
        expect!(self, Comma);
        let i = self.expr();
        let ra;
        if check!(self, LParen).is_some() {
            ra = self.reg();
            expect!(self, RParen);
        } else {
            ra = 0;
        }
        if i > u16::MAX as u32 {
            error!(self, "immediate out of range");
        }
        self.emit_rri(opc, rt, ra, i);
    }

    fn mem_reg(&mut self, opc: u32) {
        let (rt, ra, rb, sc) = self.parse_memx();
        let sz = opc >> 2 & 3;
        if sc != 1 && 1 << sz != sc {
            error!(self, "invalid scale");
        }
        if sc != 1 {
            self.emit_rrr(opc | 0x10, rt, ra, rb);
        } else {
            self.emit_rrr(opc, rt, ra, rb);
        }
    }

    fn add_patch(&mut self, p: Patch) {
        if p.sym.starts_with('.') {
            self.localpatches.push(p);
        } else {
            self.filepatches.push(p);
        }
    }

    fn jmp(&mut self, opc: u32) {
        let p = self.label_expr(PatchKind::Jmp26);
        self.add_patch(p);
        self.emitw(opc);
    }

    fn adr(&mut self) {
        let rd = self.reg();
        expect!(self, Comma);
        let p = self.label_expr(PatchKind::Adr21);
        self.add_patch(p);
        self.emitw(rd << 6 | 0x3b);
    }

    fn sym_addr(&self, sym: &str) -> Option<usize> {
        Some(if sym == "." {
            self.code.len()
        } else if let Some(&i) = self.locals.get(sym) {
            self.symt[i].addr
        } else if let Some(&i) = self.filelocals.get(sym) {
            self.symt[i].addr
        } else if let Some(&Some(i)) = self.globals.get(sym) {
            self.symt[i].addr
        } else {
            return None;
        })
    }

    fn apply_patch(&mut self, p: &Patch) -> bool {
        let symaddr = if p.sym == "." {
            p.addr
        } else if let Some(a) = self.sym_addr(&p.sym) {
            a
        } else {
            return false;
        }
        .wrapping_add(p.addend as usize);

        let reladdr: isize = symaddr as isize - p.addr as isize;

        let mut patchval = u32::from_le_bytes(self.code[p.addr..p.addr + 4].try_into().unwrap());
        match p.kind {
            PatchKind::Abs32 | PatchKind::Rel32 => {
                patchval = symaddr as u32;
            }
            PatchKind::Jmp26 => {
                if reladdr & 3 != 0 {
                    error!(p, "misaligned jump offset");
                }
                if !(-(1 << 28)..1 << 28).contains(&reladdr) {
                    error!(p, "label too far");
                }
                patchval = patchval & 0x3f | (reladdr as u32) << 4;
            }
            PatchKind::Adr21 => {
                if !(-(1 << 21)..1 << 21).contains(&reladdr) {
                    error!(p, "label too far");
                }
                patchval = patchval & 0x7ff | (reladdr as u32) << 11;
            }
        }
        self.code[p.addr..p.addr + 4].clone_from_slice(&patchval.to_le_bytes());

        true
    }
}
