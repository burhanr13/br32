module shifter (
    input [31:0] op,
    input [4:0] sh_i,
    input [4:0] maskbits,
    input left,
    input sx,
    output logic [31:0] out
);

    wire [31:0] ones = '1;
    wire [31:0] mask = ones >> maskbits;
    wire [ 4:0] sh = left ? -sh_i : sh_i;

    always_comb begin
        logic [63:0] rot;
        out = op;
        if (left) out &= mask;
        rot = {out, out} >> sh;
        out = rot[31:0];
        if (!left) begin
            out &= mask;
            if (sx && out[~maskbits]) out |= ~mask;
        end
    end
endmodule
