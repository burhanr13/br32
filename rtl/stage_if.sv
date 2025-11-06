
module stage_if #(
    logic [31:0] RESET_VEC = 0
) (
    input clk,
    input exn,
    input [5:0] exn_type,
    input eret,
    input [31:0] elr,
    if_out_if.master IF,
    id_out_if.other ID,
    ex_out_if.other EX,
    output [31:0] iaddr,
    input [31:0] idata
);

    reg [31:0] pc;

    always_comb begin
        IF.pc = pc;
        IF.instr = idata;
        if (exn) begin
            if (eret) IF.nextpc = elr;
            else IF.nextpc = {RESET_VEC[31:8], exn_type, 2'b0};
        end else IF.nextpc = ID.branch ? ID.branch_dest : pc + 4;

        IF.bubble = ID.branch;
    end

    always_ff @(posedge clk) begin
        if (!ID.stall || exn) begin
            pc <= IF.nextpc;
            iaddr <= IF.nextpc;
        end
    end

endmodule
