package decoder_pkg;

    typedef enum {
        OP2_REG   = 0,
        OP2_IMM16,
        OP2_IMM26
    } op2_e;

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

        logic op1_pc;

        op2_e op2_type;
        logic [31:0] imm16;
        logic [31:0] imm26;

        logic undefined;
    } decoded_t;

endpackage
