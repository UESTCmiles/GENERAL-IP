`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/19 14:11:03
// Design Name: 
// Module Name: uart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_top #(
    parameter CLK_FREQ = 'd100_000_000,
    parameter BAUD_RATE = 'd1_000_000,
    parameter DATA_BIT = 'd8,
    parameter STOP_BIT = 'd1,
    parameter CHECK_BIT = 'd0,
    parameter CHECK_MODE = "EVEN"
)
(
    input clk,
    input rst,
    input rx,
    output tx,
    output reg [7:0]led
);
    /* temp signal */
    wire [7:0]rx_data;
    wire rx_valid;
    /* ภýปฏ */
    uart_tx#(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BIT(DATA_BIT),
        .STOP_BIT(STOP_BIT),
        .CHECK_BIT(CHECK_BIT),
        .CHECK_MODE(CHECK_MODE)
    )
    u_tx(
        .clk(clk),
        .rst(rst),
        .tx_data(rx_data),
        .tx_valid(rx_valid),
        .tx(tx)
    );
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BIT(DATA_BIT),
        .STOP_BIT(STOP_BIT),
        .CHECK_BIT(CHECK_BIT),
        .CHECK_MODE(CHECK_MODE)
    )
    u_rx(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    
    
    /* logic */
    always@(posedge clk or posedge rst) begin
        if(rst)
            led <= 'd0;
        else if(rx_valid)
            led <= rx_data;
        else
            led <= led;
    end
endmodule
