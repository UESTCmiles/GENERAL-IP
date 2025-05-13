module byte2rgmii (
    input rst_n,
    input eth_txc,
    input [7:0]tx_databyte,
    input tx_databyte_en,

    output eth_txen,
    output [3:0]eth_txd
);
    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
        .INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
    ) ODDR_inst (
        .Q(eth_txen), // 1-bit DDR output
        .C(eth_txc), // 1-bit clock input
        .CE(1'b1), // 1-bit clock enable input
        .D1(tx_databyte_en), // 1-bit data input (positive edge)
        .D2(tx_databyte_en), // 1-bit data input (negative edge)
        .R(~rst_n), // 1-bit reset
        .S(1'b0) // 1-bit set
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin:s2d
            ODDR #(
                .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
                .INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
                .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
            ) ODDR_inst (
                .Q(eth_txd[i]), // 1-bit DDR output
                .C(eth_txc), // 1-bit clock input
                .CE(1'b1), // 1-bit clock enable input
                .D1(tx_databyte[i]), // 1-bit data input (positive edge)
                .D2(tx_databyte[i+4]), // 1-bit data input (negative edge)
                .R(~rst_n), // 1-bit reset
                .S(1'b0) // 1-bit set
            );   
        end
    endgenerate
    
endmodule