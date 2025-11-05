package pipeline_pkg;
    import decoder_pkg::*;

    typedef struct {
        logic [31:0] pc, nextpc;

        logic [31:0] instr;

        logic bubble;
    } if_out_t;

    typedef struct {
        logic [31:0] pc, nextpc;

        decoded_t dec;

        logic [31:0] op1, op2;

        logic cond_true;
        logic branch;
        logic [31:0] branch_dest;

        logic bubble, stall;
    } id_out_t;

    typedef struct {
        logic [31:0] pc, nextpc;

        logic [31:0] alu_res;
        logic [1:0] cmp_res;
        logic [31:0] op3;
        logic [4:0] rd;
        logic w_rd;
        logic w_cr;

        logic link;

        logic mem_r;
        logic mem_w;
        logic [1:0] mem_sz;
        logic mem_sx;

        logic io_r;
        logic io_w;

        logic mfsr, mtsr;
        logic mfcr;

        logic scall, eret;
        logic udf;

        logic bubble;
    } ex_out_t;

    typedef struct {
        logic [31:0] pc, nextpc;

        logic [31:0] res;
        logic [4:0] rd;
        logic w_rd;
        logic [1:0] cmp_res;
        logic w_cr;

        logic [31:0] op3;
        logic [31:0] alu_res;

        logic mtsr;

        logic scall, eret;
        logic udf;

        logic bubble;
    } mem_out_t;

    typedef struct {
        logic [31:0] pc;

        logic [31:0] res;
        logic [4:0] rd;
        logic w_rd;

        logic bubble;
    } wb_out_t;

endpackage
