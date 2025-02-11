`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/01 13:45:38
// Design Name: 
// Module Name: vga_timing
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

module vga_timing(
    input pixel_clk,
    input rst_n,

    output wire[11:0]hor_active_cnt,
    output wire[11:0]ver_active_cnt,

    output hs,
    output vs,
    output de
);
    `include "defines_vga.v"

    /* temp signal */
    reg [11:0]hor_cnt;
    reg [11:0]ver_cnt;

    /* output */

    assign hor_active_cnt = de ? hor_cnt - `HOR_SYNC - `HOR_BACK : 12'd0;
    assign ver_active_cnt = de ? ver_cnt - `VER_SYNC - `VER_BACK : 12'd0;

    /* logic */
    //hor_cnt
    always@(posedge pixel_clk or negedge rst_n) begin
        if(!rst_n)
            hor_cnt <= 'd0;
        else if(hor_cnt == `HOR_TOTAL - 1)
            hor_cnt <= 'd0;
        else
            hor_cnt <= hor_cnt + 1'b1;
    end

    //ver_cnt
    always@(posedge pixel_clk or negedge rst_n) begin
        if(!rst_n)
            ver_cnt <= 'd0;
        else if(hor_cnt == `HOR_TOTAL - 1)
            if(ver_cnt == `VER_TOTAL - 1)
                ver_cnt <= 'd0;
            else
                ver_cnt <= ver_cnt + 1'b1;
        else
            ver_cnt <= ver_cnt;
    end 

     //hs
    assign hs = rst_n ? ((hor_cnt >= 'd0) && (hor_cnt < `HOR_SYNC) ? `POLARITY : ~`POLARITY) : ~`POLARITY;

    //vs
    assign vs = rst_n ? ((ver_cnt >= 'd0) && (ver_cnt < `VER_SYNC) ? `POLARITY : ~`POLARITY) : ~`POLARITY;

    //de
    assign de = rst_n ?
    ((hor_cnt >= `HOR_SYNC + `HOR_BACK) && (hor_cnt < `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE) && 
    (ver_cnt >= `VER_SYNC + `VER_BACK) && (ver_cnt <= `VER_SYNC + `VER_BACK + `VER_ACTIVE) ? 1'b1 : 1'b0) : 1'b0;

endmodule
