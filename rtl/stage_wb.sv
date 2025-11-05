import pipeline_pkg::*;

module stage_wb (
    input clk,
    output wb_out_t out,
    input mem_out_t MEM,
    output [31:0] regs[32],
    output [1:0] cmp_reg
);

    reg [31:0] pc;
    reg [31:0] res;
    reg [4:0] rd;
    reg w_rd;

    reg bubble;

    always_comb begin
        out.pc = pc;

        out.res = res;

        out.rd = rd;
        out.w_rd = w_rd && !bubble;

        out.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        pc <= MEM.pc;
        res <= MEM.res;
        rd <= MEM.rd;
        w_rd <= MEM.w_rd;

        bubble <= MEM.bubble;

        if (!bubble && w_rd) regs[rd] <= out.res;
        if (MEM.w_cr) cmp_reg <= MEM.cmp_res;
    end

endmodule
