module regfile (
    input clk,

    regfile_if.regfile rif
);
    reg [31:0] r1;
    reg [31:0] r2;
    reg [31:0] r3;
    reg [31:0] r4;
    reg [31:0] r5;
    reg [31:0] r6;
    reg [31:0] r7;
    reg [31:0] r8;
    reg [31:0] r9;
    reg [31:0] r10;
    reg [31:0] r11;
    reg [31:0] r12;
    reg [31:0] r13;
    reg [31:0] r14;
    reg [31:0] r15;
    reg [31:0] r16;
    reg [31:0] r17;
    reg [31:0] r18;
    reg [31:0] r19;
    reg [31:0] r20;
    reg [31:0] r21;
    reg [31:0] r22;
    reg [31:0] r23;
    reg [31:0] r24;
    reg [31:0] r25;
    reg [31:0] r26;
    reg [31:0] r27;
    reg [31:0] r28;
    reg [31:0] r29;
    reg [31:0] r30;
    reg [31:0] r31;

    function automatic [31:0] read(logic [4:0] rn);
        /* verilator public */
        case (rn)
            0: read = 0;
            1: read = r1;
            2: read = r2;
            3: read = r3;
            4: read = r4;
            5: read = r5;
            6: read = r6;
            7: read = r7;
            8: read = r8;
            9: read = r9;
            10: read = r10;
            11: read = r11;
            12: read = r12;
            13: read = r13;
            14: read = r14;
            15: read = r15;
            16: read = r16;
            17: read = r17;
            18: read = r18;
            19: read = r19;
            20: read = r20;
            21: read = r21;
            22: read = r22;
            23: read = r23;
            24: read = r24;
            25: read = r25;
            26: read = r26;
            27: read = r27;
            28: read = r28;
            29: read = r29;
            30: read = r30;
            31: read = r31;
            default: read = 0;
        endcase
    endfunction

    assign rif.rs1_val = read(rif.rs1);
    assign rif.rs2_val = read(rif.rs2);
    assign rif.rs3_val = read(rif.rs3);

    always_ff @(posedge clk) begin
        if (rif.w_rd)
            case (rif.rd)
                1:  r1 <= rif.rd_val;
                2:  r2 <= rif.rd_val;
                3:  r3 <= rif.rd_val;
                4:  r4 <= rif.rd_val;
                5:  r5 <= rif.rd_val;
                6:  r6 <= rif.rd_val;
                7:  r7 <= rif.rd_val;
                8:  r8 <= rif.rd_val;
                9:  r9 <= rif.rd_val;
                10: r10 <= rif.rd_val;
                11: r11 <= rif.rd_val;
                12: r12 <= rif.rd_val;
                13: r13 <= rif.rd_val;
                14: r14 <= rif.rd_val;
                15: r15 <= rif.rd_val;
                16: r16 <= rif.rd_val;
                17: r17 <= rif.rd_val;
                18: r18 <= rif.rd_val;
                19: r19 <= rif.rd_val;
                20: r20 <= rif.rd_val;
                21: r21 <= rif.rd_val;
                22: r22 <= rif.rd_val;
                23: r23 <= rif.rd_val;
                24: r24 <= rif.rd_val;
                25: r25 <= rif.rd_val;
                26: r26 <= rif.rd_val;
                27: r27 <= rif.rd_val;
                28: r28 <= rif.rd_val;
                29: r29 <= rif.rd_val;
                30: r30 <= rif.rd_val;
                31: r31 <= rif.rd_val;
            endcase
    end

endmodule
