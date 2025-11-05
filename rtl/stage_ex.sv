import pipeline_pkg::*;

module stage_ex (
    input clk,
    input exn,
    output ex_out_t out,
    input id_out_t ID,
    input mem_out_t MEM,
    input wb_out_t WB,
    input [31:0] regs[32]
);

    reg [31:0] pc, nextpc;
    reg [31:0] op1, op2;

    reg [5:0] alu_opc;
    reg op2_imm;
    reg cond_true;

    reg [4:0] rs3, rd;
    reg r_rs3, w_rd;
    reg w_cr, r_cr;

    reg link;

    reg mem_r, mem_w;
    reg [1:0] mem_sz;
    reg op2_shift;
    reg mem_sx;

    reg io_r, io_w;

    logic mfsr, mtsr;
    logic mfcr, mtcr;

    logic scall, eret;
    logic udf;

    reg bubble;

    wire [31:0] alu_res;
    wire [1:0] cmp_res;

    alu ALU (
        .opc(alu_opc),
        .imm(op2_imm),
        .op1(op1),
        .op2_i(op2_shift ? op2 << mem_sz : op2),
        .cond_true(cond_true),
        .res(alu_res),
        .cmp_res(cmp_res)
    );

    always_comb begin
        out.pc = pc;
        out.nextpc = nextpc;

        out.alu_res = alu_res;
        out.cmp_res = cmp_res;

        if (MEM.w_rd && rs3 == MEM.rd) out.op3 = MEM.res;
        else if (WB.w_rd && rs3 == WB.rd) out.op3 = WB.res;
        else out.op3 = regs[rs3];

        if (mem_w) begin
            if (mem_sz == 0) out.op3 = {4{out.op3[7:0]}};
            else if (mem_sz == 1) out.op3 = {2{out.op3[15:0]}};
        end

        out.rd = rd;
        out.w_rd = w_rd && !bubble;
        out.cmp_res = mtcr ? out.op3[1:0] : cmp_res;
        out.w_cr = w_cr && !bubble;
        out.link = link;

        out.mem_r = mem_r;
        out.mem_w = mem_w;
        out.mem_sz = mem_sz;
        out.mem_sx = mem_sx;
        out.io_r = io_r;
        out.io_w = io_w;

        out.mfcr = mfcr;
        out.mfsr = mfsr;
        out.mtsr = mtsr;
        out.scall = scall;
        out.eret = eret;
        out.udf = udf;

        out.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        pc <= ID.pc;
        nextpc <= ID.nextpc;
        op1 <= ID.op1;
        op2 <= ID.op2;
        alu_opc <= ID.dec.alu_opc;
        op2_imm <= ID.dec.op2_imm;
        cond_true <= ID.cond_true;
        rs3 <= ID.dec.rs3;
        r_rs3 <= ID.dec.r_rs3;
        rd <= ID.dec.rd;
        w_rd <= ID.dec.w_rd;
        r_cr <= ID.dec.r_cr;
        w_cr <= ID.dec.w_cr;
        link <= ID.dec.link;
        mem_r <= ID.dec.mem_r;
        mem_w <= ID.dec.mem_w;
        mem_sz <= ID.dec.mem_sz;
        op2_shift <= ID.dec.op2_shift;
        mem_sx <= ID.dec.mem_sx;
        io_r <= ID.dec.io_r;
        io_w <= ID.dec.io_w;
        mfsr <= ID.dec.mfsr;
        mtsr <= ID.dec.mtsr;
        mfcr <= ID.dec.mfcr;
        mtcr <= ID.dec.mtcr;
        scall <= ID.dec.scall;
        eret <= ID.dec.eret;
        udf <= ID.dec.udf;

        bubble <= ID.bubble || exn;
    end

endmodule
