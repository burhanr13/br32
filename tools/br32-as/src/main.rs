mod assembler;
mod disassembler;
mod tokenize;

use std::{collections::HashMap, fs::File, io::BufReader};

use clap::Parser;

use crate::{
    assembler::{Patch, Sym},
    tokenize::Token,
};

#[derive(Default)]
struct State {
    fp: Option<BufReader<File>>,
    file: String,
    line: u32,

    nextchar: Option<u8>,
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

#[derive(Parser)]
struct Args {
    #[arg(required = true)]
    infiles: Vec<String>,

    #[arg(short = 'o', default_value = "a.out")]
    outfile: String,

    #[arg(short, long)]
    disas: bool,
    #[arg(short = 's', long = "emit-syms")]
    emitsyms: bool,
}

fn main() {
    let a = Args::parse();
    if a.disas {
        disassembler::disassemble(&a.infiles[0]);
        return;
    }
    let mut s = State::default();
    for file in a.infiles {
        s.assemble(&file);
    }
    s.output(a.outfile, a.emitsyms);
}
