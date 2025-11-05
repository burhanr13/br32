import pipeline_pkg::*;

module stage_if #(
    logic [31:0] RESET_VEC = 0
) (
    input clk,
    input exn,
    input [5:0] exn_type,
    input eret,
    input [31:0] elr,
    output if_out_t out,
    input id_out_t ID,
    input ex_out_t EX,
    output [31:0] iaddr,
    input [31:0] idata
);

    reg [31:0] pc;

    always_comb begin
        out.pc = pc;
        out.nextpc = pc + 4;
        out.instr = idata;
        if (exn) begin
            if (eret) out.nextpc = elr;
            else out.nextpc = {RESET_VEC[31:8], exn_type, 2'b0};
        end else out.nextpc = ID.branch ? ID.branch_dest : pc + 4;

        out.bubble = ID.branch;
    end

    always_ff @(posedge clk) begin
        if (!ID.stall) begin
            pc <= out.nextpc;
            iaddr <= out.nextpc;
        end
    end

endmodule
