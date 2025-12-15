use std::{
    collections::HashMap,
    fs::File,
    io::{BufReader, Write},
    mem,
    path::Path,
};

use crate::tokenize::{Token, next_token};

#[derive(Default)]
pub struct State {
    pub fp: Option<BufReader<File>>,
    pub file: String,
    pub line: u32,

    pub nextchar: Option<u8>,
    nexttok: Option<Token>,

    code: Vec<u8>,

    constants: HashMap<String, u32>,

    symt: Vec<Sym>,
    globals: HashMap<String, Option<usize>>,
    filelocals: HashMap<String, usize>,
    locals: HashMap<String, usize>,

    globalpatches: Vec<Patch>,
    filepatches: Vec<Patch>,
    localpatches: Vec<Patch>,
}

struct Sym {
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

struct Patch {
    kind: PatchKind,
    file: String,
    line: u32,
    addr: usize,
    sym: String,
    addend: i32,
}

macro_rules! error {
    ($s:expr, $m:expr $(,$args:expr)*) => {
        panic!(concat!("assembler error at {}:{}: ", $m), $s.file, $s.line $(,$args)*)
    };
}

fn advance(s: &mut State) -> Option<Token> {
    let t = s.nexttok.take();
    s.nexttok = next_token(s);
    if t == Some(Token::NewLine) {
        s.line += 1
    };
    t
}

macro_rules! check {
    ($s:expr) => {
        None
    };
    ($s:expr, $t:ident $(($v:tt))? $(, $ts:ident)*) => {
        if matches!($s.nexttok, Some(Token::$t $(($v))?)) {
            advance($s)
        } else {
            check!($s $(, $ts)*)
        }
    };
}

macro_rules! expect {
    ($s:expr, $t:ident $(($v:tt))?) => {
        if let Some(Token::$t$(($v))?) = advance($s) {
            $($v)?
        } else {error!($s, "expected {}", stringify!($t));}
    };
}

fn reg(s: &mut State) -> u32 {
    let rn = expect!(s, Ident(rn));
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
            error!(s, "unknown register {}", rn);
        }
    }
}

fn expr_primary(s: &mut State) -> u32 {
    if check!(s, Sub).is_some() {
        expr_primary(s).wrapping_neg()
    } else if check!(s, Not).is_some() {
        !expr_primary(s)
    } else if check!(s, LParen).is_some() {
        let i = expr(s);
        expect!(s, RParen);
        i
    } else if let Some(Token::IntLit(i)) = check!(s, IntLit(_)) {
        i
    } else if let Some(Token::Ident(x)) = check!(s, Ident(_)) {
        if let Some(&v) = s.constants.get(&x) {
            v
        } else {
            error!(s, "unexpected label or undefined constant '{}'", x)
        }
    } else {
        error!(s, "expected constant expression")
    }
}

fn expr_prod(s: &mut State) -> u32 {
    let mut i = expr_primary(s);
    while let Some(t) = check!(s, Mul, Div, Mod) {
        let rhs = expr_primary(s);
        match t {
            Token::Mul => i *= rhs,
            Token::Div => i /= rhs,
            Token::Mod => i %= rhs,
            _ => unreachable!(),
        }
    }
    i
}

fn expr_sum2(s: &mut State, mut i: u32) -> u32 {
    while let Some(t) = check!(s, Add, Sub) {
        let rhs = expr_prod(s);
        match t {
            Token::Add => i += rhs,
            Token::Sub => i -= rhs,
            _ => unreachable!(),
        }
    }
    i
}

fn expr_sum(s: &mut State) -> u32 {
    let i = expr_prod(s);
    expr_sum2(s, i)
}

fn expr_shift(s: &mut State) -> u32 {
    let mut i = expr_sum(s);
    while let Some(t) = check!(s, Shl, Shr) {
        let rhs = expr_sum(s);
        match t {
            Token::Shl => i <<= rhs,
            Token::Shr => i >>= rhs,
            _ => unreachable!(),
        }
    }
    i
}

fn expr_bitwise(s: &mut State) -> u32 {
    let mut i = expr_shift(s);
    while let Some(t) = check!(s, And, Or, Xor) {
        let rhs = expr_shift(s);
        match t {
            Token::And => i &= rhs,
            Token::Or => i |= rhs,
            Token::Xor => i ^= rhs,
            _ => unreachable!(),
        }
    }
    i
}

