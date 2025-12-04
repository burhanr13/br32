
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

    decoded_t dec;
    decoder d (
        .instr,
        .out(dec)
    );

    function automatic [31:0] read_reg(logic [4:0] rn, logic r_rn, inout logic stall);
        if (rn == 0) read_reg = 0;
        else if (EX.w_rd && rn == EX.rd) begin
            if (r_rn && EX.res_in_mem) begin
                stall |= 1;
                read_reg = 0;
            end else read_reg = EX.alu_res;
        end else if (MEM.w_rd && rn == MEM.rd) read_reg = MEM.res;
        else if (WB.w_rd && rn == WB.rd) read_reg = WB.res;
        else read_reg = regs[rn];
    endfunction

    always_comb begin
        automatic logic stall;
        logic [1:0] cr_val;

        stall = EX.stall;

        ID.dec = dec;

        if (dec.op1_0) ID.op1 = 0;
        else if (dec.op1_pc) ID.op1 = ID.pc;
        else ID.op1 = read_reg(dec.rs1, dec.r_rs1, stall);

        if (dec.op2_imm) ID.op2 = dec.imm;
        else ID.op2 = read_reg(dec.rs2, dec.r_rs2, stall);

        if (EX.w_cr) cr_val = EX.cmp_res;
        else if (MEM.w_cr) cr_val = MEM.cmp_res;
        else cr_val = cmp_reg;

        ID.cond_true = !dec.r_cr || ((dec.cond_code[2:1] == cr_val) ^ dec.cond_code[0]);

        ID.branch = dec.branch && ID.cond_true && !bubble && !stall;
        ID.branch_dest = dec.branch_op1 ? {ID.op1[31:2], 2'b0} : ID.pc + dec.branch_off;

        ID.stall = stall && !bubble;
        ID.bubble = bubble || ID.stall;
    end

    always_ff @(posedge clk) begin
        if (!ID.stall || exn) begin
            ID.pc <= IF.pc;
            ID.nextpc <= IF.stall ? IF.pc : IF.nextpc;
            instr <= IF.instr;

            bubble <= IF.bubble || exn;
        end
    end

endmodule
