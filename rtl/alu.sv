module alu (
    input [5:0] opc,
    input imm,
    input [31:0] op1,
    input [31:0] op2_i,
    output logic [31:0] res,
    output logic [1:0] flags_res
);
    import alu_pkg::*;

    wire [31:0] op2 = op2_i ^ {32{opc[2]}};
    wire [4:0] shamt = op2_i[4:0];
    wire [4:0] shmask = imm ? op2_i[9:5] : shamt & ~{5{opc[2]}};

    wire cin = opc[2];
    wire [31:0] sum;
    wire cout;
    assign {cout, sum} = op1 + op2 + {31'b0, cin};

    wire [31:0] and_res = op1 & op2;

    wire [31:0] shift_res;
    shifter shifter (
        .op(op1),
        .sh_i(shamt),
        .maskbits(shmask),
        .left(opc[0]),
        .sx(opc[1]),
        .out(shift_res)
    );

    always_comb begin
        case (opc[5:4])
            0:
            case (opc[1:0])
                0: res = sum;
                1: res = and_res;
                2: res = op1 | op2;
                3: res = op1 ^ op2;
                default: res = 0;
            endcase
            1: res = shift_res;
            2: res = 0;
            3: res = 0;  // cond instrs
            default: res = 0;
        endcase

        case (opc[1:0])
            0: begin
                flags_res[EQ] = sum == 0;
                flags_res[LT] = (op1[31] == op2[31]) ? op1[31] : ~cout;
            end
            1: begin
                flags_res[EQ] = sum == 0;
                flags_res[LT] = ~cout;
            end
            2: begin
                flags_res[EQ] = and_res == 0;
                flags_res[LT] = and_res[31];
            end
            default: flags_res = 0;
        endcase
    end

endmodule


