import pipeline_pkg::*;

module stage_if (
    input clk,
    input rst,
    output if_out_t out,
    input id_out_t ID,
    input ex_out_t EX,
    output [31:0] iaddr,
    input [31:0] idata
);

    reg [31:0] pc;

    always_comb begin
        out.pc = EX.branch ? EX.branch_dest : pc;
        out.nextpc = out.pc + 4;
        iaddr = out.pc;
        out.instr = idata;
        out.bubble = 0;
    end

    always_ff @(posedge clk) begin
        if (rst) pc <= 0;
        else if (!ID.stall) pc <= out.nextpc;
    end

endmodule
