#include <cstdio>

#include <verilated.h>

#include "Vcore__Syms.h"

bool debug = false;

#define DEBUG(fmt, ...)                                                        \
    ({                                                                         \
        if (debug) printf(fmt __VA_OPT__(, ) __VA_ARGS__);                     \
    })

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

u8 mem[0x10000];

Vcore model;

long cycles = 0;

bool done = false;
u32 exit_code;

enum class IoPort {
    HALT = 0x0000,
    COUT = 0x0001,
    CLK = 0x0002,
    TMRCNT = 0x0003,
    TMRVAL = 0x0004,
};

u32 tmrval;
u32 tmrreset;
union {
    u32 raw;
    struct {
        bool ena : 1;
        bool irqena : 1;
        bool irqpend : 1;
        bool repeat : 1;
    };
} tmrcnt;

u32 rio(u16 port) {
    switch (static_cast<IoPort>(port)) {
        case IoPort::CLK:
            return cycles;
        case IoPort::TMRCNT:
            return tmrcnt.raw;
        case IoPort::TMRVAL:
            return tmrval;
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
        case IoPort::TMRCNT: {
            bool old_ena = tmrcnt.ena;
            tmrcnt.raw = data;
            if (tmrcnt.ena && !old_ena) {
                tmrval = tmrreset;
            }
            break;
        }
        case IoPort::TMRVAL:
            tmrreset = data;
            break;
    }
}

void handle_timer() {
    if (tmrcnt.ena) {
        if (++tmrval == 0) {
            tmrval = tmrreset;
            tmrcnt.irqpend = 1;
            if (!tmrcnt.repeat) tmrcnt.ena = 0;
            DEBUG("\ttimer overflowed\n");
        }
    }
    model.irq = tmrcnt.irqena && tmrcnt.irqpend;
}

void dump() {
    DEBUG("\tpipe: IF:%x ", model.core->IF->pc);
    if (model.core->s_id->bubble) {
        DEBUG("ID:() ");
    } else {
        DEBUG("ID:%x ", model.core->ID->pc);
    }
    if (model.core->s_ex->bubble) {
        DEBUG("EX:() ");
    } else {
        DEBUG("EX:%x ", model.core->EX->pc);
    }
    if (model.core->s_mem->bubble) {
        DEBUG("MEM:() ");
    } else {
        DEBUG("MEM:%x ", model.core->MEM->pc);
    }
    if (model.core->s_wb->bubble) {
        DEBUG("WB:() ");
    } else {
        DEBUG("WB:%x ", model.core->WB->pc);
    }
    DEBUG("\n\t");
    const char* reg_names[] = {
        "zr", "sp", "a0", "a1", "a2", "a3",  "a4",  "a5",  "a6",  "a7", "t0",
        "t1", "t2", "t3", "t4", "t5", "t6",  "s0",  "s1",  "s2",  "s3", "s4",
        "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "s13", "lr"};
    for (int i = 0; i < 32; i++) {
        DEBUG("%s=%x ", reg_names[i], model.core->regs[i]);
        if (i % 8 == 7) DEBUG("\n\t");
    }
    const char* conditions[4] = {"GT", "EQ", "LT", "??"};
    DEBUG("cr=%s\n", conditions[model.core->cmp_reg]);
    DEBUG("\tie=%x sie=%x scr=%s elr=%x einfo=%x\n", model.core->e->ie,
          model.core->e->saved_ie, conditions[model.core->e->saved_cr],
          model.core->e->saved_pc, model.core->e->exn_info);

    DEBUG("\tirq=%d\n", model.irq);

    // DEBUG("\tIF=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__if_out).c_str());
    // DEBUG("\tID=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__id_out).c_str());
    // DEBUG("\tEX=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__ex_out).c_str());
    // DEBUG("\tMEM=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__mem_out).c_str());
    // DEBUG("\tWB=%s\n",
    // VL_TO_STRING(model.rootp->core__DOT__wb_out).c_str());
}

void handle_bus() {
    model.idata = *(u32*) &mem[model.iaddr];
    DEBUG("\tfetch [%x]=%08x\n", model.iaddr, model.idata);
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
        DEBUG("\tmem read %d [%x]=%x\n", 8 << model.mem_sz, model.mem_addr,
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
        DEBUG("\tmem write %d [%x]=%x\n", 8 << model.mem_sz, model.mem_addr,
              model.mem_wdata);
    }
    if (model.io_r) {
        model.io_rdata = rio(model.io_addr);
        DEBUG("\tio read [%x]=%x\n", model.io_addr, model.io_rdata);
    } else if (model.io_w) {
        wio(model.io_addr, model.io_wdata);
        DEBUG("\tio write [%x]=%x\n", model.io_addr, model.io_wdata);
    }
}

void step() {
    DEBUG("cycle: %ld\n", cycles);

    model.clk = 1;
    model.eval();
    model.rst = 0;
    model.clk = 0;
    model.eval();

    dump();

    handle_bus();
    handle_timer();

    cycles++;
}

int main(int argc, char** argv) {

    argc--;
    argv++;
    while (argc > 0) {
        if ((*argv)[0] == '-') {
            for (char* p = &(*argv)[1]; *p; p++) {
                switch (*p) {
                    case 'd':
                        debug = true;
                        break;
                }
            }
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
