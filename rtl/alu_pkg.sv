package alu_pkg;

    typedef enum {
        EQ,
        LT
    } cmp_res_e;

    typedef enum {
        ADD  = 0,
        AND,
        OR,
        XOR,
        SUB,
        ANDN,
        ORN,
        XORN,
        SRL  = 'h10,
        SLL,
        SRA,
        ROR  = 'h14,
        ROL,
        SCMN = 'h20,
        UCMN,
        TST,
        SCMP = 'h24,
        UCMP,
        TSTN
    } alu_op_e;

endpackage
