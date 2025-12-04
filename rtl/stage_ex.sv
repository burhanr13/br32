
module stage_ex (
    input clk,
    input exn,
    ex_out_if.master EX,
    id_out_if.other ID,
    mem_out_if.other MEM,
    wb_out_if.other WB,
    input [31:0] regs[32]
);

    reg [31:0] op1, op2;

    reg [5:0] alu_opc;
    reg op2_imm;
    reg cond_true;

    reg [4:0] rs3;
    reg r_rs3, w_rd;
    reg w_cr, r_cr;

    reg op2_shift;

    reg mtcr;

    reg bubble  /*verilator public*/;

    wire [1:0] cmp_res;

    alu ALU (
        .opc(alu_opc),
        .imm(op2_imm),
        .op1(op1),
        .op2_i(op2_shift ? op2 << EX.mem_sz : op2),
        .cond_true(cond_true),
        .res(EX.alu_res),
        .cmp_res(cmp_res)
    );

    always_comb begin
        automatic logic stall;

        stall = MEM.stall;

        if (MEM.w_rd && rs3 == MEM.rd) EX.op3 = MEM.res;
        else if (WB.w_rd && rs3 == WB.rd) EX.op3 = WB.res;
        else EX.op3 = regs[rs3];

        if (EX.mem_w) begin
            if (EX.mem_sz == 0) EX.op3 = {4{EX.op3[7:0]}};
            else if (EX.mem_sz == 1) EX.op3 = {2{EX.op3[15:0]}};
        end

        EX.w_rd = w_rd && !bubble;
        EX.cmp_res = mtcr ? EX.op3[1:0] : cmp_res;
        EX.w_cr = w_cr && !bubble;

        EX.res_in_mem = EX.mem_r || EX.io_r || EX.mfcr || EX.mfsr;

        EX.stall = stall && !bubble;
        EX.bubble = bubble || EX.stall;
    end

    always_ff @(posedge clk) begin
        if (!EX.stall || exn) begin
            EX.pc <= ID.pc;
            EX.nextpc <= ID.stall ? ID.pc : ID.nextpc;
            op1 <= ID.op1;
            op2 <= ID.op2;
            alu_opc <= ID.dec.alu_opc;
            op2_imm <= ID.dec.op2_imm;
            cond_true <= ID.cond_true;
            rs3 <= ID.dec.rs3;
            r_rs3 <= ID.dec.r_rs3;
            w_rd <= ID.dec.w_rd;
            EX.rd <= ID.dec.rd;
            r_cr <= ID.dec.r_cr;
            w_cr <= ID.dec.w_cr;
            EX.link <= ID.dec.link;
            EX.mem_r <= ID.dec.mem_r;
            EX.mem_w <= ID.dec.mem_w;
            EX.mem_sz <= ID.dec.mem_sz;
            op2_shift <= ID.dec.op2_shift;
            EX.mem_sx <= ID.dec.mem_sx;
            EX.io_r <= ID.dec.io_r;
            EX.io_w <= ID.dec.io_w;
            EX.mfsr <= ID.dec.mfsr;
            EX.mtsr <= ID.dec.mtsr;
            EX.mfcr <= ID.dec.mfcr;
            mtcr <= ID.dec.mtcr;
            EX.scall <= ID.dec.scall;
            EX.eret <= ID.dec.eret;
            EX.udf <= ID.dec.udf;

            bubble <= ID.bubble || exn;
        end
    end

endmodule
