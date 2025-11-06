interface id_out_if;
    import decoder_pkg::*;

    logic [31:0] pc  /*verilator public*/;
    logic [31:0] nextpc;

    decoded_t dec;

    logic [31:0] op1, op2;

    logic cond_true;
    logic branch;
    logic [31:0] branch_dest;

    logic bubble, stall;

    modport master(output pc, nextpc, dec, op1, op2, cond_true, branch, branch_dest, bubble, stall);
    modport other(input pc, nextpc, dec, op1, op2, cond_true, branch, branch_dest, bubble, stall);
endinterface
