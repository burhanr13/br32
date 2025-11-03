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

        logic [31:0] branch_dest;

        logic bubble, stall;
    } id_out_t;

    typedef struct {
        logic [31:0] pc, nextpc;

        logic [31:0] alu_res;
        logic [31:0] op3;
        logic [4:0] rd;
        logic w_rd;

        logic branch, link;
        logic [31:0] branch_dest;

        logic mem_r;
        logic mem_w;
        logic [1:0] mem_sz;
        logic mem_sx;

        logic io_r;
        logic io_w;

        logic bubble;
    } ex_out_t;

    typedef struct {
        logic [31:0] pc;

        logic [31:0] res;
        logic [4:0] rd;
        logic w_rd;

        logic mem_r;
        logic [1:0] mem_sz;
        logic mem_sx;

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
