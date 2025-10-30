#include <stdint.h>
#include <string.h>

typedef uint8_t u8;
typedef int8_t s8;
typedef uint16_t u16;
typedef int16_t s16;
typedef uint32_t u32;
typedef int32_t s32;
typedef uint64_t u64;
typedef int64_t s64;

#define BIT(n) (1 << n)
#define MASK(n) (BIT(n) - 1)

enum {
    E_RESET,
    E_SCALL,
    E_UND,
    E_MEM,
    E_DIV0,
    E_IRQ,
};

#define RESET_VEC 0xff000000

typedef struct {
    u32 r[32];
    u32 pc;

    union {
        struct {
            union {
                u32 flags;
                struct {
                    bool eq : 1;
                    bool lt : 1;
                    u32 : 14;
                    bool user : 1;
                };
            };
            u32 slr;
            u32 sflags;
            u32 exnarg;
            struct {
                u32 prot_on : 1;
                u32 : 15;
                u32 prot_perms : 16;
            } memctrl;
            struct {
                u32 sz : 16;
                u32 start : 16;
            } memregs[8];
        };
        u32 sr[32];
    };

    void* mem;

    u32 (*rio)(u16 n);
    void (*wio)(u16 n, u32 d);
} Cpu;

#define SR(n) ((offsetof(Cpu, n) - offsetof(Cpu, sr)) / 4)

#define MEM(a, sz) (*(u##sz*) (cpu->mem + a))

bool eval_cond(Cpu* vm, u32 cond) {
    return ((cond >> 1) == (vm->flags & 3)) != (cond & 1);
}

void exception(Cpu* cpu, u32 e) {
    cpu->sflags = cpu->flags;
    cpu->user = false;
    cpu->slr = cpu->pc;
    cpu->pc = RESET_VEC + 4 * e;
}

void undefined(Cpu* cpu, u32 instr) {
    cpu->exnarg = instr;
    exception(cpu, E_UND);
}

