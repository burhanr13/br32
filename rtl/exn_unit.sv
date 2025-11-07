
typedef enum logic [5:0] {
    RST   = 0,
    IRQ   = 1,
    SCALL = 2,
    UDF   = 3
} exn_e;

typedef enum {
    SR_IE = 'h1000,
    SR_SIE,
    SR_SCR,
    SR_ELR,
    SR_EINFO
} sreg_e;

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
    output logic [31:0] sr_rdata,
    output [31:0] elr,
    output [1:0] scr
);

    reg ie  /*verilator public*/;
    reg saved_ie  /*verilator public*/;
    reg [1:0] saved_cr  /*verilator public*/;
    reg [31:0] saved_pc  /*verilator public*/;
    reg [31:0] exn_info  /*verilator public*/;

    logic save_exn_info;

    assign elr = saved_pc;
    assign scr = saved_cr;

    always_comb begin
        automatic logic true_ie = (MEM.mtsr && MEM.alu_res == SR_IE) ? MEM.op3[0] : ie;

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

        case (MEM.alu_res)
            SR_IE: sr_rdata = {31'b0, ie};
            SR_SIE: sr_rdata = {31'b0, saved_ie};
            SR_SCR: sr_rdata = {30'b0, saved_cr};
            SR_ELR: sr_rdata = saved_pc;
            SR_EINFO: sr_rdata = exn_info;
            default: sr_rdata = 0;
        endcase
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
            case (MEM.alu_res)
                SR_IE: ie <= MEM.op3[0];
                SR_SIE: saved_ie <= MEM.op3[0];
                SR_SCR: saved_cr <= MEM.op3[1:0];
                SR_ELR: saved_pc <= MEM.op3;
                SR_EINFO: exn_info <= MEM.op3;
                default: ;
            endcase
        end
    end

endmodule
