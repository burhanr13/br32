module sim;
    reg clk;
    reg rstn;

    reg [5:0] led;

    top dut(.*);

    initial begin
        $dumpfile("trace.vcd");
        $dumpvars();

        rstn = 0;
        clk = 0;
        #3 rstn = 1;
        #100_000_000 $finish;
    end

    always #1 clk = !clk;

endmodule
