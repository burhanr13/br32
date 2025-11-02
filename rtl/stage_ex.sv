import pipeline_pkg::*;

module stage_ex (
    input clk,
    input rst,
    output ex_out_t out,
    input id_out_t ID,
    input [31:0] regs[32]
);

    reg [1:0] flags;

    reg [31:0] pc, nextpc;
    reg [31:0] op1, op2;

    reg [5:0] alu_opc;
    reg op2_imm;
    reg [2:0] cond_code;

    reg [4:0] rs3, rd;
    reg r_rs3, w_rd;
    reg w_flags, r_flags;

    reg branch, link;
    reg [31:0] branch_dest;

    reg bubble;

    wire [31:0] alu_res;
    wire [1:0] flags_res;

    alu ALU (
        .opc(alu_opc),
        .imm(op2_imm),
        .op1(op1),
        .op2_i(op2),
        .res(alu_res),
        .flags_res(flags_res)
    );

    wire cond_true = !r_flags || ((cond_code[2:1] == flags) ^ cond_code[0]);

    always_comb begin
        out.pc = pc;
        out.nextpc = nextpc;

        out.alu_res = alu_res;
        out.mem_data = regs[rs3];

        out.rd = rd;
        out.w_rd = w_rd && !bubble;
        out.branch = branch && cond_true && !bubble;
        out.link = link;

        out.branch_dest = branch_dest;

        out.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        pc <= ID.pc;
        nextpc <= ID.nextpc;
        op1 <= ID.op1;
        op2 <= ID.op2;
        alu_opc <= ID.dec.alu_opc;
        op2_imm <= ID.dec.op2_imm;
        cond_code <= ID.dec.cond_code;
        rs3 <= ID.dec.rs3;
        r_rs3 <= ID.dec.r_rs3;
        rd <= ID.dec.rd;
        w_rd <= ID.dec.w_rd;
        r_flags <= ID.dec.r_flags;
        w_flags <= ID.dec.w_flags;
        branch <= ID.dec.branch;
        link <= ID.dec.link;
        branch_dest <= ID.branch_dest;

        bubble <= ID.bubble || rst;

        if (!out.bubble && w_flags) flags <= flags_res;
    end

endmodule
