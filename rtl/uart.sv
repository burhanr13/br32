module uart #(
    int CLKSPEED = 27_000_000,
    int BAUDRATE = 115200
) (
    input clk,
    input rst,

    output tx_busy,
    output rx_ready,

    input tx_wr,
    input [7:0] tx_data,
    input rx_rd,
    output [7:0] rx_data,

    input  uart_rx,
    output uart_tx
);

    reg tx_sending;
    reg [3:0] tx_bit;
    reg [9:0] tx_bits;
    reg [15:0] tx_ctr;

    assign tx_busy = tx_sending;
    assign uart_tx = tx_sending ? tx_bits[0] : 1;

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_sending <= 0;
            tx_ctr <= 0;
        end else if (tx_sending) begin
            if (tx_ctr == 16'(CLKSPEED / BAUDRATE - 1)) begin
                tx_bits <= tx_bits >> 1;
                tx_ctr  <= 0;
                if (tx_bit == 9) begin
                    tx_sending <= 0;
                end else tx_bit <= tx_bit + 1;
            end else tx_ctr <= tx_ctr + 1;
        end else if (tx_wr) begin
            tx_sending <= 1;
            tx_bit <= 0;
            tx_bits <= {1'b1, tx_data, 1'b0};
            tx_ctr <= 0;
        end
    end

    assign rx_ready = 0;
    assign rx_data = 0;

endmodule
