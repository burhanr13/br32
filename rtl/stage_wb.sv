
module stage_wb (
    input clk,
    input rst,
    wb_out_if.master WB,
    mem_out_if.other MEM,
    regfile_if.wb rif,
    output reg [1:0] cmp_reg
);

    reg w_rd;

    reg bubble  /*verilator public*/;

    always_comb begin
        WB.w_rd = w_rd && !bubble;
        rif.w_rd = WB.w_rd;
        rif.rd = WB.rd;
        rif.rd_val = WB.res;

        WB.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        WB.pc  <= MEM.pc;
        WB.res <= MEM.res;
        WB.rd  <= MEM.rd;
        w_rd   <= MEM.w_rd;

        bubble <= MEM.bubble;

        if (MEM.w_cr) cmp_reg <= MEM.cmp_res;
    end

endmodule
