module gmii2byte (
    input rst_n,
    input eth_rxc,
    input eth_rxdv,
    input [7:0]eth_rxd,

    output reg [7:0]rx_databyte,
    output reg rx_databyte_en
);
    always@(negedge eth_rxc or negedge rst_n) begin
        if(~rst_n) begin
            rx_databyte <= 8'd0;
            rx_databyte_en <= 1'b0; 
        end 
        else begin
            rx_databyte <= eth_rxd;
            rx_databyte_en <= eth_rxdv; 
        end
    end
    
endmodule