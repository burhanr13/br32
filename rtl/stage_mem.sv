import pipeline_pkg::*;

module stage_mem (
    input clk,
    input rst,
    output mem_out_t out,
    input ex_out_t EX
);

    reg [31:0] pc, nextpc;

    reg [31:0] alu_res;
    reg [31:0] mem_data;

    reg [4:0] rd;
    reg w_rd;

    reg link;

    reg bubble;

    always_comb begin
        out.pc = pc;
        out.res = link ? nextpc : alu_res;
        out.rd = rd;
        out.w_rd = w_rd && !bubble;

        out.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        pc <= EX.pc;
        nextpc <= EX.nextpc;
        alu_res <= EX.alu_res;
        mem_data <= EX.mem_data;
        rd <= EX.rd;
        w_rd <= EX.w_rd;
        link <= EX.link;

        bubble <= EX.bubble || rst;
    end

endmodule
