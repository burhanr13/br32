
module core (
    input clk,
    input rst,
    input irq,

    output mem_r,
    output mem_w,
    output fetch,
    output [1:0] mem_sz,
    output [31:0] mem_addr,
    input [31:0] mem_rdata,
    output [31:0] mem_wdata,
    input mem_busy,

    output io_r,
    output io_w,
    output [15:0] io_addr,
    input [31:0] io_rdata,
    output [31:0] io_wdata
);
    import sr_pkg::*;

    reg [31:0] regs[32]  /*verilator public*/;
    reg [1:0] cmp_reg  /*verilator public*/;

    wire exn;
    wire eret;
    wire [5:0] exn_type;

    wire [31:0] elr;
    wire [1:0] scr;

    if_out_if IF ();
    id_out_if ID ();
    ex_out_if EX ();
    mem_out_if MEM ();
    wb_out_if WB ();

    wire [15:0] sr_addr;
    wire [31:0] sr_rdata;

    wire [31:0] instr_addr;
    wire [31:0] instr_data;
    wire instr_busy;

    wire data_r;
    wire data_w;
    wire [1:0] data_sz;
    wire [31:0] data_addr;
    wire [31:0] data_rdata;
    wire [31:0] data_wdata;
    wire data_busy;

    reg [31:0] sysclk;
    always_ff @(posedge clk) begin
        if (rst) sysclk <= 0;
        else sysclk <= sysclk + 1;
    end
    assign sr_rdata = sr_addr == SR_SYSCLK ? sysclk : 'z;

    arbiter a (.*);

    exn_unit e (.*);

    stage_if s_if (.*);

    stage_id s_id (.*);

    stage_ex s_ex (.*);

    stage_mem s_mem (
        .io_r_o(io_r),
        .io_w_o(io_w),
        .*
    );

    stage_wb s_wb (.*);

endmodule
