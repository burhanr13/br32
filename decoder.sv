import decoder_pkg::*;

module decoder (
    input [31:0] instr,
    output decoded_t out
);

    always_comb begin
        logic high_imm = 0;
        logic sx_imm = 0;

        out = 0;

        out.rd = instr[10:6];
        out.rs1 = instr[15:11];
        out.rs2 = instr[20:16];
        out.rs3 = out.rd;

        out.imm26 = {{4{instr[31]}}, instr[31:6], 2'b0};

        case (instr[5:4])
            0: begin
                if (instr[3]) begin
                    out.branch   = 1;
                    out.op1_pc   = 1;
                    out.op2_type = OP2_IMM26;
                    if (instr[2:1] == 3) begin
                        out.link = instr[0];
                    end else begin
                        out.r_flags   = 1;
                        out.cond_code = instr[2:0];
                    end
                end else out.undefined = 1;
            end
            1: begin
                out.alu_opc = {3'b0, instr[2:0]};
                high_imm = instr[3];
                out.op2_type = OP2_IMM16;
                out.r_rs1 = 1;
                out.w_rd = 1;
            end
            3: begin
                case (instr[3:0])
                    8: begin
                        logic [4:0] opc = instr[10:6];
                        out.alu_opc = {3'b100, opc[2:0]};
                        high_imm = opc[3];
                        out.op2_type = OP2_IMM16;
                        out.r_rs1 = 1;
                        out.w_flags = 1;
                    end
                    9: begin
                        logic [5:0] opc = instr[31:26];
                        out.alu_opc = {4'b0100, opc[3:2]};
                        out.op2_type = OP2_IMM16;
                        out.r_rs1 = 1;
                        out.w_rd = 1;
                    end
                    'he: begin
                        logic [10:0] opc = instr[31:21];
                        if (opc[10:6] == 0) begin
                            out.alu_opc = opc[5:0];
                            out.r_rs1 = 1;
                            out.r_rs2 = 1;
                            out.w_rd = 1;
                        end
                    end
                    default: out.undefined = 1;
                endcase
            end
            default: out.undefined = 1;
        endcase

        out.w_rd &= out.rd != 0;

        if (out.link) begin
            out.w_rd = 1;
            out.rd = 31;
        end

        out.imm16[31:16] = high_imm ? instr[31:16] : sx_imm ? {16{instr[31]}} : 0;
        out.imm16[15:0]  = high_imm ? 0 : instr[31:16];
    end

endmodule
