import pipeline_pkg::*;

module stage_if (
    input clk,
    input rst,
    output if_out_t out,
    input ex_out_t EX,
    output [31:0] addr,
    inout [31:0] data
);

    reg [31:0] pc;

    always_comb begin
        out.pc = EX.branch ? EX.branch_dest : pc;
        out.nextpc = out.pc + 4;
        addr = out.pc;
        out.instr = data;
        out.bubble = 0;
    end

    always_ff @(posedge clk) begin
        if (rst) pc <= 0;
        else pc <= out.nextpc;
    end

endmodule
