import pipeline_pkg::*;

module stage_wb (
    input clk,
    input rst,
    output wb_out_t out,
    input mem_out_t MEM,
    output [31:0] regs[32]
);

    reg [31:0] pc;
    reg [31:0] res;
    reg [4:0] rd;
    reg w_rd;
    reg mem_r;
    reg [1:0] mem_sz;
    reg mem_sx;

    reg bubble;

    always_comb begin
        out.pc = pc;

        if (mem_r) begin
            case (mem_sz)
                0: out.res = {{24{mem_sx && res[7]}}, res[7:0]};
                1: out.res = {{16{mem_sx && res[15]}}, res[15:0]};
                default: out.res = res;
            endcase
        end else out.res = res;

        out.rd = rd;
        out.w_rd = w_rd && !bubble;

        out.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        pc <= MEM.pc;
        res <= MEM.res;
        rd <= MEM.rd;
        w_rd <= MEM.w_rd;
        mem_r <= MEM.mem_r;
        mem_sz <= MEM.mem_sz;
        mem_sx <= MEM.mem_sx;

        bubble <= MEM.bubble || rst;

        if (!bubble && w_rd) regs[rd] <= out.res;
    end

endmodule
