import decoder_pkg::*;

typedef struct {logic [31:0] pc;} stage_if_t;

typedef struct {
    logic [31:0] pc, nextpc;

    logic [31:0] instr;
    decoded_t dec;
} stage_id_t;

typedef struct {
    logic [31:0] nextpc;

    logic [5:0] alu_opc;
    logic [31:0] op1, op2;
    logic [4:0] rs2, rd;
    logic r_rs2, w_rd;
    logic r_flags, w_flags;
    logic op2_imm;

    logic [2:0] cond_code;

    logic branch, link;

    logic [31:0] alu_res;
    logic [1:0]  flags_res;
} stage_ex_t;

typedef struct {
    logic [31:0] nextpc;

    logic [31:0] alu_res;
    logic [31:0] mem_data;
    logic [4:0] rd;
    logic w_rd;

    logic branch, link;
} stage_mem_t;

typedef struct {
    logic [31:0] res;
    logic [4:0] rd;
    logic w_rd;
} stage_wb_t;

module core #(
    int IMEMSZ = 512
) (
    input clk,
    input reset
);
    localparam int IMEMBITS = $clog2(IMEMSZ);

    logic [31:0] regs[32];
    assign regs[0] = 0;
    logic [1:0] flags;

    stage_if_t IF;
    stage_id_t ID;
    stage_ex_t EX;
    stage_mem_t MEM;
    stage_wb_t WB;

    logic [31:0] imem[IMEMSZ];

    always_ff @(posedge clk) begin : IF_stage
        if (reset) begin
            IF.pc <= 0;
            ID.instr <= 'h0040003e;
        end else begin
            logic [31:0] pc = MEM.branch ? MEM.alu_res : IF.pc;
            logic [31:0] nextpc = pc + 4;
            IF.pc <= nextpc;
            ID.pc <= pc;
            ID.nextpc <= nextpc;
            ID.instr <= imem[pc[2+:IMEMBITS]];
        end
    end

    decoder DEC (
        .instr(ID.instr),
        .out  (ID.dec)
    );

    function automatic [31:0] calc_op2();
        case (ID.dec.op2_type)
            OP2_REG:   calc_op2 = regs[ID.dec.rs2];
            OP2_IMM16: calc_op2 = ID.dec.imm16;
            OP2_IMM26: calc_op2 = ID.dec.imm26;
            default:   calc_op2 = 0;
        endcase
    endfunction

    always_ff @(posedge clk) begin : ID_stage
        if (reset) begin
            EX.w_rd   <= 0;
            EX.branch <= 0;
        end else begin
            EX.nextpc  <= ID.nextpc;
            EX.alu_opc <= ID.dec.alu_opc;
            if (ID.dec.op1_pc) EX.op1 <= ID.pc;
            else EX.op1 <= regs[ID.dec.rs1];

            EX.op2 <= calc_op2();

            EX.rs2 <= ID.dec.rs2;
            EX.r_rs2 <= ID.dec.r_rs2;
            EX.rd <= ID.dec.rd;
            EX.w_rd <= ID.dec.w_rd;
            EX.r_flags <= ID.dec.r_flags;
            EX.w_flags <= ID.dec.w_flags;
            EX.op2_imm <= ID.dec.op2_type != OP2_REG;

            EX.cond_code <= ID.dec.cond_code;

            EX.branch <= ID.dec.branch;
            EX.link <= ID.dec.link;
        end
    end

    alu ALU (
        .opc(EX.alu_opc),
        .imm(EX.op2_imm),
        .op1(EX.op1),
        .op2_i(EX.op2),
        .res(EX.alu_res),
        .flags_res(EX.flags_res)
    );

    always_ff @(posedge clk) begin : EX_stage
        if (reset) begin
            MEM.w_rd   <= 0;
            MEM.branch <= 0;
        end else begin
            logic cond_true = ~EX.r_flags | ((EX.cond_code[1:0] == flags) ^ EX.cond_code[0]);
            if (EX.w_flags) flags <= EX.flags_res;

            MEM.nextpc <= EX.nextpc;
            MEM.alu_res <= EX.alu_res;
            MEM.rd <= EX.rd;
            MEM.w_rd <= EX.w_rd;
            MEM.branch <= EX.branch & cond_true;
            MEM.link <= EX.link;
        end
    end

    always_ff @(posedge clk) begin : MEM_stage
        if (reset) begin
            WB.w_rd <= 0;
        end else begin
            WB.res  <= MEM.link ? MEM.nextpc : MEM.alu_res;
            WB.rd   <= MEM.rd;
            WB.w_rd <= MEM.w_rd;
        end
    end

    always_ff @(posedge clk) begin : WB_stage
        if (!reset) begin
            if (WB.w_rd) regs[WB.rd] <= WB.res;
        end
    end

endmodule
