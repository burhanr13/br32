interface if_out_if;
    logic [31:0] pc  /*verilator public*/;
    logic [31:0] nextpc;

    logic [31:0] instr;

    logic bubble;

    modport master(output pc, nextpc, instr, bubble);
    modport other(input pc, nextpc, instr, bubble);
endinterface
