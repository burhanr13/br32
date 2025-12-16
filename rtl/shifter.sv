module shifter (
    input [31:0] op,
    input [4:0] sh,
    input [4:0] maskbits,
    input left,
    input sx,
    output [31:0] out
);

    wire  [31:0] ones = '1;
    wire  [31:0] mask = ones >> maskbits;
    wire  [ 4:0] sh_n = -sh;
    logic [31:0] mask_r;
    always_comb for (int i = 0; i < 32; i++) mask_r[i] = mask[31-i];
    wire [31:0] rot = 32'({op, op} >> (left ? sh_n : sh));
    wire [31:0] masked = left ? rot & mask_r : rot & mask;
    assign out = sx && masked[~maskbits] ? masked | ~mask : masked;
endmodule
