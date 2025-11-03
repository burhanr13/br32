module decoder (
    input [31:0] instr,
    output decoded_t out
);
    import decoder_pkg::*;

    localparam logic [4:0] LR = 31;

    always_comb begin
        logic high_imm = 0;
        logic sx_imm = 0;

        out = '0;

        out.rd = instr[10:6];
        out.rs1 = instr[15:11];
        out.rs2 = instr[20:16];
        out.rs3 = out.rd;

        out.branch_off = {{4{instr[31]}}, instr[31:6], 2'b0};

        case (instr[5:4])
            0: begin
                if (instr[3]) begin
                    out.branch = 1;
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
                out.op2_imm = 1;
                out.r_rs1 = 1;
                out.w_rd = 1;
            end
            2: begin
                sx_imm = 1;
                out.op2_imm = 1;
                out.r_rs1 = 1;
                out.mem_sz = instr[3:2];
                out.mem_sx = instr[0];
                out.mem_r = !instr[1];
                out.mem_w = instr[1] && !instr[0];
                out.w_rd = !out.mem_w;
                out.r_rs3 = out.mem_w;
            end
            3: begin
                case (instr[3:0])
                    0, 1: begin
                        out.op2_imm = 1;
                        out.r_rs1 = 1;
                        out.io_r = !instr[0];
                        out.io_w = instr[0];
                        out.w_rd = out.io_r;
                        out.r_rs3 = out.io_w;
                    end
                    4: begin
                        out.op1_pc = 1;
                        out.op2_imm = 1;
                        sx_imm = 1;
                        out.w_rd = 1;
                    end
                    8: begin
                        logic [4:0] opc = instr[10:6];
                        if (opc[4]) begin
                            out.branch = 1;
                            out.branch_op1 = 1;
                            out.r_rs1 = 1;
                            out.link = opc[1];
                        end else begin
                            out.alu_opc = {3'b100, opc[2:0]};
                            high_imm = opc[3];
                            out.op2_imm = 1;
                            out.r_rs1 = 1;
                            out.w_flags = 1;
                        end
                    end
                    9: begin
                        logic [5:0] opc = instr[31:26];
                        out.alu_opc = {4'b0100, opc[3:2]};
                        out.op2_imm = 1;
                        out.r_rs1 = 1;
                        out.w_rd = 1;
                    end
                    'he: begin
                        logic [10:0] opc = instr[31:21];
                        if (opc[10:6] == 0) begin
                            logic is_cmp = opc[5:4] == 2;
                            logic is_cond = opc[5:4] == 3;
                            out.alu_opc = opc[5:0];
                            out.r_rs1 = 1;
                            out.r_rs2 = 1;
                            out.w_rd = !is_cmp;
                            out.w_flags = is_cmp;
                            out.cond_code = opc[2:0];
                            out.r_flags = is_cond;
                        end else if (opc[10:6] == 'h1f) begin
                            out.r_rs1 = 1;
                            out.r_rs2 = 1;
                            out.mem_sz = opc[3:2];
                            out.mem_sx = opc[0];
                            out.op2_shift = opc[4];
                            out.mem_r = !opc[1];
                            out.mem_w = opc[1] && !opc[0];
                            out.w_rd = !out.mem_w;
                            out.r_rs3 = out.mem_w;
                        end else out.undefined = 1;
                    end
                    default: out.undefined = 1;
                endcase
            end
            default: out.undefined = 1;
        endcase

        out.w_rd &= out.rd != 0;

        if (out.link) begin
            out.w_rd = 1;
            out.rd   = LR;
        end

        out.imm[31:16] = high_imm ? instr[31:16] : sx_imm ? {16{instr[31]}} : 0;
        out.imm[15:0]  = high_imm ? 0 : instr[31:16];
    end

endmodule