fn expr(s: &mut State) -> u32 {
    expr_bitwise(s)
}

fn check_label(s: &mut State) -> bool {
    if let Some(Token::Ident(x)) = s.nexttok.as_ref()
        && !s.constants.contains_key(x)
    {
        true
    } else {
        false
    }
}

fn label_expr(s: &mut State, mut k: PatchKind) -> Patch {
    if !check_label(s) {
        error!(s, "expected label");
    }
    let Some(Token::Ident(l)) = advance(s) else {
        unreachable!()
    };
    let mut addend: i32 = 0;
    if let Some(t) = check!(s, Add, Sub) {
        match t {
            Token::Add => {
                addend += expr(s) as i32;
            }
            Token::Sub => {
                if let Some(Token::Ident(x)) = s.nexttok.as_ref()
                    && !s.constants.contains_key(x)
                    && k == PatchKind::Abs32
                    && let Some(sa) = sym_addr(s, x)
                {
                    advance(s);
                    k = PatchKind::Rel32;
                    addend -= sa as i32;
                } else {
                    addend -= expr_prod(s) as i32;
                }
                addend = expr_sum2(s, addend as u32) as i32;
            }
            _ => unreachable!(),
        }
    }
    Patch {
        file: s.file.clone(),
        line: s.line,
        kind: k,
        addr: s.code.len(),
        sym: l,
        addend,
    }
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

fn sreg(s: &mut State) -> u32 {
    if let Some(Token::Ident(x)) = s.nexttok.as_ref()
        && let Some(i) = sreg_of_str(x)
    {
        advance(s);
        i
    } else {
        expr(s)
    }
}

fn parse_rri(s: &mut State) -> (u32, u32, u32) {
    let rd = reg(s);
    expect!(s, Comma);
    let ra = reg(s);
    expect!(s, Comma);
    let i = expr(s);
    (rd, ra, i)
}

fn parse_ri(s: &mut State) -> (u32, u32) {
    let ra = reg(s);
    expect!(s, Comma);
    let i = expr(s);
    (ra, i)
}

fn parse_rrii(s: &mut State) -> (u32, u32, u32, u32) {
    let rd = reg(s);
    expect!(s, Comma);
    let ra = reg(s);
    expect!(s, Comma);
    let i1 = expr(s);
    expect!(s, Comma);
    let i2 = expr(s);
    (rd, ra, i1, i2)
}

fn parse_rrr(s: &mut State) -> (u32, u32, u32) {
    let rd = reg(s);
    expect!(s, Comma);
    let ra = reg(s);
    expect!(s, Comma);
    let rb = reg(s);
    (rd, ra, rb)
}

fn parse_rr(s: &mut State) -> (u32, u32) {
    let ra = reg(s);
    expect!(s, Comma);
    let rb = reg(s);
    (ra, rb)
}

fn parse_mem(s: &mut State) -> (u32, u32, u32) {
    let rt = reg(s);
    expect!(s, Comma);
    let i;
    if check!(s, LParen).is_some() {
        i = 0;
    } else {
        i = expr(s);
        expect!(s, LParen);
    }
    let ra = reg(s);
    expect!(s, RParen);
    (rt, ra, i)
}

fn parse_memx(s: &mut State) -> (u32, u32, u32, u32) {
    let rt = reg(s);
    expect!(s, Comma);
    expect!(s, LParen);
    let ra = reg(s);
    expect!(s, Comma);
    let rb = reg(s);
    let i = if check!(s, Comma).is_some() {
        expr(s)
    } else {
        1
    };
    expect!(s, RParen);
    (rt, ra, rb, i)
}

fn parse(s: &mut State, file: &str) {
    s.file = file.to_string();
    s.line = 0;
    let Ok(fp) = File::open(&s.file).map(BufReader::new) else {
        error!(s, "cannot open file")
    };
    s.fp = Some(fp);

    advance(s);
    while s.nexttok.is_some() {
        if check!(s, NewLine).is_some() {
            continue;
        }
        let id = expect!(s, Ident(id));

        match id.as_str() {
            "addi" => {
                let (rd, ra, i) = parse_rri(s);
                add_imm(s, rd, ra, i)
            }
            "subi" => {
                let (rd, ra, i) = parse_rri(s);
                add_imm(s, rd, ra, i.wrapping_neg())
            }
            "andi" => {
                let (rd, ra, i) = parse_rri(s);
                logic_imm(s, 0x11, rd, ra, i);
            }
            "andni" => {
                let (rd, ra, i) = parse_rri(s);
                logic_imm(s, 0x11, rd, ra, !i);
            }
            "ori" => {
                let (rd, ra, i) = parse_rri(s);
                logic_imm(s, 0x12, rd, ra, i);
            }
            "xori" => {
                let (rd, ra, i) = parse_rri(s);
                logic_imm(s, 0x13, rd, ra, i);
            }
            "movi" => {
                let (rd, i) = parse_ri(s);
                logic_imm(s, 0x12, rd, 0, i);
            }
            "scmpi" => cmp_imm(s, 4),
            "ucmpi" => cmp_imm(s, 5),
            "tsti" => tst_imm(s),

            "jpr" => {
                let rd = reg(s);
                emit_ri(s, 0x10, rd, 0);
            }
            "jlr" => {
                let rd = reg(s);
                emit_ri(s, 0x11, rd, 0);
            }
            "ret" => emit_ri(s, 0x10, 31, 0),

            "rormi" => {
                let (rd, ra, i1, i2) = parse_rrii(s);
                emit_rrii(s, 0, rd, ra, i1, i2);
            }
            "rolmi" => {
                let (rd, ra, i1, i2) = parse_rrii(s);
                emit_rrii(s, 4, rd, ra, i1, i2);
            }
            "rorsmi" => {
                let (rd, ra, i1, i2) = parse_rrii(s);
                emit_rrii(s, 8, rd, ra, i1, i2);
            }
            "ubfe" => {
                let (rd, ra, i1, i2) = parse_rrii(s);
                emit_rrii(s, 0, rd, ra, i1, 32 - i2);
            }
            "sbfe" => {
                let (rd, ra, i1, i2) = parse_rrii(s);
                emit_rrii(s, 8, rd, ra, i1, 32 - i2);
            }
            "uxb" => {
                let (rd, ra) = parse_rr(s);
                emit_rrii(s, 0, rd, ra, 0, 24);
            }
            "uxh" => {
                let (rd, ra) = parse_rr(s);
                emit_rrii(s, 0, rd, ra, 0, 16);
            }
            "sxb" => {
                let (rd, ra) = parse_rr(s);
                emit_rrii(s, 8, rd, ra, 0, 24);
            }
            "sxh" => {
                let (rd, ra) = parse_rr(s);
                emit_rrii(s, 8, rd, ra, 0, 16);
            }
            "srli" => {
                let (rd, ra, i) = parse_rri(s);
                emit_rrii(s, 0, rd, ra, i, i);
            }
            "slli" => {
                let (rd, ra, i) = parse_rri(s);
                emit_rrii(s, 4, rd, ra, i, i);
            }
            "srai" => {
                let (rd, ra, i) = parse_rri(s);
                emit_rrii(s, 8, rd, ra, i, i);
            }
            "rori" => {
                let (rd, ra, i) = parse_rri(s);
                emit_rrii(s, 0, rd, ra, i, 0);
            }
            "roli" => {
                let (rd, ra, i) = parse_rri(s);
                emit_rrii(s, 4, rd, ra, i, 0);
            }

            "add" => alu_reg(s, 0),
            "and" => alu_reg(s, 1),
            "or" => alu_reg(s, 2),
            "xor" => alu_reg(s, 3),
            "sub" => alu_reg(s, 4),
            "andn" => alu_reg(s, 5),
            "orn" => alu_reg(s, 6),
            "xorn" => alu_reg(s, 7),
            "mov" => alu_reg_a0(s, 2),
            "not" => alu_reg_a0(s, 6),
            "neg" => alu_reg_a0(s, 4),
            "nop" => emit_rrr(s, 2, 0, 0, 0),

            "srl" => alu_reg(s, 0x10),
            "sll" => alu_reg(s, 0x11),
            "sra" => alu_reg(s, 0x12),
            "ror" => alu_reg(s, 0x14),
            "rol" => alu_reg(s, 0x15),

            "tst" => alu_reg_d0(s, 0x22),
            "scmp" => alu_reg_d0(s, 0x24),
            "ucmp" => alu_reg_d0(s, 0x25),
            "tstn" => alu_reg_d0(s, 0x26),

            "selgt" => alu_reg(s, 0x30),
            "selle" => alu_reg(s, 0x31),
            "selng" => alu_reg(s, 0x31),
            "seleq" => alu_reg(s, 0x32),
            "selne" => alu_reg(s, 0x33),
            "sellt" => alu_reg(s, 0x34),
            "selge" => alu_reg(s, 0x35),
            "selnl" => alu_reg(s, 0x35),

            "movgt" => alu_reg_ad(s, 0x30),
            "movle" => alu_reg_ad(s, 0x31),
            "movng" => alu_reg_ad(s, 0x31),
            "moveq" => alu_reg_ad(s, 0x32),
            "movne" => alu_reg_ad(s, 0x33),
            "movlt" => alu_reg_ad(s, 0x34),
            "movge" => alu_reg_ad(s, 0x35),
            "movnl" => alu_reg_ad(s, 0x35),

            "sincgt" => alu_reg(s, 0x38),
            "sincle" => alu_reg(s, 0x39),
            "sincng" => alu_reg(s, 0x39),
            "sinceq" => alu_reg(s, 0x3a),
            "sincne" => alu_reg(s, 0x3b),
            "sinclt" => alu_reg(s, 0x3c),
            "sincge" => alu_reg(s, 0x3d),
            "sincnl" => alu_reg(s, 0x3d),

            "incgt" => alu_reg_aa(s, 0x38),
            "incle" => alu_reg_aa(s, 0x39),
            "incng" => alu_reg_aa(s, 0x39),
            "inceq" => alu_reg_aa(s, 0x3a),
            "incne" => alu_reg_aa(s, 0x3b),
            "inclt" => alu_reg_aa(s, 0x3c),
            "incge" => alu_reg_aa(s, 0x3d),
            "incnl" => alu_reg_aa(s, 0x3d),

            "setgt" => alu_reg_0(s, 0x38),
            "setle" => alu_reg_0(s, 0x39),
            "setng" => alu_reg_0(s, 0x39),
            "seteq" => alu_reg_0(s, 0x3a),
            "setne" => alu_reg_0(s, 0x3b),
            "setlt" => alu_reg_0(s, 0x3c),
            "setge" => alu_reg_0(s, 0x3d),
            "setnl" => alu_reg_0(s, 0x3d),

            "ldb" => mem_imm(s, 0x20),
            "ldbs" => mem_imm(s, 0x21),
            "stb" => mem_imm(s, 0x22),
            "ldh" => mem_imm(s, 0x24),
            "ldhs" => mem_imm(s, 0x25),
            "sth" => mem_imm(s, 0x26),
            "ldw" => mem_imm(s, 0x28),
            "stw" => mem_imm(s, 0x2a),

            "ldbx" => mem_reg(s, 0x7c0),
            "ldbsx" => mem_reg(s, 0x7c1),
            "stbx" => mem_reg(s, 0x7c2),
            "ldhx" => mem_reg(s, 0x7c4),
            "ldhsx" => mem_reg(s, 0x7c5),
            "sthx" => mem_reg(s, 0x7c6),
            "ldwx" => mem_reg(s, 0x7c8),
            "stwx" => mem_reg(s, 0x7ca),

            "addx" => {
                let (rt, ra, rb, sc) = parse_memx(s);
                if !sc.is_power_of_two() || sc > 4 {
                    error!(s, "invalid scale");
                }
                emit_rrr(s, 0x7d3 | sc.trailing_zeros() << 2, rt, ra, rb);
            }

            "mfio" => io(s, 0x30),
            "mtio" => io(s, 0x31),

            "scall" => {
                let i = expr(s);
                emit_special(s, 0, 0, i);
            }
            "eret" => {
                emit_special(s, 1, 0, 0);
            }
            "mfsr" => {
                let rt = reg(s);
                expect!(s, Comma);
                let sr = sreg(s);
                emit_special(s, 4, rt, sr);
            }
            "mtsr" => {
                let rt = reg(s);
                expect!(s, Comma);
                let sr = sreg(s);
                emit_special(s, 5, rt, sr);
            }
            "mfcr" => {
                let rt = reg(s);
                emit_special(s, 6, rt, 0);
            }
            "mtcr" => {
                let rt = reg(s);
                emit_special(s, 7, rt, 0);
            }
            "udf" => emitw(s, 0xffff_ffff),

            "bgt" => jmp(s, 0x8),
            "ble" => jmp(s, 0x9),
            "bng" => jmp(s, 0x9),
            "beq" => jmp(s, 0xa),
            "bne" => jmp(s, 0xb),
            "blt" => jmp(s, 0xc),
            "bge" => jmp(s, 0xd),
            "bnl" => jmp(s, 0xd),
            "jp" => jmp(s, 0xe),
            "jl" => jmp(s, 0xf),

            "adr" => adr(s),

            ".set" => {
                let x = expect!(s, Ident(x));
                if x == "." {
                    error!(s, "cannot use this name");
                }
                expect!(s, Comma);
                let v = expr(s);
                s.constants.insert(x, v);
            }
            ".align" => {
                let a = expr(s);
                align(s, a as usize);
            }
            ".byte" => loop {
                if let Some(Token::StringLit(v)) = check!(s, StringLit(_)) {
                    s.code.extend(v);
                } else {
                    let b = expr(s);
                    emitb(s, b as u8);
                }
                if check!(s, Comma).is_none() {
                    break;
                }
            },
            ".string" => {
                let v = expect!(s, StringLit(v));
                s.code.extend(v);
                s.code.push(0);
            }
            ".half" => loop {
                let h = expr(s);
                emith(s, h as u16);
                if check!(s, Comma).is_none() {
                    break;
                }
            },
            ".word" => loop {
                if check_label(s) {
                    let p = label_expr(s, PatchKind::Abs32);
                    add_patch(s, p);
                    emitw(s, 0);
                } else {
                    let w = expr(s);
                    emitw(s, w);
                }
                if check!(s, Comma).is_none() {
                    break;
                }
            },
            ".global" => {
                let x = expect!(s, Ident(x));
                if x.starts_with('.') {
                    error!(s, "cannot make this global");
                }
                if let Some(i) = s.locals.remove(&x) {
                    s.globals.insert(x, Some(i));
                } else {
                    s.globals.entry(x).or_default();
                }
            }
            ".include" => {
                let ifile = expect!(s, StringLit(ifile));
                let fullpath = Path::new(file)
                    .parent()
                    .unwrap()
                    .join(str::from_utf8(&ifile).unwrap());
                let oldfp = s.fp.take();
                let oldfile = mem::take(&mut s.file);
                let oldline = s.line;
                let oldnextchr = s.nextchar.take();
                let oldnexttok = s.nexttok.take();
                parse(s, fullpath.to_str().unwrap());
                s.fp = oldfp;
                s.file = oldfile;
                s.line = oldline;
                s.nextchar = oldnextchr;
                s.nexttok = oldnexttok;
            }
            l => {
                expect!(s, Colon);

                if l == "." {
                    error!(s, "cannot use this name");
                }

                let idx = s.symt.len();
                if l.starts_with('.') {
                    if s.locals.contains_key(l) {
                        error!(s, "duplicate label '{}'", l);
                    }
                    s.locals.insert(l.to_string(), idx);
                } else {
                    let ps = std::mem::take(&mut s.localpatches);
                    for p in ps {
                        if !apply_patch(s, &p) {
                            error!(p, "undefined label '{}'", p.sym);
                        }
                    }
                    s.locals.clear();

                    if s.globals.contains_key(l) {
                        if s.globals[l].is_some() {
                            error!(s, "duplicate label '{}'", l);
                        }
                        s.globals.insert(l.to_string(), Some(idx));
                    } else {
                        if s.filelocals.contains_key(l) {
                            error!(s, "duplicate label '{}'", l);
                        }
                        s.filelocals.insert(l.to_string(), idx);
                    }
                }
                s.symt.push(Sym {
                    addr: s.code.len(),
                    name: l.to_string(),
                });
            }
        }

        expect!(s, NewLine);
    }
}

pub fn assemble(s: &mut State, file: &str) {
    parse(s, file);

    let ps = std::mem::take(&mut s.localpatches);
    for p in ps {
        if !apply_patch(s, &p) {
            error!(p, "undefined label '{}'", p.sym);
        }
    }
    s.locals.clear();

    let ps = std::mem::take(&mut s.filepatches);
    for p in ps {
        if !apply_patch(s, &p) {
            s.globalpatches.push(p);
        }
    }
    s.filelocals.clear();

    s.constants.clear();
}

pub fn output(s: &mut State, file: String, emitsyms: bool) {
    let ps = std::mem::take(&mut s.globalpatches);
    for p in ps {
        if !apply_patch(s, &p) {
            error!(p, "undefined label '{}'", p.sym);
        }
    }

    std::fs::write(&file, &s.code).unwrap();

    if emitsyms {
        let mut f = File::create(format!("{}.syms", file)).unwrap();
        for sym in &s.symt {
            writeln!(f, "{:08x}: {}", sym.addr, sym.name).unwrap();
        }
    }
}

fn emitb(s: &mut State, b: u8) {
    s.code.push(b)
}

fn emith(s: &mut State, h: u16) {
    s.code.extend(h.to_le_bytes())
}

fn emitw(s: &mut State, w: u32) {
    s.code.extend(w.to_le_bytes())
}

fn align(s: &mut State, amt: usize) {
    while !s.code.len().is_multiple_of(amt) {
        s.code.push(0);
    }
}

fn emit_rri(s: &mut State, opc: u32, rd: u32, ra: u32, imm: u32) {
    emitw(s, imm << 16 | ra << 11 | rd << 6 | opc)
}

fn emit_ri(s: &mut State, opc: u32, ra: u32, imm: u32) {
    emitw(s, imm << 16 | ra << 11 | opc << 6 | 0x38)
}

fn emit_rrii(s: &mut State, opc: u32, rd: u32, ra: u32, imm1: u32, imm2: u32) {
    if imm1 >= 32 || imm2 >= 32 {
        error!(s, "immediate out of range");
    }
    emitw(
        s,
        opc << 26 | imm2 << 21 | imm1 << 16 | ra << 11 | rd << 6 | 0x39,
    );
}

fn emit_rrr(s: &mut State, opc: u32, rd: u32, ra: u32, rb: u32) {
    emitw(s, opc << 21 | rb << 16 | ra << 11 | rd << 6 | 0x3e);
}

fn emit_special(s: &mut State, opc: u32, rd: u32, imm: u32) {
    if imm > u16::MAX as u32 {
        error!(s, "immediate out of range");
    }
    emitw(s, imm << 16 | opc << 11 | rd << 6 | 0x3d);
}

fn add_imm(s: &mut State, rd: u32, ra: u32, imm: u32) {
    let nimm = imm.wrapping_neg();
    if imm & 0xffff0000 == 0 {
        emit_rri(s, 0x10, rd, ra, imm);
    } else if imm & 0x0000ffff == 0 {
        emit_rri(s, 0x18, rd, ra, imm >> 16);
    } else if nimm & 0xffff0000 == 0 {
        emit_rri(s, 0x14, rd, ra, nimm);
    } else {
        emit_rri(s, 0x10, rd, ra, imm & 0xffff);
        emit_rri(s, 0x18, rd, rd, imm >> 16);
    }
}

fn logic_imm(s: &mut State, opc: u32, rd: u32, ra: u32, imm: u32) {
    if imm & 0xffff0000 == 0 {
        emit_rri(s, opc, rd, ra, imm);
    } else if imm & 0x0000ffff == 0 {
        emit_rri(s, opc | 8, rd, ra, imm >> 16);
    } else if !imm & 0xffff0000 == 0 {
        emit_rri(s, opc | 4, rd, ra, !imm);
    } else if !imm & 0x0000ffff == 0 {
        emit_rri(s, opc | 0xc, rd, ra, !imm >> 16);
    } else if opc == 0x11 {
        emit_rri(s, opc | 4, rd, ra, !imm & 0xffff);
        emit_rri(s, opc | 0xc, rd, rd, !imm >> 16);
    } else {
        emit_rri(s, opc, rd, ra, imm & 0xffff);
        emit_rri(s, opc | 8, rd, rd, imm >> 16);
    }
}

fn cmp_imm(s: &mut State, opc: u32) {
    let (ra, imm) = parse_ri(s);
    let nimm = imm.wrapping_neg();
    if imm & 0xffff0000 == 0 {
        emit_ri(s, opc, ra, imm);
    } else if imm & 0x0000ffff == 0 {
        emit_ri(s, opc | 8, ra, imm >> 16);
    } else if nimm & 0xffff0000 == 0 {
        emit_ri(s, opc ^ 4, ra, nimm);
    } else {
        error!(s, "immediate out of range");
    }
}

fn tst_imm(s: &mut State) {
    let (ra, imm) = parse_ri(s);
    if imm & 0xffff0000 == 0 {
        emit_ri(s, 0x2, ra, imm);
    } else if imm & 0x0000ffff == 0 {
        emit_ri(s, 0xa, ra, imm >> 16);
    } else if !imm & 0xffff0000 == 0 {
        emit_ri(s, 0x6, ra, !imm);
    } else if !imm & 0x0000ffff == 0 {
        emit_ri(s, 0xe, ra, !imm >> 16);
    } else {
        error!(s, "immediate out of range");
    }
}

fn alu_reg(s: &mut State, opc: u32) {
    let (rd, ra, rb) = parse_rrr(s);
    emit_rrr(s, opc, rd, ra, rb);
}

fn alu_reg_a0(s: &mut State, opc: u32) {
    let (rd, rb) = parse_rr(s);
    emit_rrr(s, opc, rd, 0, rb);
}

fn alu_reg_d0(s: &mut State, opc: u32) {
    let (ra, rb) = parse_rr(s);
    emit_rrr(s, opc, 0, ra, rb);
}

fn alu_reg_aa(s: &mut State, opc: u32) {
    let (rd, ra) = parse_rr(s);
    emit_rrr(s, opc, rd, ra, ra);
}

fn alu_reg_ad(s: &mut State, opc: u32) {
    let (rd, ra) = parse_rr(s);
    emit_rrr(s, opc, rd, ra, rd);
}

fn alu_reg_0(s: &mut State, opc: u32) {
    let rd = reg(s);
    emit_rrr(s, opc, rd, 0, 0);
}

fn mem_imm(s: &mut State, opc: u32) {
    let (rt, ra, imm) = parse_mem(s);
    let simm = imm as i32;
    if simm < i16::MIN as i32 || simm > i16::MAX as i32 {
        error!(s, "immediate out of range");
    }
    emit_rri(s, opc, rt, ra, imm & 0xffff);
}

fn io(s: &mut State, opc: u32) {
    let rt = reg(s);
    expect!(s, Comma);
    let i = expr(s);
    let ra;
    if check!(s, LParen).is_some() {
        ra = reg(s);
        expect!(s, RParen);
    } else {
        ra = 0;
    }
    if i > u16::MAX as u32 {
        error!(s, "immediate out of range");
    }
    emit_rri(s, opc, rt, ra, i);
}

fn mem_reg(s: &mut State, opc: u32) {
    let (rt, ra, rb, sc) = parse_memx(s);
    let sz = opc >> 2 & 3;
    if sc != 1 && 1 << sz != sc {
        error!(s, "invalid scale");
    }
    if sc != 1 {
        emit_rrr(s, opc | 0x10, rt, ra, rb);
    } else {
        emit_rrr(s, opc, rt, ra, rb);
    }
}

fn add_patch(s: &mut State, p: Patch) {
    if p.sym.starts_with('.') {
        s.localpatches.push(p);
    } else {
        s.filepatches.push(p);
    }
}

fn jmp(s: &mut State, opc: u32) {
    let p = label_expr(s, PatchKind::Jmp26);
    add_patch(s, p);
    emitw(s, opc);
}

fn adr(s: &mut State) {
    let rd = reg(s);
    expect!(s, Comma);
    let p = label_expr(s, PatchKind::Adr21);
    add_patch(s, p);
    emitw(s, rd << 6 | 0x3b);
}

fn sym_addr(s: &State, sym: &str) -> Option<usize> {
    Some(if sym == "." {
        s.code.len()
    } else if let Some(&i) = s.locals.get(sym) {
        s.symt[i].addr
    } else if let Some(&i) = s.filelocals.get(sym) {
        s.symt[i].addr
    } else if let Some(&Some(i)) = s.globals.get(sym) {
        s.symt[i].addr
    } else {
        return None;
    })
}

fn apply_patch(s: &mut State, p: &Patch) -> bool {
    let symaddr = if p.sym == "." {
        p.addr
    } else if let Some(a) = sym_addr(s, &p.sym) {
        a
    } else {
        return false;
    }
    .wrapping_add(p.addend as usize);

    let reladdr: isize = symaddr as isize - p.addr as isize;

    let mut patchval = u32::from_le_bytes(s.code[p.addr..p.addr + 4].try_into().unwrap());
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
    s.code[p.addr..p.addr + 4].clone_from_slice(&patchval.to_le_bytes());

    true
}
