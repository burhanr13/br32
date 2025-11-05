import pipeline_pkg::*;

module stage_id (
    input clk,
    input exn,
    output id_out_t out,
    input if_out_t IF,
    input ex_out_t EX,
    input mem_out_t MEM,
    input wb_out_t WB,
    input [31:0] regs[32],
    input [1:0] cmp_reg
);
    import decoder_pkg::*;

    reg [31:0] pc, nextpc, instr;
    reg bubble, stall;

    logic [1:0] cr_val;

    wire decoded_t dec;
    decoder d (
        .instr,
        .out(dec)
    );

    always_comb begin
        out.pc = pc;
        out.nextpc = nextpc;

        stall = 0;

        out.dec = dec;

        if (dec.op1_0) out.op1 = 0;
        else if (dec.op1_pc) out.op1 = pc;
        else if (EX.w_rd && dec.rs1 == EX.rd) begin
            if ((EX.mem_r || EX.io_r) && dec.r_rs1) begin
                stall   = 1;
                out.op1 = 0;
            end else out.op1 = EX.alu_res;
        end else if (MEM.w_rd && dec.rs1 == MEM.rd) out.op1 = MEM.res;
        else if (WB.w_rd && dec.rs1 == WB.rd) out.op1 = WB.res;
        else out.op1 = regs[dec.rs1];

        if (dec.op2_imm) out.op2 = dec.imm;
        else if (EX.w_rd && dec.rs2 == EX.rd) begin
            if ((EX.mem_r || EX.io_r) && dec.r_rs2) begin
                stall   = 1;
                out.op2 = 0;
            end else out.op2 = EX.alu_res;
        end else if (MEM.w_rd && dec.rs2 == MEM.rd) out.op2 = MEM.res;
        else if (WB.w_rd && dec.rs2 == WB.rd) out.op2 = WB.res;
        else out.op2 = regs[dec.rs2];

        if (EX.w_cr) cr_val = EX.cmp_res;
        else if (MEM.w_cr) cr_val = MEM.cmp_res;
        else cr_val = cmp_reg;

        out.cond_true = !dec.r_cr || ((dec.cond_code[2:1] == cr_val) ^ dec.cond_code[0]);

        out.branch = dec.branch && out.cond_true && !out.bubble;
        out.branch_dest = dec.branch_op1 ? {out.op1[31:2], 2'b0} : pc + dec.branch_off;

        out.stall = stall && !bubble;
        out.bubble = bubble || out.stall;
    end

    always_ff @(posedge clk) begin
        if (!out.stall) begin
            pc <= IF.pc;
            nextpc <= IF.nextpc;
            instr <= IF.instr;
            bubble <= IF.bubble || exn;
        end
    end

endmodule
