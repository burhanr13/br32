
module stage_mem (
    input clk,
    input exn,
    mem_out_if.master MEM,
    ex_out_if.other EX,

    output data_r,
    output data_w,
    output [1:0] data_sz,
    output [31:0] data_addr,
    input [31:0] data_rdata,
    output [31:0] data_wdata,
    input data_busy,

    output reg io_r_o,
    output reg io_w_o,
    output reg [15:0] io_addr,
    input [31:0] io_rdata,
    output reg [31:0] io_wdata,

    output reg [15:0] sr_addr,
    input [31:0] sr_rdata,
    input [1:0] cmp_reg,
    input [1:0] scr
);

    reg mem_r, mem_w;
    reg [1:0] mem_sz;
    reg mem_sx;
    reg io_r;

    reg [4:0] rd;
    reg w_rd;
    reg [1:0] cmp_res;
    reg w_cr;

    reg mfsr, mtsr, mfcr;

    reg scall, eret, udf;

    reg  link;

    reg  bubble  /*verilator public*/;

    wire [31:0] data_rdata_sh = data_rdata >> {MEM.alu_res[1:0], 3'b0};

    always_comb begin
        automatic logic stall = 0;

        if (link) MEM.res = MEM.nextpc;
        else if (mfcr) MEM.res = {30'b0, cmp_reg};
        else if (mfsr) MEM.res = sr_rdata;
        else if (mem_r) begin
            case (mem_sz)
                0: MEM.res = {{24{mem_sx && data_rdata[7]}}, data_rdata_sh[7:0]};
                1: MEM.res = {{16{mem_sx && data_rdata[15]}}, data_rdata_sh[15:0]};
                default: MEM.res = data_rdata;
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

        stall |= (mem_r || mem_w) && data_busy;

        MEM.stall  = stall && !bubble;
        MEM.bubble = bubble || MEM.stall;
    end

    assign data_r = EX.mem_r && !EX.bubble && !exn;
    assign data_w = EX.mem_w && !EX.bubble && !exn;
    assign data_sz = EX.mem_sz;
    assign data_addr = EX.alu_res;
    assign data_wdata = EX.op3;

    always_ff @(posedge clk) begin
        if (!MEM.stall || exn) begin
            MEM.pc <= EX.pc;
            MEM.nextpc <= EX.stall ? EX.pc : EX.nextpc;
            MEM.alu_res <= EX.alu_res;
            MEM.op3 <= EX.op3;
            rd <= EX.rd;
            w_rd <= EX.w_rd;
            cmp_res <= EX.cmp_res;
            w_cr <= EX.w_cr;
            link <= EX.link;
            mem_r <= EX.mem_r;
            mem_w <= EX.mem_w;
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
        end

        io_r_o   <= EX.io_r && !EX.bubble && !exn;
        io_w_o   <= EX.io_w && !EX.bubble && !exn;
        io_addr  <= EX.alu_res[15:0];
        io_wdata <= EX.op3;

        sr_addr  <= EX.alu_res[15:0];
    end

endmodule
