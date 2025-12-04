
typedef enum logic [5:0] {
    RST   = 0,
    IRQ   = 1,
    SCALL = 2,
    UDF   = 3
} exn_e;

module exn_unit (
    input clk,
    input rst,
    input irq,
    ex_out_if.other EX,
    mem_out_if.other MEM,
    input [1:0] cmp_reg,
    output logic exn,
    output logic [5:0] exn_type,
    output logic eret,
    input [15:0] sr_addr,
    output reg [31:0] sr_rdata,
    output [31:0] elr,
    output [1:0] scr
);
    import sr_pkg::*;

    reg ie  /*verilator public*/;
    reg saved_ie  /*verilator public*/;
    reg [1:0] saved_cr  /*verilator public*/;
    reg [31:0] saved_pc  /*verilator public*/;
    reg [31:0] exn_info  /*verilator public*/;

    logic save_exn_info;

    assign elr = saved_pc;
    assign scr = saved_cr;

    wire true_ie = (MEM.mtsr && sr_addr == SR_IE) ? MEM.op3[0] : ie;

    always_comb begin
        exn = 0;
        save_exn_info = 0;
        eret = 0;
        exn_type = 0;
        if (rst) begin
            exn = 1;
            exn_type = RST;
        end else if (MEM.scall) begin
            exn = 1;
            exn_type = SCALL;
            save_exn_info = 1;
        end else if (MEM.udf) begin
            exn = 1;
            exn_type = UDF;
            save_exn_info = 1;
        end else if (MEM.eret) begin
            exn  = 1;
            eret = 1;
        end else if (irq && true_ie && !EX.bubble) begin
            exn = 1;
            exn_type = IRQ;
        end
    end

    always_comb begin
        automatic logic sr_read = 1;
        automatic logic [31:0] sr_val = 0;
        case (sr_addr)
            SR_IE: sr_val = {31'b0, ie};
            SR_SIE: sr_val = {31'b0, saved_ie};
            SR_SCR: sr_val = {30'b0, saved_cr};
            SR_ELR: sr_val = saved_pc;
            SR_EINFO: sr_val = exn_info;
            default: sr_read = 0;
        endcase
        sr_rdata = sr_read ? sr_val : 'z;
    end

    always_ff @(posedge clk) begin
        if (eret) begin
            ie <= saved_ie;
        end else if (exn) begin
            saved_ie <= ie;
            ie <= 0;
            saved_cr <= MEM.w_cr ? MEM.cmp_res : cmp_reg;
            saved_pc <= MEM.nextpc;
            if (save_exn_info) exn_info <= MEM.alu_res;
            else exn_info <= 0;
        end else if (MEM.mtsr) begin
            case (sr_addr)
                SR_IE: ie <= MEM.op3[0];
                SR_SIE: saved_ie <= MEM.op3[0];
                SR_SCR: saved_cr <= MEM.op3[1:0];
                SR_ELR: saved_pc <= MEM.op3;
                SR_EINFO: exn_info <= MEM.op3;
            endcase
        end
    end

endmodule
