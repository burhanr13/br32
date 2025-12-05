interface regfile_if;
    logic [4:0] rs1;
    logic [31:0] rs1_val;
    logic [4:0] rs2;
    logic [31:0] rs2_val;
    logic [4:0] rs3;
    logic [31:0] rs3_val;
    logic w_rd;
    logic [4:0] rd;
    logic [31:0] rd_val;

    modport regfile(input rs1, rs2, rs3, w_rd, rd, rd_val, output rs1_val, rs2_val, rs3_val);
    modport id(output rs1, rs2, input rs1_val, rs2_val);
    modport ex(output rs3, input rs3_val);
    modport wb(output w_rd, rd, rd_val);

endinterface
