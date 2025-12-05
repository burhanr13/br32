#include <SDL3/SDL.h>
#include <cstdio>

#include <verilated.h>

#include "Vtop.h"
#include "Vtop__Syms.h"

bool debug = false;

#define DEBUG(fmt, ...)                                                        \
    ({                                                                         \
        if (debug) printf(fmt __VA_OPT__(, ) __VA_ARGS__);                     \
    })

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

#define CLK_SPEED 5'000'000
#define SAMPLE_RATE m

SDL_AudioStream* audioStream;

Vtop* model;
Vtop_top* top;

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

int cur_sample = 0;
u8 audio_buf[1024];
int audio_idx;

void rio(u16 port, u32& data) {
    switch (static_cast<IoPort>(port)) {
        case IoPort::HALT:
        case IoPort::COUT: break;
        case IoPort::CLK: data = cycles; break;
        case IoPort::TMRCNT: data = tmrcnt.raw; break;
        case IoPort::TMRVAL: data = tmrval; break;
    }
}

void wio(u16 port, u32 data) {
    switch (static_cast<IoPort>(port)) {
        case IoPort::HALT:
            exit_code = data;
            done = true;
            break;
        case IoPort::COUT: fputc(data, stdout); break;
        case IoPort::CLK: break;
        case IoPort::TMRCNT: {
            bool old_ena = tmrcnt.ena;
            tmrcnt.raw = data;
            if (tmrcnt.ena && !old_ena) {
                tmrval = tmrreset;
            }
            break;
        }
        case IoPort::TMRVAL: tmrreset = data; break;
    }
}

void handle_timer() {
    if (tmrcnt.ena) {
        if (++tmrval == 0) {
            tmrval = tmrreset;
            tmrcnt.irqpend = 1;
            if (!tmrcnt.repeat) tmrcnt.ena = 0;
            DEBUG("\ttimer overflowed\n");
            // cur_sample = !cur_sample;
        }
    }
    top->irq = tmrcnt.irqena && tmrcnt.irqpend;
}

