module arbiter (
    input clk,

    input [31:0] instr_addr,
    output [31:0] instr_data,
    output instr_busy,

    input data_r,
    input data_w,
    input [1:0] data_sz,
    input [31:0] data_addr,
    output [31:0] data_rdata,
    input reg [31:0] data_wdata,
    output data_busy,

    output mem_r,
    output mem_w,
    output fetch,
    output [1:0] mem_sz,
    output [31:0] mem_addr,
    input [31:0] mem_rdata,
    output [31:0] mem_wdata,
    input mem_busy
);

    wire sel_data = data_r || data_w;
    reg sel_data_next;

    always_ff @(posedge clk) begin
        if (!mem_busy) sel_data_next <= sel_data;
    end

    assign instr_data = mem_rdata;
    assign instr_busy = sel_data_next || mem_busy;

    assign data_rdata = mem_rdata;
    assign data_busy = !sel_data_next || mem_busy;

    assign mem_r = sel_data ? data_r : 1;
    assign mem_w = sel_data ? data_w : 0;
    assign fetch = !sel_data;
    assign mem_sz = sel_data ? data_sz : 2;
    assign mem_addr = sel_data ? data_addr : instr_addr;
    assign mem_wdata = data_wdata;

endmodule
