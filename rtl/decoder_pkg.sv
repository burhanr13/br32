package decoder_pkg;

    typedef struct packed {
        logic [4:0] rd;
        logic w_rd;
        logic [4:0] rs1;
        logic r_rs1;
        logic [4:0] rs2;
        logic r_rs2;
        logic [4:0] rs3;
        logic r_rs3;

        logic r_flags;
        logic w_flags;

        logic branch;
        logic link;

        logic [5:0] alu_opc;
        logic [2:0] cond_code;

        logic op1_pc;
        logic op2_imm;

        logic [31:0] imm;
        logic [31:0] branch_off;

        logic branch_op1;

        logic mem_r;
        logic mem_w;
        logic [1:0] mem_sz;
        logic op2_shift;
        logic mem_sx;

        logic io_r;
        logic io_w;

        logic undefined;
    } decoded_t;

endpackage
