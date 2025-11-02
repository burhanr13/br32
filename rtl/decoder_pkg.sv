package decoder_pkg;

    typedef struct {
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

        logic op2_imm;

        logic [31:0] imm;
        logic [31:0] branch_off;

        logic branch_op1;

        logic undefined;
    } decoded_t;

endpackage
