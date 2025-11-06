interface wb_out_if;
    logic [31:0] pc /*verilator public*/;

    logic [31:0] res;
    logic [4:0] rd;
    logic w_rd;

    logic bubble;

    modport master(output pc,res,rd,w_rd,bubble);
    modport other(input pc,res,rd,w_rd,bubble);
endinterface
