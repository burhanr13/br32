
typedef enum logic [15:0] {
    IO_LED = 'h1000,
    IO_RGB = 'h1001
} io_e;

module top #(
    int RAM_SIZE = 'h10000
) (
    input clk,
    input rstn,

    output [5:0] led_o,
    output ws2812_o
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

    reg [7:0] ram0[RAM_SIZE/4]  /* verilator public*/;
    reg [7:0] ram1[RAM_SIZE/4]  /* verilator public*/;
    reg [7:0] ram2[RAM_SIZE/4]  /* verilator public*/;
    reg [7:0] ram3[RAM_SIZE/4]  /* verilator public*/;
`ifndef VERILATOR
    initial begin
        logic [7:0] code[RAM_SIZE];
        $readmemh("init.mem", code);
        for (int i = 0; i < RAM_SIZE / 4; i++) begin
            ram0[i] = code[i*4+0];
            ram1[i] = code[i*4+1];
            ram2[i] = code[i*4+2];
            ram3[i] = code[i*4+3];
        end
    end
`endif

    wire [$clog2(RAM_SIZE)-3:0] ram_addr = mem_addr[$clog2(RAM_SIZE)-1:2];

    always_ff @(posedge clk) begin
        if (mem_w) begin
            if (wstrb[0]) ram0[ram_addr] <= mem_wdata[7:0];
            if (wstrb[1]) ram1[ram_addr] <= mem_wdata[15:8];
            if (wstrb[2]) ram2[ram_addr] <= mem_wdata[23:16];
            if (wstrb[3]) ram3[ram_addr] <= mem_wdata[31:24];
        end
        mem_rdata <= {ram3[ram_addr], ram2[ram_addr], ram1[ram_addr], ram0[ram_addr]};
    end

    wire io_r  /*verilator public*/;
    wire io_w  /*verilator public */;
    wire [15:0] io_addr  /*verilator public */;
    reg [31:0] io_rdata  /*verilator public */;
    wire [31:0] io_wdata  /*verilator public */;

    reg [5:0] reg_led;
    assign led_o = ~reg_led;
    reg [24:0] reg_rgb;
    ws2812 rgbcnt (
        .clk(clk),
        .ena(reg_rgb[24]),
        .r(reg_rgb[7:0]),
        .g(reg_rgb[15:8]),
        .b(reg_rgb[23:16]),
        .ws2812_o(ws2812_o)
    );

    always_comb begin
        automatic logic io_ren = 1;
        automatic logic [31:0] io_val = 0;
        case (io_addr)
            IO_LED:  io_val = {26'b0, reg_led};
            IO_RGB:  io_val = {7'b0, reg_rgb};
            default: io_ren = 0;
        endcase
        io_rdata = io_ren ? io_val : 'z;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_led <= 0;
            reg_rgb <= 0;
        end else if (io_w) begin
            case (io_addr)
                IO_LED: reg_led <= io_wdata[5:0];
                IO_RGB: reg_rgb <= io_wdata[24:0];
            endcase
        end
    end

    core core0 (.*);


    initial begin
        $dumpfile("trace.vcd");
        $dumpvars();
    end

endmodule
