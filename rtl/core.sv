import pipeline_pkg::*;

module core (
    input clk,
    input rst,
    output [31:0] addr,
    inout [31:0] data
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
        .*
    );

    stage_mem MEM (
        .out(mem_out),
        .EX (ex_out),
        .*
    );

    stage_wb WB (
        .out(wb_out),
        .MEM(mem_out),
        .*
    );

endmodule
