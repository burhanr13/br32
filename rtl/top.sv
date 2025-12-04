
typedef enum logic [15:0] {IO_LED = 'h1000} io_e;

module top (
    input clk,
    input rstn,

    output reg [5:0] led
);
    wire rst = !rstn;
    wire irq  /*verilator public */ = 0;

    wire mem_r  /* verilator public*/;
    wire mem_w  /* verilator public*/;
    wire fetch  /* verilator public*/;
    wire [1:0] mem_sz  /* verilator public*/;
    wire [31:0] mem_addr  /* verilator public*/;
    reg [31:0] mem_rdata  /* verilator public*/;
    wire [31:0] mem_wdata  /* verilator public*/;
    wire mem_busy  /* verilator public*/ = 0;

    wire [3:0] wstrb = (mem_sz == 0 ? 'b1 : mem_sz == 1 ? 'b11 : 'b1111) << mem_addr[1:0];

    reg [7:0] mem['h10000]  /* verilator public*/;
`ifndef VERILATOR
    initial begin
        $readmemh("init.mem", mem);
    end
`endif

    always_ff @(posedge clk) begin
        if (mem_w) begin
            if (wstrb[0]) mem[{mem_addr[15:2], 2'd0}] <= mem_wdata[7:0];
            if (wstrb[1]) mem[{mem_addr[15:2], 2'd1}] <= mem_wdata[15:8];
            if (wstrb[2]) mem[{mem_addr[15:2], 2'd2}] <= mem_wdata[23:16];
            if (wstrb[3]) mem[{mem_addr[15:2], 2'd3}] <= mem_wdata[31:24];
        end
        mem_rdata <= {
            mem[{mem_addr[15:2], 2'd3}],
            mem[{mem_addr[15:2], 2'd2}],
            mem[{mem_addr[15:2], 2'd1}],
            mem[{mem_addr[15:2], 2'd0}]
        };
    end

    wire io_r  /*verilator public*/;
    wire io_w  /*verilator public */;
    wire [15:0] io_addr  /*verilator public */;
    reg [31:0] io_rdata  /*verilator public */;
    wire [31:0] io_wdata  /*verilator public */;

    always_comb begin
        automatic logic io_ren = 1;
        automatic logic [31:0] io_val = 0;
        case (io_addr)
            IO_LED:  io_val = {26'b0, led};
            default: io_ren = 0;
        endcase
        io_rdata = io_ren ? io_val : 'z;
    end

    always_ff @(posedge clk) begin
        if (io_w) begin
            case (io_addr)
                IO_LED: led <= io_wdata[5:0];
            endcase
        end
    end

    core core0 (.*);

endmodule