void dump() {
    DEBUG("\tpipe: IF:%x ", top->core0->IF->pc);
    if (top->core0->s_id->bubble) {
        DEBUG("ID:(%x) ", top->core0->ID->__PVT__nextpc);
    } else {
        DEBUG("ID:%x ", top->core0->ID->pc);
    }
    if (top->core0->s_ex->bubble) {
        DEBUG("EX:(%x) ", top->core0->EX->__PVT__nextpc);
    } else {
        DEBUG("EX:%x ", top->core0->EX->pc);
    }
    if (top->core0->s_mem->bubble) {
        DEBUG("MEM:(%x) ", top->core0->MEM->__PVT__nextpc);
    } else {
        DEBUG("MEM:%x ", top->core0->MEM->pc);
    }
    if (top->core0->s_wb->bubble) {
        DEBUG("WB:() ");
    } else {
        DEBUG("WB:%x ", top->core0->WB->pc);
    }
    DEBUG("\n\t");
    const char* reg_names[] = {
        "zr", "sp", "a0", "a1", "a2", "a3",  "a4",  "t0",  "t1", "t2", "t3",
        "t4", "t5", "t6", "t7", "t8", "t9",  "s0",  "s1",  "s2", "s3", "s4",
        "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "fp", "lr"};
    for (int i = 0; i < 32; i++) {
        DEBUG("%s=%x ", reg_names[i], top->core0->regs->read(i));
        if (i % 8 == 7) DEBUG("\n\t");
    }
    const char* conditions[4] = {"GT", "EQ", "LT", "??"};
    DEBUG("cr=%s\n", conditions[top->core0->cmp_reg]);
    DEBUG("\tie=%x sie=%x scr=%s elr=%x einfo=%x\n", top->core0->e->ie,
          top->core0->e->saved_ie, conditions[top->core0->e->saved_cr],
          top->core0->e->saved_pc, top->core0->e->exn_info);

    DEBUG("\tirq=%d\n", top->irq);

    // DEBUG("\tIF=%s\n",
    // VL_TO_STRING(top.rootp->core__DOT__if_out).c_str());
    // DEBUG("\tID=%s\n",
    // VL_TO_STRING(top.rootp->core__DOT__id_out).c_str());
    // DEBUG("\tEX=%s\n",
    // VL_TO_STRING(top.rootp->core__DOT__ex_out).c_str());
    // DEBUG("\tMEM=%s\n",
    // VL_TO_STRING(top.rootp->core__DOT__mem_out).c_str());
    // DEBUG("\tWB=%s\n",
    // VL_TO_STRING(top.rootp->core__DOT__wb_out).c_str());
}

void handle_mem() {
    // static u32 next_rdata;
    // if (model->clk) {
    //     if (top->mem_r) {
    //         next_rdata = *(u32*) &top->mem.m_storage[(top->mem_addr & ~3) %
    //                                                  sizeof
    //                                                  top->mem.m_storage];
    //         DEBUG("\tmem %s %d [%x]=%x\n", top->fetch ? "fetch" : "read",
    //               8 << top->mem_sz, top->mem_addr, next_rdata);
    //     } else if (top->mem_w) {
    //         switch (top->mem_sz) {
    //             case 0:
    //                 *(u8*) &top->mem
    //                      .m_storage[top->mem_addr % sizeof
    //                      top->mem.m_storage] =
    //                     top->mem_wdata;
    //                 break;
    //             case 1:
    //                 *(u16*) &top->mem
    //                      .m_storage[top->mem_addr % sizeof
    //                      top->mem.m_storage] =
    //                     top->mem_wdata;
    //                 break;
    //             case 2:
    //                 *(u32*) &top->mem
    //                      .m_storage[top->mem_addr % sizeof
    //                      top->mem.m_storage] =
    //                     top->mem_wdata;
    //                 break;
    //         }
    //         DEBUG("\tmem write %d [%x]=%x\n", 8 << top->mem_sz,
    //         top->mem_addr,
    //               top->mem_wdata);
    //     }
    // } else {
    //     top->mem_rdata = next_rdata;
    // }
}

void handle_io() {
    if (top->io_r) {
        rio(top->io_addr, top->io_rdata);
        DEBUG("\tio read [%x]=%x\n", top->io_addr, top->io_rdata);
    } else if (top->io_w) {
        wio(top->io_addr, top->io_wdata);
        DEBUG("\tio write [%x]=%x\n", top->io_addr, top->io_wdata);
    }
    handle_timer();
}

void step() {
    DEBUG("cycle: %ld\n", cycles);

    // if (cycles % (CLK_SPEED / SAMPLE_RATE) == 0) {
    //     audio_buf[audio_idx++] = cur_sample ? 0xff : 0;
    //     if (audio_idx == sizeof audio_buf / sizeof audio_buf[0]) {
    //         audio_idx = 0;
    //         SDL_PutAudioStreamData(audioStream, audio_buf, sizeof audio_buf);
    //     }
    // }

    model->clk = 1;
    handle_mem();
    model->eval();
    Verilated::timeInc(5);
    model->clk = 0;
    handle_mem();
    handle_io();
    model->eval();
    model->rstn = 1;
    Verilated::timeInc(5);

    dump();

    cycles++;
}

int main(int argc, char** argv) {
    auto modelp = std::make_unique<Vtop>();
    model = modelp.get();
    top = model->top;

    argc--;
    argv++;
    while (argc > 0) {
        if ((*argv)[0] == '-') {
            for (char* p = &(*argv)[1]; *p; p++) {
                switch (*p) {
                    case 'd': debug = true; break;
                }
            }
        } else {
            FILE* fp = fopen(*argv, "rb");
            if (fp) {
                u8 code[4 * sizeof top->ram0];
                int ct = fread(code, 1, sizeof code, fp);
                fclose(fp);
                for (int i = 0; i < ct; i += 4) {
                    top->ram0[i >> 2] = code[i + 0];
                    top->ram1[i >> 2] = code[i + 1];
                    top->ram2[i >> 2] = code[i + 2];
                    top->ram3[i >> 2] = code[i + 3];
                }
            } else {
                perror("fopen");
                return 1;
            }
        }
        argc--;
        argv++;
    }

    Verilated::traceEverOn(true);

    // if (!SDL_Init(SDL_INIT_AUDIO)) printf("audio init failed\n");
    // SDL_AudioSpec as = {
    //     .format = SDL_AUDIO_U8, .channels = 1, .freq = SAMPLE_RATE};
    // audioStream =
    // SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
    //                                         &as, nullptr, nullptr);
    // SDL_ResumeAudioStreamDevice(audioStream);

    model->rstn = 0;
    model->clk = 0;
    model->eval();
    Verilated::timeInc(5);

    while (!done) {
        step();
    }

    // SDL_DestroyAudioStream(audioStream);
    // SDL_Quit();

    return exit_code;
}
