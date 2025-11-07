
module stage_wb (
    input clk,
    wb_out_if.master WB,
    mem_out_if.other MEM,
    output reg [31:0] regs[32],
    output reg [1:0] cmp_reg
);

    reg w_rd;

    reg bubble  /*verilator public*/;

    always_comb begin
        WB.w_rd   = w_rd && !bubble;
        WB.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        WB.pc  <= MEM.pc;
        WB.res <= MEM.res;
        WB.rd  <= MEM.rd;
        w_rd   <= MEM.w_rd;

        bubble <= MEM.bubble;

        if (!WB.bubble && w_rd) regs[WB.rd] <= WB.res;
        if (MEM.w_cr) cmp_reg <= MEM.cmp_res;
    end

endmodule