void run_instr(Cpu* cpu) {

    cpu->r[0] = 0;

    u32 instr = MEM(cpu->pc, 32);
    cpu->pc += 4;

    u32 opc = instr & MASK(6);

    u32 rd = instr >> 6 & MASK(5);
    u32 ra = instr >> 11 & MASK(5);
    u32 rb = instr >> 16 & MASK(5);
    u32 rc = instr >> 21 & MASK(5);

    switch (opc) {
        case 0x8 ... 0xf: {
            s32 jmp_offs = (s32) instr >> 4;
            if (opc == 0xf) cpu->r[31] = cpu->pc;
            if (opc == 0xe || eval_cond(cpu, opc & 7)) {
                cpu->pc += jmp_offs;
            }
            break;
        }
        case 0x10 ... 0x1f: {
            u32 imm = instr >> 16;
            if (opc & 8) imm <<= 16;
            if (opc & 4) imm = ~imm;
            switch (opc & 3) {
                case 0:
                    cpu->r[rd] = cpu->r[ra] + imm;
                    break;
                case 1:
                    cpu->r[rd] = cpu->r[ra] & imm;
                    break;
                case 2:
                    cpu->r[rd] = cpu->r[ra] | imm;
                    break;
                case 3:
                    cpu->r[rd] = cpu->r[ra] ^ imm;
                    break;
            }
            break;
        }
        case 0x20 ... 0x2f: {
            u32 sh = (opc >> 2) & 3;
            if (sh > 2) sh = 2;
            u32 addr = cpu->r[ra] + ((s32) instr >> 16 << sh);
            switch (opc & 0xf) {
                case 0:
                    cpu->r[rd] = MEM(addr, 8);
                    break;
                case 1:
                    cpu->r[rd] = (s8) MEM(addr, 8);
                    break;
                case 2:
                    MEM(addr, 8) = cpu->r[rd];
                    break;
                case 4:
                    cpu->r[rd] = MEM(addr, 16);
                    break;
                case 5:
                    cpu->r[rd] = (s16) MEM(addr, 16);
                    break;
                case 6:
                    MEM(addr, 16) = cpu->r[rd];
                    break;
                case 8:
                    cpu->r[rd] = MEM(addr, 32);
                    break;
                case 0xa:
                    MEM(addr, 32) = cpu->r[rd];
                    break;
                case 0xc:
                    memcpy(&cpu->r[rd], &MEM(addr, 32), (32 - rd) * 4);
                    break;
                case 0xe:
                    memcpy(&MEM(addr, 32), &cpu->r[rd], (32 - rd) * 4);
                    break;
                default:
                    undefined(cpu, instr);
            }
            break;
        }
        case 0x30:
            if (cpu->user) undefined(cpu, instr);
            else cpu->r[rd] = cpu->rio(cpu->r[ra] + (instr >> 16));
            break;
        case 0x31:
            if (cpu->user) undefined(cpu, instr);
            else cpu->wio(cpu->r[ra] + (instr >> 16), cpu->r[rd]);
            break;
        case 0x34:
            cpu->r[rd] = cpu->pc + ((s32) instr >> 16);
            break;
        case 0x3c: {
            opc = rd;
            switch (opc) {
                case 0x0 ... 0xf: {
                    u32 imm = instr >> 16;
                    if (opc & 8) imm <<= 16;
                    if (opc & 4) imm = ~imm;
                    switch (opc & 3) {
                        case 0:
                            cpu->eq = cpu->r[ra] == imm;
                            cpu->lt = (s32) cpu->r[ra] < (s32) imm;
                            break;
                        case 1:
                            cpu->eq = cpu->r[ra] == imm;
                            cpu->lt = cpu->r[ra] < imm;
                            break;
                        case 2:
                            cpu->eq = (cpu->r[ra] & imm) == 0;
                            cpu->lt = (cpu->r[ra] & imm) >> 31;
                            break;
                        default:
                            undefined(cpu, instr);
                    }
                    break;
                }
                default:
                    undefined(cpu, instr);
            }
            break;
        }
        case 0x3e: {
            opc = instr >> 21;
            switch (opc) {
#define BINARY(opc, op)                                                        \
    case opc:                                                                  \
        cpu->r[rd] = cpu->r[ra] op cpu->r[rb];                                 \
        break
                BINARY(0, +);
                BINARY(1, &);
                BINARY(2, |);
                BINARY(3, ^);
                BINARY(4, -);
                BINARY(5, &~);
                BINARY(6, | ~);
                BINARY(7, ^~);
#undef BINARY
                case 8:
                    cpu->r[rd] = cpu->r[ra] >> (cpu->r[rb] & 31);
                    break;
                case 9:
                    cpu->r[rd] = cpu->r[ra] << (cpu->r[rb] & 31);
                    break;
                case 0xa:
                    cpu->r[rd] =
                        __builtin_rotateright32(cpu->r[ra], cpu->r[rb] & 31);
                    break;
                case 0xb:
                    cpu->r[rd] =
                        __builtin_rotateleft32(cpu->r[ra], cpu->r[rb] & 31);
                    break;
                case 0xc:
                    cpu->r[rd] = (s32) cpu->r[ra] >> (cpu->r[rb] & 31);
                    break;
                case 0x10:
                    cpu->eq = cpu->r[ra] == cpu->r[rb];
                    cpu->lt = (s32) cpu->r[ra] < (s32) cpu->r[rb];
                    break;
                case 0x11:
                    cpu->eq = cpu->r[ra] == cpu->r[rb];
                    cpu->lt = cpu->r[ra] < cpu->r[rb];
                    break;
                case 0x12:
                    cpu->eq = (cpu->r[ra] & cpu->r[rb]) == 0;
                    cpu->lt = (cpu->r[ra] & cpu->r[rb]) >> 31;
                    break;
                case 0x20 ... 0x3f: {
                    u32 sh = (opc >> 2) & 3;
                    if (sh > 2) sh = 2;
                    if (!(opc & BIT(4))) sh = 0;
                    u32 addr = cpu->r[ra] + (cpu->r[rb] << sh);
                    switch (opc & 0xf) {
                        case 0:
                            cpu->r[rd] = MEM(addr, 8);
                            break;
                        case 1:
                            cpu->r[rd] = (s8) MEM(addr, 8);
                            break;
                        case 2:
                            MEM(addr, 8) = cpu->r[rd];
                            break;
                        case 4:
                            cpu->r[rd] = MEM(addr, 16);
                            break;
                        case 5:
                            cpu->r[rd] = (s16) MEM(addr, 16);
                            break;
                        case 6:
                            MEM(addr, 16) = cpu->r[rd];
                            break;
                        case 8:
                            cpu->r[rd] = MEM(addr, 32);
                            break;
                        case 0xa:
                            MEM(addr, 32) = cpu->r[rd];
                            break;
                        case 0x3:
                        case 0x7:
                        case 0xb:
                            cpu->r[rd] = addr;
                            break;
                        case 0xd:
                            cpu->r[31] = cpu->pc;
                            [[fallthrough]];
                        case 0xc:
                            cpu->pc = MEM(addr, 32);
                            break;
                        case 0xf:
                            cpu->r[31] = cpu->pc;
                            [[fallthrough]];
                        case 0xe:
                            cpu->pc = addr;
                            break;
                        default:
                            undefined(cpu, instr);
                    }
                    break;
                }
                case 0x5bf: {
                    opc = rb;
                    switch (opc) {
                        case 0 ... 5:
                            if (eval_cond(cpu, opc & 7)) {
                                cpu->r[rd] = cpu->r[ra];
                            }
                            break;
                        case 8 ... 0xd:
                            if (eval_cond(cpu, opc & 7)) {
                                cpu->r[rd] = cpu->r[ra] + 1;
                            } else {
                                cpu->r[rd] = cpu->r[ra];
                            }
                            break;
                        default:
                            undefined(cpu, instr);
                    }
                    break;
                }
                case 0x5c0 ... 0x5ff: {
                    opc = opc & MASK(6);
                    u32 arg = instr >> 11 & MASK(10);
                    if (opc == 0) {
                        cpu->exnarg = arg;
                        exception(cpu, E_SCALL);
                    } else if (cpu->user) {
                        undefined(cpu, instr);
                    } else {
                        switch (opc) {
                            case 1:
                                cpu->pc = cpu->slr;
                                cpu->flags = cpu->sflags;
                                break;
                            case 4:
                                if (arg * 4 < sizeof cpu->sr)
                                    cpu->r[rd] = cpu->sr[arg];
                                else undefined(cpu, instr);
                                break;
                            case 5:
                                if (arg * 4 < sizeof cpu->sr)
                                    cpu->sr[arg] = cpu->r[rd];
                                else undefined(cpu, instr);
                                break;
                            default:
                                undefined(cpu, instr);
                        }
                    }
                    break;
                }
                case 0x600 ... 0x7ff: {
                    opc = opc >> 5 & 0xf;
                    u32 imm1 = rb;
                    u32 imm2 = rc;
                    switch (opc) {
                        case 0:
                            cpu->r[rd] =
                                (s32) (cpu->r[ra] >> imm1 << (31 - imm2)) >>
                                (31 - imm2);
                            break;
                        case 1:
                            cpu->r[rd] = cpu->r[ra] >> imm1 << (31 - imm2) >>
                                         (31 - imm2);
                            break;
                        case 2:
                            cpu->r[rd] &=
                                ~(~0u << (31 - imm2) >> (31 - imm2) << imm1);
                            cpu->r[rd] |= cpu->r[ra] << (31 - imm2) >>
                                          (31 - imm2) << imm1;
                            break;
                        case 3:
                            cpu->r[rd] = cpu->r[ra] << (31 - imm2) >>
                                         (31 - imm2) << imm1;
                            break;
                        case 4:
                            cpu->r[rd] =
                                ((u64) cpu->r[rb] << 32 | cpu->r[ra]) >> imm2;
                            break;
                        case 8:
                            cpu->r[rd] = cpu->r[rc] + cpu->r[ra] * cpu->r[rb];
                            break;
                        case 9:
                            cpu->r[rd] = cpu->r[rc] - cpu->r[rb] * cpu->r[rb];
                            break;
                        case 0xa: {
                            u64 res =
                                (s64) (s32) cpu->r[ra] * (s64) (s32) cpu->r[rb];
                            cpu->r[rd] = res;
                            cpu->r[rc] = res >> 32;
                            break;
                        }
                        case 0xb: {
                            u64 res = (u64) cpu->r[ra] * (u64) cpu->r[rb];
                            cpu->r[rd] = res;
                            cpu->r[rc] = res >> 32;
                            break;
                        }
                        case 0xc:
                            cpu->r[rd] = (s32) cpu->r[ra] / (s32) cpu->r[rb];
                            cpu->r[rc] = (s32) cpu->r[ra] % (s32) cpu->r[rb];
                            break;
                        case 0xd:
                            cpu->r[rd] = cpu->r[ra] / cpu->r[rb];
                            cpu->r[rc] = cpu->r[ra] % cpu->r[rb];
                            break;
                        default:
                            undefined(cpu, instr);
                    }
                    break;
                }
                default:
                    undefined(cpu, instr);
            }
            break;
        }
        default:
            undefined(cpu, instr);
    }
}
