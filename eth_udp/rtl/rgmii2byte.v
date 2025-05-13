module rgmii2byte (
    input rst_n,
    input eth_rxc,
    input eth_rxdv,
    input [3:0]eth_rxd,

    output [7:0]rx_databyte,
    output rx_databyte_en
);
    wire [1:0]eth_rxdv_t;

    assign rx_databyte_en = &eth_rxdv_t;
    
    
    IDDR #(
        .DDR_CLK_EDGE           ("SAME_EDGE_PIPELINED"            ), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                                            //    or "SAME_EDGE_PIPELINED" 
        .INIT_Q1                (1'b0                       ), // Initial value of Q1: 1'b0 or 1'b1
        .INIT_Q2                (1'b0                       ), // Initial value of Q2: 1'b0 or 1'b1
        .SRTYPE                 ("SYNC"                     )  // Set/Reset type: "SYNC" or "ASYNC" 
    ) u_iddr (
        .Q1                     (eth_rxdv_t[0]                    ), // 1-bit output for positive edge of clock
        .Q2                     (eth_rxdv_t[1]                   ), // 1-bit output for negative edge of clock
        .C                      (eth_rxc                     ),   // 1-bit clock input
        .CE                     (1'b1                       ), // 1-bit clock enable input
        .D                      (eth_rxdv                    ),   // 1-bit DDR data input
        .R                      (~rst_n                     ),   // 1-bit reset
        .S                      (1'b0                       )    // 1-bit set
   );

   genvar i;
   generate
        for(i = 0; i < 4; i = i + 1) begin:rgmii_to_byte
            IDDR #(
                .DDR_CLK_EDGE           ("SAME_EDGE_PIPELINED"            ), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                                                    //    or "SAME_EDGE_PIPELINED" 
                .INIT_Q1                (1'b0                       ), // Initial value of Q1: 1'b0 or 1'b1
                .INIT_Q2                (1'b0                       ), // Initial value of Q2: 1'b0 or 1'b1
                .SRTYPE                 ("SYNC"                     )  // Set/Reset type: "SYNC" or "ASYNC" 
            ) u_iddr (
                .Q1                     (rx_databyte[i]                   ), // 1-bit output for positive edge of clock
                .Q2                     (rx_databyte[4+i]                   ), // 1-bit output for negative edge of clock
                .C                      (eth_rxc                     ),   // 1-bit clock input
                .CE                     (1'b1                       ), // 1-bit clock enable input
                .D                      (eth_rxd[i]                    ),   // 1-bit DDR data input
                .R                      (~rst_n                     ),   // 1-bit reset
                .S                      (1'b0                       )    // 1-bit set
            );
        end
   endgenerate
    
endmodule