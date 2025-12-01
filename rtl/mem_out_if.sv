interface mem_out_if;
    logic [31:0] pc /*verilator public*/;
    logic [31:0] nextpc;

    logic [31:0] res;
    logic [4:0] rd;
    logic w_rd;
    logic [1:0] cmp_res;
    logic w_cr;

    logic [31:0] op3;
    logic [31:0] alu_res;

    logic mtsr;

    logic scall, eret, udf;

    logic bubble, stall;

    modport master(
        output pc,nextpc,res,rd,w_rd,cmp_res,
        w_cr,op3,alu_res,mtsr,scall,eret,udf,bubble,stall
    );
    modport other(
        input pc,nextpc,res,rd,w_rd,cmp_res,
        w_cr,op3,alu_res,mtsr,scall,eret,udf,bubble,stall
    );
endinterface
