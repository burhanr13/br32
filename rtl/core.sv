import pipeline_pkg::*;

module core (
    input clk,
    input rst,

    output mem_r,
    output mem_w,
    output [1:0] mem_sz,
    output [31:0] mem_addr,
    inout [31:0] mem_data,

    output [31:0] iaddr,
    input  [31:0] idata,

    output io_r,
    output io_w,
    output [15:0] io_addr,
    inout [31:0] io_data
);

    logic [31:0] regs[32];
    assign regs[0] = 0;

    if_out_t  if_out;
    id_out_t  id_out;
    ex_out_t  ex_out;
    mem_out_t mem_out;
    wb_out_t  wb_out;

    stage_if IF (
        .out(if_out),
        .ID (id_out),
        .EX (ex_out),
        .*
    );

    stage_id ID (
        .out(id_out),
        .IF (if_out),
        .EX (ex_out),
        .MEM(mem_out),
        .WB (wb_out),
        .*
    );

    stage_ex EX (
        .out(ex_out),
        .ID (id_out),
        .MEM(mem_out),
        .WB (wb_out),
        .*
    );

    stage_mem MEM (
        .out(mem_out),
        .EX(ex_out),
        .mem_r_o(mem_r),
        .mem_w_o(mem_w),
        .mem_sz_o(mem_sz),
        .io_r_o(io_r),
        .io_w_o(io_w),
        .*
    );

    stage_wb WB (
        .out(wb_out),
        .MEM(mem_out),
        .*
    );

endmodule
