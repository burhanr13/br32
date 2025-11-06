
module stage_id (
    input clk,
    input exn,
    id_out_if.master ID,
    if_out_if.other IF,
    ex_out_if.other EX,
    mem_out_if.other MEM,
    wb_out_if.other WB,
    input [31:0] regs[32],
    input [1:0] cmp_reg
);
    import decoder_pkg::*;

    reg [31:0] instr;
    reg bubble  /*verilator public*/;

    wire decoded_t dec;
    decoder d (
        .instr,
        .out(dec)
    );

    always_comb begin
        logic stall = 0;
        logic [1:0] cr_val;

        ID.dec = dec;

        if (dec.op1_0) ID.op1 = 0;
        else if (dec.op1_pc) ID.op1 = ID.pc;
        else if (EX.w_rd && dec.rs1 == EX.rd) begin
            if ((EX.mem_r || EX.io_r || EX.mfcr || EX.mfsr) && dec.r_rs1) begin
                stall  = 1;
                ID.op1 = 0;
            end else ID.op1 = EX.alu_res;
        end else if (MEM.w_rd && dec.rs1 == MEM.rd) ID.op1 = MEM.res;
        else if (WB.w_rd && dec.rs1 == WB.rd) ID.op1 = WB.res;
        else ID.op1 = regs[dec.rs1];

        if (dec.op2_imm) ID.op2 = dec.imm;
        else if (EX.w_rd && dec.rs2 == EX.rd) begin
            if ((EX.mem_r || EX.io_r) && dec.r_rs2) begin
                stall  = 1;
                ID.op2 = 0;
            end else ID.op2 = EX.alu_res;
        end else if (MEM.w_rd && dec.rs2 == MEM.rd) ID.op2 = MEM.res;
        else if (WB.w_rd && dec.rs2 == WB.rd) ID.op2 = WB.res;
        else ID.op2 = regs[dec.rs2];

        if (EX.w_cr) cr_val = EX.cmp_res;
        else if (MEM.w_cr) cr_val = MEM.cmp_res;
        else cr_val = cmp_reg;

        ID.cond_true = !dec.r_cr || ((dec.cond_code[2:1] == cr_val) ^ dec.cond_code[0]);

        ID.branch = dec.branch && ID.cond_true && !bubble;
        ID.branch_dest = dec.branch_op1 ? {ID.op1[31:2], 2'b0} : ID.pc + dec.branch_off;

        ID.stall = stall && !bubble;
        ID.bubble = bubble || ID.stall;
    end

    always_ff @(posedge clk) begin
        if (!ID.stall || exn) begin
            ID.pc <= IF.pc;
            ID.nextpc <= IF.nextpc;
            instr <= IF.instr;
            bubble <= IF.bubble || exn;
        end
    end

endmodule
