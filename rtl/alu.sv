module alu (
    input [5:0] opc,
    input imm,
    input cond_true,
    input [31:0] op1,
    input [31:0] op2_i,
    output logic [31:0] res,
    output logic [1:0] cmp_res
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
        .sh(shamt),
        .maskbits(shmask),
        .left(opc[0]),
        .sx(opc[1]),
        .out(shift_res)
    );

    always_comb begin
        res = 0;
        cmp_res = 0;

        case (opc[5:4])
            0:
            case (opc[1:0])
                0: res = sum;
                1: res = and_res;
                2: res = op1 | op2;
                3: res = op1 ^ op2;
            endcase
            1: res = shift_res;
            3: begin
                if (cond_true) res = opc[3] ? op1 + 1 : op1;
                else res = op2_i;
            end
        endcase

        case (opc[1:0])
            0: begin
                cmp_res[EQ] = sum == 0;
                cmp_res[LT] = (op1[31] == op2[31]) ? op1[31] : ~cout;
            end
            1: begin
                cmp_res[EQ] = sum == 0;
                cmp_res[LT] = ~cout;
            end
            2: begin
                cmp_res[EQ] = and_res == 0;
                cmp_res[LT] = and_res[31];
            end
        endcase
    end

endmodule


