use std::{
    fs::File,
    io::{BufRead, BufReader, Read},
};

const REGS: [&str; 32] = [
    "zr", "sp", "a0", "a1", "a2", "a3", "a4", "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8",
    "t9", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "fp",
    "lr",
];

const CONDS: [&str; 8] = ["gt", "le", "eq", "ne", "lt", "ge", "xx", "xx"];

pub fn disassemble(filename: &str) {
    let Ok(mut fp) = File::open(filename).map(BufReader::new) else {
        panic!("cannot open file");
    };

    let mut symfp = File::open(format!("{}.syms", filename))
        .map(BufReader::new)
        .ok();

    let mut addr = 0;

    let mut nextlabel: Option<(u32, String)> = None;

    let mut buf = [0; 4];
    while let Ok(()) = fp.read_exact(&mut buf) {
        if nextlabel.is_none()
            && let Some(sfp) = symfp.as_mut()
        {
            let mut l = String::new();
            if let Ok(_) = sfp.read_line(&mut l)
                && let Some((l, r)) = l.split_once(':')
                && let Ok(a) = u32::from_str_radix(l, 16)
            {
                nextlabel = Some((a, r.trim().to_string()));
            }
        }

        if let Some((a, l)) = nextlabel.as_ref()
            && *a == addr
        {
            println!("{:08x}:           {}:", addr, l);
            nextlabel = None;
        }

        let instr = u32::from_le_bytes(buf);
        print!("{:08x}: {:08x}:   ", addr, instr);

        let rd = (instr >> 6 & 31) as usize;
        let ra = (instr >> 11 & 31) as usize;
        let rb = (instr >> 16 & 31) as usize;
        let mut imm = instr >> 16;

        match instr >> 4 & 3 {
            0 => {
                let opc = instr & 15;
                match opc {
                    8..=0xd => {
                        print!(
                            "b{} {:08x}",
                            CONDS[opc as usize & 7],
                            addr as isize + ((instr as i32) >> 4) as isize
                        );
                    }
                    0xe => {
                        print!("jp {:08x}", addr as isize + ((instr as i32) >> 4) as isize);
                    }
                    0xf => {
                        print!("jl {:08x}", addr as isize + ((instr as i32) >> 4) as isize);
                    }
                    _ => print!("udf"),
                }
            }
            1 => {
                let opc = instr & 15;
                if opc & 8 != 0 {
                    imm <<= 16
                }
                if opc & 4 != 0 {
                    if opc & 3 == 0 {
                        imm = imm.wrapping_neg();
                    } else {
                        imm = !imm;
                    }
                }
                let opstr = match opc & 3 {
                    0 => "addi",
                    1 => "andi",
                    2 => "ori",
                    3 => "xori",
                    _ => unreachable!(),
                };

                if opc & 3 == 0 {
                    let simm = imm as i32;
                    if simm >= 0 {
                        print!("addi {}, {}, {}", REGS[rd], REGS[ra], simm);
                    } else {
                        print!("subi {}, {}, {}", REGS[rd], REGS[ra], -simm);
                    }
                } else {
                    print!("{} {}, {}, {:#x}", opstr, REGS[rd], REGS[ra], imm);
                }
            }
            2 => {
                let opc = instr & 15;
                if opc & 3 == 3 || opc >> 2 & 3 == 3 || opc == 9 {
                    print!("udf");
                } else {
                    let st = opc & 2 != 0;
                    let s = opc & 1 != 0;
                    let sz = opc >> 2 & 3;
                    let szstr = ["b", "h", "w"];
                    print!(
                        "{}{}{} {}, {}({})",
                        if st { "st" } else { "ld" },
                        szstr[sz as usize],
                        if s { "s" } else { "" },
                        REGS[rd],
                        imm as i16,
                        REGS[ra]
                    );
                }
            }
            3 => {
                let opc = instr & 15;
                match opc {
                    0 => print!("mfio {}, {:#x}({})", REGS[rd], imm, REGS[ra]),
                    1 => print!("mtio {}, {:#x}({})", REGS[rd], imm, REGS[ra]),
                    8 => {
                        let opc = rd as u32;
                        if opc & 16 != 0 {
                            if opc == 0x10 {
                                print!("jpr {}", REGS[ra]);
                            } else if opc == 0x11 {
                                print!("jlr {}", REGS[ra]);
                            }
                        } else {
                            if opc & 8 != 0 {
                                imm <<= 16
                            }
                            if opc & 3 != 2 && opc & 4 == 0 {
                                imm = imm.wrapping_neg();
                            }
                            if opc & 3 == 2 && opc & 4 != 0 {
                                imm = !imm;
                            }
                            match opc & 3 {
                                0 => print!("scmpi {}, {}", REGS[ra], imm as i32),
                                1 => print!("ucmpi {}, {}", REGS[ra], imm),
                                2 => print!("tsti {}, {:#x}", REGS[ra], imm),
                                _ => print!("udf"),
                            }
                        }
                    }
                    9 => {
                        let imm1 = instr >> 16 & 31;
                        let imm2 = instr >> 21 & 31;
                        let opc = instr >> 26;
                        match opc {
                            0 => print!("rormi {}, {}, {}, {}", REGS[rd], REGS[ra], imm1, imm2),
                            4 => print!("rolmi {}, {}, {}, {}", REGS[rd], REGS[ra], imm1, imm2),
                            8 => print!("rorsmi {}, {}, {}, {}", REGS[rd], REGS[ra], imm1, imm2),
                            _ => print!("udf"),
                        }
                    }
                    0xb => {
                        print!(
                            "adr {}, {:08x}",
                            REGS[rd],
                            addr as isize + ((instr as i32) >> 11) as isize
                        );
                    }
                    0xd => {
                        let opc = ra;
                        match opc {
                            0 => {
                                print!("scall {:#x}", imm);
                            }
                            1 => print!("eret"),
                            4 => print!("mfsr {}, {:#x}", REGS[rd], imm),
                            5 => print!("mtsr {}, {:#x}", REGS[rd], imm),
                            6 => print!("mfcr {}", REGS[rd]),
                            7 => print!("mtcr {}", REGS[rd]),
                            _ => print!("udf"),
                        }
                    }
                    0xe => {
                        let opc = instr >> 21;
                        if opc < 0x40 {
                            let cc = opc & 7;
                            let opstr = match opc {
                                0x00 => "add",
                                0x01 => "and",
                                0x02 => "or",
                                0x03 => "xor",
                                0x04 => "sub",
                                0x05 => "andn",
                                0x06 => "orn",
                                0x07 => "xorn",
                                0x10 => "srl",
                                0x11 => "sll",
                                0x12 => "sra",
                                0x14 => "ror",
                                0x15 => "rol",
                                0x22 => "tst",
                                0x24 => "scmp",
                                0x25 => "ucmp",
                                0x26 => "tstn",
                                0x30..0x38 => "sel",
                                0x38..0x40 => "sinc",
                                _ => "udf",
                            };
                            if opc >> 4 == 3 {
                                print!(
                                    "{}{} {}, {}, {}",
                                    opstr, CONDS[cc as usize], REGS[rd], REGS[ra], REGS[rb]
                                );
                            } else if opc >> 4 == 2 {
                                print!("{} {}, {}", opstr, REGS[ra], REGS[rb]);
                            } else {
                                print!("{} {}, {}, {}", opstr, REGS[rd], REGS[ra], REGS[rb]);
                            }
                        } else if opc >= 0x7c0 {
                            if opc & 3 == 3 && opc >> 2 & 3 != 3 && opc & 16 != 0 {
                                print!(
                                    "addx {}, ({}, {}, {})",
                                    REGS[rd],
                                    REGS[ra],
                                    REGS[rb],
                                    1 << (opc >> 2 & 3)
                                )
                            } else if opc & 3 == 3 || opc >> 2 & 3 == 3 || opc == 9 {
                                print!("udf");
                            } else {
                                let st = opc & 2 != 0;
                                let s = opc & 1 != 0;
                                let sz = opc >> 2 & 3;
                                let szstr = ["b", "h", "w"];
                                print!(
                                    "{}{}{}x {}, ({}, {}",
                                    if st { "st" } else { "ld" },
                                    szstr[sz as usize],
                                    if s { "s" } else { "" },
                                    REGS[rd],
                                    REGS[ra],
                                    REGS[rb]
                                );
                                if opc & 16 != 0 {
                                    print!(", {})", 1 << sz);
                                } else {
                                    print!(")");
                                }
                            }
                        }
                    }
                    _ => print!("udf"),
                }
            }
            _ => unreachable!(),
        }

        println!();
        addr += 4;
    }
}
