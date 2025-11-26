module shifter (
    input [31:0] op,
    input [4:0] sh,
    input [4:0] maskbits,
    input left,
    input sx,
    output logic [31:0] out
);

    wire [31:0] ones = '1;
    wire [31:0] mask = ones >> maskbits;
    wire [4:0] sh_n = -sh;
    logic [31:0] mask_r;

    always_comb begin
        for (int i = 0; i < 32; i++) mask_r[i] = mask[31-i];

        out = op >> (left ? sh_n : sh) | op << (left ? sh : sh_n);
        out &= left ? mask_r : mask;
        if (sx && out[~maskbits]) out |= ~mask;
    end
endmodule
