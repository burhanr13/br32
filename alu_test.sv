import alu_pkg::*;

module alu_test;
    logic [5:0] opc;
    logic imm;
    logic [31:0] op1;
    logic [31:0] op2;
    logic [31:0] res;
    logic [1:0] flags_res;

    alu dut (
        .op2_i(op2),
        .*
    );

    task automatic test_op(input alu_op_e opc_i, input logic [31:0] op1_i, input logic [31:0] op2_i,
                           input logic [31:0] exp, input logic imm_i = 0);
        begin
            opc = opc_i[5:0];
            op1 = op1_i;
            op2 = op2_i;
            imm = imm_i;
            #10
            assert (dut.res == exp)
            else
                $error(
                    "%s%s %h %h -- got %h, expected %h",
                    opc_i.name(),
                    imm ? " (i)" : "",
                    op1,
                    op2,
                    res,
                    exp
                );
        end
    endtask

    `define TEST_OP(op, exp) \
    task automatic test_``op(input logic [31:0] a, input logic [31:0] b); \
        test_op(op, a, b, exp); \
    endtask

    `TEST_OP(ADD, a + b);
    `TEST_OP(SUB, a - b);
    `TEST_OP(AND, a & b);
    `TEST_OP(ANDN, a & ~b);
    `TEST_OP(OR, a | b);
    `TEST_OP(ORN, a | ~b);
    `TEST_OP(XOR, a ^ b);
    `TEST_OP(XORN, a ^~ b);

    `TEST_OP(SLL, a << b[4:0]);
    `TEST_OP(SRL, a >> b[4:0]);
    `TEST_OP(SRA, $signed(a) >>> b[4:0]);
    `TEST_OP(ROL, a << b[4:0] | a >> -b[4:0]);
    `TEST_OP(ROR, a >> b[4:0] | a << -b[4:0]);

    `undef TEST_OP

    task automatic test_RORMI(input logic [31:0] a, input logic [31:0] b);
        test_op(SRL, a, b, (a >> b[4:0] | a << -b[4:0]) << b[9:5] >> b[9:5], 1);
    endtask

    task automatic test_RORMSI(input logic [31:0] a, input logic [31:0] b);
        test_op(SRA, a, b, $signed((a >> b[4:0] | a << -b[4:0]) << b[9:5]) >>> b[9:5], 1);
    endtask

    task automatic test_ROLMI(input logic [31:0] a, input logic [31:0] b);
        test_op(SLL, a, b, a << b[9:5] >> b[9:5] << b[4:0] | a << b[9:5] >> b[9:5] >> -b[4:0], 1);
    endtask

    task automatic test_cmp_op(input alu_op_e opc_i, input logic [31:0] op1_i,
                               input logic [31:0] op2_i, input logic exp_eq, input logic exp_lt);
        begin
            opc = opc_i[5:0];
            op1 = op1_i;
            op2 = op2_i;
            #10
            assert (flags_res[EQ] == exp_eq && flags_res[LT] == exp_lt)
            else
                $error(
                    "%s %h %h -- got eq:%d lt:%d, expected eq:%d lt:%d",
                    opc_i.name(),
                    op1,
                    op2,
                    flags_res[EQ],
                    flags_res[LT],
                    exp_eq,
                    exp_lt
                );
        end
    endtask

    task automatic test_SCMP(input logic signed [31:0] op1_i, input logic signed [31:0] op2_i);
        test_cmp_op(SCMP, op1_i, op2_i, op1_i == op2_i, op1_i < op2_i);
    endtask

    task automatic test_SCMN(input logic signed [31:0] op1_i, input logic signed [31:0] op2_i);
        test_cmp_op(SCMN, op1_i, op2_i, op1_i == -op2_i, op1_i < -op2_i);
    endtask

    task automatic test_UCMP(input logic [31:0] op1_i, input logic [31:0] op2_i);
        test_cmp_op(UCMP, op1_i, op2_i, op1_i == op2_i, op1_i < op2_i);
    endtask

    task automatic test_UCMN(input logic [31:0] op1_i, input logic [31:0] op2_i);
        test_cmp_op(UCMN, op1_i, op2_i, op1_i == -op2_i, op1_i < -op2_i);
    endtask

    task automatic test_TST(input logic [31:0] op1_i, input logic [31:0] op2_i);
        test_cmp_op(TST, op1_i, op2_i, (op1_i & op2_i) == 0, op1_i[31] & op2_i[31]);
    endtask

    task automatic test_TSTN(input logic [31:0] op1_i, input logic [31:0] op2_i);
        test_cmp_op(TSTN, op1_i, op2_i, (op1_i & ~op2_i) == 0, op1_i[31] & ~op2_i[31]);
    endtask

    `define TEST1000(op) \
        for (int i=0;i<1000;i++) test_``op($urandom(),$urandom());

    initial begin
        test_ADD(0, 0);
        test_ADD(0, 1);
        test_ADD(1, 0);
        test_ADD(0, -1);
        test_ADD(-1, 0);
        test_SUB(0, 0);
        test_SUB(1, 0);
        test_SUB(0, 1);
        test_SUB(1, 1);
        test_AND('b0011, 'b1010);
        test_ANDN('b0011, 'b1010);
        test_OR('b0011, 'b1010);
        test_ORN('b0011, 'b1010);
        test_XOR('b0011, 'b1010);
        test_XORN('b0011, 'b1010);
        test_SCMP(0, 0);
        test_UCMP(0, 0);
        test_SCMP(0, 1);
        test_UCMP(0, 1);
        test_SCMP(1, 0);
        test_UCMP(0, 1);
        test_SCMP(-1, 0);
        test_SCMP(0, -1);
        test_UCMP(-1, 0);
        test_UCMP(0, -1);
        test_SCMP('h80000000, 'h7fffffff);
        test_SCMP('h7fffffff, 'h80000000);
        test_UCMP('h80000000, 'h7fffffff);
        test_UCMP('h7fffffff, 'h80000000);
        test_SCMN(1, -1);
        test_SCMN(1, 0);
        test_SCMN(-1, 0);
        test_SCMN(0, 0);
        test_TST(1, 0);
        test_TSTN(1, 0);
        test_TST(-1, 1 << 31);
        test_SLL('h1234, 8);
        test_SRL('h123400, 4);
        test_SRL('h80000000, 16);
        test_SRA('h80000000, 16);
        test_ROR('h12345678, 8);
        test_ROL('h12345678, 8);
        test_RORMI('h12345678, {22'b0, 5'd24, 5'd12});
        test_RORMSI('h12345678, {22'b0, 5'd29, 5'd12});
        test_ROLMI('haaaa, {22'b0, 5'd28, 5'd16});

        `TEST1000(ADD);
        `TEST1000(SUB);
        `TEST1000(AND);
        `TEST1000(ANDN);
        `TEST1000(OR);
        `TEST1000(ORN);
        `TEST1000(XOR);
        `TEST1000(XORN);
        `TEST1000(SLL);
        `TEST1000(SRL);
        `TEST1000(SRA);
        `TEST1000(ROL);
        `TEST1000(ROR);
        `TEST1000(RORMI);
        `TEST1000(ROLMI);
        `TEST1000(RORMSI);
        `TEST1000(SCMP);
        `TEST1000(UCMP);
        `TEST1000(SCMN);
        `TEST1000(UCMN);
        `TEST1000(TST);
        `TEST1000(TSTN);

        $display("all tests pass");
    end

endmodule
