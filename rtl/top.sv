
typedef enum logic [15:0] {IO_LED = 'h1000} io_e;

module top (
    input clk,
    input rstn,

    output reg [5:0] led
);
    wire rst = !rstn;
    wire irq  /*verilator public */ = 0;

    wire mem_r;
    wire mem_w;
    wire fetch;
    wire [1:0] mem_sz;
    wire [31:0] mem_addr;
    reg [31:0] mem_rdata;
    wire [31:0] mem_wdata;
    wire mem_busy = 0;

    wire [3:0] wstrb = (mem_sz == 0 ? 'b1 : mem_sz == 1 ? 'b11 : 'b1111) << mem_addr[1:0];

    reg [31:0] mem['h10000/4]  /* verilator public*/;
    initial begin
        int fp = $fopen("../asm/blinky.bin");
        $fread(mem,fp);
        $fclose(fp);
    end

    always_ff @(posedge clk) begin
        if (mem_w) begin
            for (int i = 0; i < 4; i++) begin
                if (wstrb[i]) mem[mem_addr[15:2]][8*i+:8] <= mem_wdata[8*i+:8];
            end
        end
        if (mem_r) begin
            mem_rdata <= mem[mem_addr[15:2]];
        end
    end

    wire io_r  /*verilator public*/;
    wire io_w  /*verilator public */;
    wire [15:0] io_addr  /*verilator public */;
    reg [31:0] io_rdata  /*verilator public */;
    wire [31:0] io_wdata  /*verilator public */;

    always_comb begin
        logic io_ren = 1;
        logic [31:0] io_val = 0;
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

    initial begin
        $dumpfile("trace.vcd");
        $dumpvars();
    end

endmodule
