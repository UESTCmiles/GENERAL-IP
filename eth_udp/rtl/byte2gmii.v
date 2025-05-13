module byte2gmii (
    input rst_n,
    input eth_txc,
    input [7:0]tx_databyte,
    input tx_databyte_en,

    output eth_txen,
    output [7:0]eth_txd
);
    assign eth_txen = tx_databyte_en;
    assign eth_txd = tx_databyte;
    
endmodule