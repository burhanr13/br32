#include <cstdio>

#include <verilated.h>

#include "Vcore.h"
#include "Vcore___024root.h"

unsigned char mem[0x10000];

Vcore model;

unsigned int cycles = 0;

bool done = false;

void dump() {
    printf("\tpipe: IF:%x ", model.rootp->core__DOT__if_out.__PVT__pc);
    if (model.rootp->core__DOT__ID__DOT__bubble) {
        printf("ID:() ");
    } else {
        printf("ID:%x ", model.rootp->core__DOT__ID__DOT__pc);
    }
    if (model.rootp->core__DOT__EX__DOT__bubble) {
        printf("EX:() ");
    } else {
        printf("EX:%x ", model.rootp->core__DOT__EX__DOT__pc);
    }
    if (model.rootp->core__DOT__MEM__DOT__bubble) {
        printf("MEM:() ");
    } else {
        printf("MEM:%x ", model.rootp->core__DOT__MEM__DOT__pc);
    }
    if (model.rootp->core__DOT__WB__DOT__bubble) {
        printf("WB:() ");
    } else {
        printf("WB:%x ", model.rootp->core__DOT__WB__DOT__pc);
    }
    printf("\n");
    printf("\t");
    for (int i = 0; i < 32; i++) {
        printf("r%d=%x ", i, model.rootp->core__DOT__regs[i]);
        if (i % 8 == 7) printf("\n\t");
    }
    const char* flag_names[4] = {"GT", "EQ", "LT", "??"};
    printf("flags=%s\n", flag_names[model.rootp->core__DOT__EX__DOT__flags]);

    if (0x54 == model.rootp->core__DOT__WB__DOT__pc) done = true;
}

void step() {
    printf("cycle: %d\n", cycles);

    model.clk = 1;
    model.eval();
    model.rst = 0;
    model.clk = 0;
    model.data = *(int*) &mem[model.addr];
    printf("\tfetch [%x]=%08x\n", model.addr, model.data);
    model.eval();

    dump();

    cycles++;
}

int main(int argc, char** argv) {

    if (argc == 2) {
        FILE* fp = fopen(argv[1], "rb");
        if (fp) {
            fread(mem, 1, sizeof(mem), fp);
            fclose(fp);
        }
    }

    model.rst = 1;
    model.clk = 0;
    model.eval();
    while (!done) {
        step();
    }
}
