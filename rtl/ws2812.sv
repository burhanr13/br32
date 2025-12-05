module ws2812 #(
    int CLK_SPEED = 27_000_000
) (
    input clk,

    input ena,
    input [7:0] r,
    input [7:0] g,
    input [7:0] b,

    output ws2812_o
);

    localparam bit [15:0] DlyLong = 16'($rtoi(CLK_SPEED / 1000_000 * 0.8));
    localparam bit [15:0] DlyShort = 16'($rtoi(CLK_SPEED / 1000_000 * 0.4));
    localparam bit [15:0] DlyRes = 16'(CLK_SPEED / 1000_000 * 50);

    reg [15:0] counter;

    reg wait_res;
    reg [4:0] bitcnt;
    reg [23:0] curbits;
    reg outbit;
    assign ws2812_o = outbit;

    always_ff @(posedge clk) begin
        if (wait_res) begin
            if (counter == DlyRes) begin
                if (ena) begin
                    counter  <= 0;
                    wait_res <= 0;
                    bitcnt   <= 0;
                    curbits  <= {g, r, b};
                    outbit   <= 1;
                end
            end else counter <= counter + 1;
        end else begin
            if (!ena) begin
                counter  <= 0;
                wait_res <= 1;
                bitcnt   <= 0;
                curbits  <= 0;
                outbit   <= 0;
            end else begin
                if (outbit) begin
                    if (counter == (curbits[23] ? DlyLong - 1 : DlyShort - 1)) begin
                        counter <= 0;
                        outbit  <= 0;
                    end else counter <= counter + 1;
                end else begin
                    if (counter == (curbits[23] ? DlyShort - 1 : DlyLong - 1)) begin
                        counter <= 0;
                        outbit  <= 1;
                        if (bitcnt == 23) begin
                            wait_res <= 1;
                        end else begin
                            curbits <= curbits << 1;
                            bitcnt  <= bitcnt + 1;
                        end
                    end else counter <= counter + 1;
                end
            end
        end
    end

endmodule
