#[macro_use]
mod assembler;
mod disassembler;
mod tokenize;

use clap::Parser;

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
    let mut s = assembler::State::default();
    for file in a.infiles {
        assembler::assemble(&mut s, &file);
    }
    assembler::output(&mut s, a.outfile, a.emitsyms);
}
