
module stage_if #(
    logic [31:0] RESET_VEC = 0
) (
    input clk,
    input exn,

    input [5:0] exn_type,
    input eret,
    input [31:0] elr,

    if_out_if.master IF,
    id_out_if.other  ID,
    ex_out_if.other  EX,

    output reg [31:0] instr_addr,
    input [31:0] instr_data,
    input instr_busy
);

    reg [31:0] pc;

    always_comb begin
        IF.pc = pc;
        IF.instr = instr_data;

        if (exn) begin
            if (eret) IF.nextpc = elr;
            else IF.nextpc = {RESET_VEC[31:8], exn_type, 2'b0};
        end else if (ID.branch) IF.nextpc = ID.branch_dest;
        else if (!instr_busy) IF.nextpc = pc + 4;
        else IF.nextpc = pc;

        IF.stall   = ID.stall || instr_busy;
        IF.bubble  = ID.branch || IF.stall;

        instr_addr = IF.nextpc;
    end

    always_ff @(posedge clk) begin
        if (!IF.stall || exn) begin
            pc <= IF.nextpc;
        end
    end

endmodule
