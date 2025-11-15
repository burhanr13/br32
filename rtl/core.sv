
module core (
    input clk,
    input rst,
    input irq,

    output mem_r,
    output mem_w,
    output [1:0] mem_sz,
    output [31:0] mem_addr,
    input [31:0] mem_rdata,
    output [31:0] mem_wdata,

    output [31:0] iaddr,
    input  [31:0] idata,

    output io_r,
    output io_w,
    output [15:0] io_addr,
    input [31:0] io_rdata,
    output [31:0] io_wdata
);

    reg [31:0] regs[32]  /*verilator public*/;
    assign regs[0] = 0;
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

    wire [31:0] sr_rdata;

    exn_unit e (.*);

    stage_if s_if (.*);

    stage_id s_id (.*);

    stage_ex s_ex (.*);

    stage_mem s_mem (
        .mem_r_o (mem_r),
        .mem_w_o (mem_w),
        .mem_sz_o(mem_sz),
        .io_r_o  (io_r),
        .io_w_o  (io_w),
        .*
    );

    stage_wb s_wb (.*);

endmodule
