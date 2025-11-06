
module stage_mem (
    input clk,
    input exn,
    mem_out_if.master MEM,
    ex_out_if.other EX,
    output mem_r_o,
    output mem_w_o,
    output [1:0] mem_sz_o,
    output [31:0] mem_addr,
    input [31:0] mem_rdata,
    output [31:0] mem_wdata,
    output io_r_o,
    output io_w_o,
    output [15:0] io_addr,
    input [31:0] io_rdata,
    output [31:0] io_wdata,
    input [31:0] sr_rdata,
    input [1:0] cmp_reg,
    input [1:0] scr
);

    reg mem_r;
    reg [1:0] mem_sz;
    reg mem_sx;
    reg io_r;

    reg [4:0] rd;
    reg w_rd;
    reg [1:0] cmp_res;
    reg w_cr;

    reg mfsr, mtsr, mfcr;

    reg scall, eret, udf;

    reg link;

    reg bubble  /*verilator public*/;

    always_comb begin
        if (link) MEM.res = MEM.nextpc;
        else if (mfcr) MEM.res = {30'b0, cmp_reg};
        else if (mfsr) MEM.res = sr_rdata;
        else if (mem_r) begin
            case (mem_sz)
                0: MEM.res = {{24{mem_sx && mem_rdata[7]}}, mem_rdata[7:0]};
                1: MEM.res = {{16{mem_sx && mem_rdata[15]}}, mem_rdata[15:0]};
                default: MEM.res = mem_rdata;
            endcase
        end else if (io_r) MEM.res = io_rdata;
        else MEM.res = MEM.alu_res;

        MEM.rd = rd;
        MEM.w_rd = w_rd && !bubble;
        MEM.cmp_res = eret ? scr : cmp_res;
        MEM.w_cr = (w_cr || eret) && !bubble;

        MEM.mtsr = mtsr && !bubble;
        MEM.scall = scall && !bubble;
        MEM.eret = eret && !bubble;
        MEM.udf = udf && !bubble;

        MEM.bubble = bubble;
    end

    always_ff @(posedge clk) begin
        MEM.pc <= EX.pc;
        MEM.nextpc <= EX.nextpc;
        MEM.alu_res <= EX.alu_res;
        MEM.op3 <= EX.op3;
        rd <= EX.rd;
        w_rd <= EX.w_rd;
        cmp_res <= EX.cmp_res;
        w_cr <= EX.w_cr;
        link <= EX.link;
        mem_r <= EX.mem_r;
        mem_sz <= EX.mem_sz;
        mem_sx <= EX.mem_sx;
        io_r <= EX.io_r;
        mfsr <= EX.mfsr;
        mtsr <= EX.mtsr;
        mfcr <= EX.mfcr;
        scall <= EX.scall;
        eret <= EX.eret;
        udf <= EX.udf;

        bubble <= EX.bubble || exn;

        mem_r_o <= EX.mem_r && !EX.bubble && !exn;
        mem_w_o <= EX.mem_w && !EX.bubble && !exn;
        mem_sz_o <= EX.mem_sz;
        mem_addr <= EX.alu_res;
        mem_wdata <= EX.op3;

        io_r_o <= EX.io_r && !EX.bubble && !exn;
        io_w_o <= EX.io_w && !EX.bubble && !exn;
        io_addr <= EX.alu_res[15:0];
        io_wdata <= EX.op3;
    end

endmodule
