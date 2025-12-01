interface ex_out_if;
    logic [31:0] pc  /*verilator public*/;
    logic [31:0] nextpc;

    logic [31:0] alu_res;
    logic [1:0] cmp_res;
    logic [31:0] op3;
    logic [4:0] rd;
    logic w_rd;
    logic w_cr;

    logic link;

    logic mem_r;
    logic mem_w;
    logic [1:0] mem_sz;
    logic mem_sx;

    logic io_r;
    logic io_w;

    logic mfsr, mtsr;
    logic mfcr;

    logic res_in_mem;

    logic scall, eret, udf;

    logic bubble, stall;

    modport master(
        output pc,nextpc,
        alu_res,cmp_res,op3,
        rd,w_rd,w_cr,link,mem_r,mem_w,mem_sz,
        mem_sx,io_r,io_w,mfsr,mtsr,mfcr,res_in_mem,scall,
        eret,udf,bubble,stall
    );
    modport other(
        input pc,nextpc, alu_res,cmp_res,op3,
        rd,w_rd,w_cr,link,mem_r,mem_w,mem_sz,mem_sx,io_r,io_w,
        mfsr,mtsr,mfcr,res_in_mem,scall,eret,udf,bubble,stall
    );
endinterface
