import pipeline_pkg::*;

module stage_mem (
    input clk,
    input rst,
    output mem_out_t out,
    input ex_out_t EX,
    output mem_r_o,
    output mem_w_o,
    output [1:0] mem_sz_o,
    output [31:0] mem_addr,
    inout [31:0] mem_data,
    output io_r_o,
    output io_w_o,
    output [15:0] io_addr,
    inout [31:0] io_data
);

    reg [31:0] pc, nextpc;

    reg [31:0] alu_res;
    reg [31:0] op3;
    reg mem_r, mem_w;
    reg [1:0] mem_sz;
    reg mem_sx;
    reg io_r, io_w;

    reg [4:0] rd;
    reg w_rd;

    reg link;

    reg bubble;

    always_comb begin
        out.pc   = pc;

        mem_r_o  = mem_r && !bubble;
        mem_w_o  = mem_w && !bubble;
        mem_sz_o = mem_sz;
        mem_addr = alu_res;
        if (mem_w) mem_data = op3;

        io_r_o  = io_r && !bubble;
        io_w_o  = io_w && !bubble;
        io_addr = alu_res[15:0];
        if (io_w) io_data = op3;

        if (link) out.res = nextpc;
        else if (mem_r) begin
            case (mem_sz)
                0: out.res = {{24{mem_sx && mem_data[7]}}, mem_data[7:0]};
                1: out.res = {{16{mem_sx && mem_data[15]}}, mem_data[15:0]};
                default: out.res = mem_data;
            endcase
        end else if (io_r) out.res = io_data;
        else out.res = alu_res;

        out.rd = rd;
        out.w_rd = w_rd && !bubble;

        out.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        pc <= EX.pc;
        nextpc <= EX.nextpc;
        alu_res <= EX.alu_res;
        op3 <= EX.op3;
        rd <= EX.rd;
        w_rd <= EX.w_rd;
        link <= EX.link;
        mem_r <= EX.mem_r;
        mem_w <= EX.mem_w;
        mem_sz <= EX.mem_sz;
        mem_sx <= EX.mem_sx;
        io_r <= EX.io_r;
        io_w <= EX.io_w;

        bubble <= EX.bubble || rst;
    end

endmodule
