package sr_pkg;
    typedef enum logic [15:0] {
        SR_SYSCLK = 'h0000,

        SR_IE = 'h1000,
        SR_SIE,
        SR_SCR,
        SR_ELR,
        SR_EINFO
    } sreg_e;
endpackage
