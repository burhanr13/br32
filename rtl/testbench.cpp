#include <cstdio>

#include <verilated.h>

#include "Vcore.h"
#include "Vcore___024root.h"

bool bus_trace = false;
bool cpu_trace = false;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

u8 mem[0x10000];

Vcore model;

long cycles = 0;

bool done = false;
u32 exit_code;

enum class IoPort { HALT = 0x0000, COUT = 0x0001, CLK = 0x0002 };

u32 rio(u16 port) {
    switch (static_cast<IoPort>(port)) {
        case IoPort::CLK:
            return cycles;
        default:
            return 0;
    }
}

void wio(u16 port, u32 data) {
    switch (static_cast<IoPort>(port)) {
        case IoPort::HALT:
            exit_code = data;
            done = true;
            break;
        case IoPort::COUT:
            fputc(data, stdout);
            break;
        case IoPort::CLK:
            break;
    }
}

void dump() {
    printf("\tpipe: IF:%x ", model.rootp->core__DOT__IF__DOT__pc);
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
    printf("\n\t");
    const char* reg_names[] = {
        "zr", "sp", "a0", "a1", "a2", "a3",  "a4",  "a5",  "a6",  "a7", "t0",
        "t1", "t2", "t3", "t4", "t5", "t6",  "s0",  "s1",  "s2",  "s3", "s4",
        "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "s13", "lr"};
    for (int i = 0; i < 32; i++) {
        printf("%s=%x ", reg_names[i], model.rootp->core__DOT__regs[i]);
        if (i % 8 == 7) printf("\n\t");
    }
    const char* conditions[4] = {"GT", "EQ", "LT", "??"};
    printf("cr=%s\n", conditions[model.rootp->core__DOT__cmp_res]);

    // printf("\tIF=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__if_out).c_str());
    // printf("\tID=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__id_out).c_str());
    // printf("\tEX=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__ex_out).c_str());
    // printf("\tMEM=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__mem_out).c_str());
    // printf("\tWB=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__wb_out).c_str());
}

void handle_bus() {
    model.idata = *(u32*) &mem[model.iaddr];
    if (bus_trace) printf("\tfetch [%x]=%08x\n", model.iaddr, model.idata);
    if (model.mem_r) {
        switch (model.mem_sz) {
            case 0:
                model.mem_rdata = *(u8*) &mem[model.mem_addr];
                break;
            case 1:
                model.mem_rdata = *(u16*) &mem[model.mem_addr];
                break;
            case 2:
                model.mem_rdata = *(u32*) &mem[model.mem_addr];
                break;
        }
        if (bus_trace)
            printf("\tmem read %d [%x]=%x\n", 8 << model.mem_sz, model.mem_addr,
                   model.mem_rdata);
    } else if (model.mem_w) {
        switch (model.mem_sz) {
            case 0:
                *(u8*) &mem[model.mem_addr] = model.mem_wdata;
                break;
            case 1:
                *(u16*) &mem[model.mem_addr] = model.mem_wdata;
                break;
            case 2:
                *(u32*) &mem[model.mem_addr] = model.mem_wdata;
                break;
        }
        if (bus_trace)
            printf("\tmem write %d [%x]=%x\n", 8 << model.mem_sz,
                   model.mem_addr, model.mem_wdata);
    }
    if (model.io_r) {
        model.io_rdata = rio(model.io_addr);
        if (bus_trace)
            printf("\tio read [%x]=%x\n", model.io_addr, model.io_rdata);
    } else if (model.io_w) {
        wio(model.io_addr, model.io_wdata);
        if (bus_trace)
            printf("\tio write [%x]=%x\n", model.io_addr, model.io_wdata);
    }
}

void step() {
    if (bus_trace || cpu_trace) printf("cycle: %ld\n", cycles);

    model.clk = 1;
    model.eval();
    model.rst = 0;
    model.clk = 0;
    model.eval();

    if (cpu_trace) dump();

    handle_bus();

    cycles++;
}

int main(int argc, char** argv) {

    argc--;
    argv++;
    while (argc > 0) {
        if (!strcmp(*argv, "-d")) {
            cpu_trace = true;
        } else if (!strcmp(*argv, "-b")) {
            bus_trace = true;
        } else {
            FILE* fp = fopen(*argv, "rb");
            if (fp) {
                fread(mem, 1, sizeof(mem), fp);
                fclose(fp);
            } else {
                perror("fopen");
                return 1;
            }
        }
        argc--;
        argv++;
    }

    model.rst = 1;
    model.clk = 0;
    model.eval();
    while (!done) {
        step();
    }

    return exit_code;
}
