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

    output [9:0]hor_active_cnt,
    output [9:0]ver_active_cnt,

    output reg hs,
    output reg vs,
    output reg de
);
    `include "defines_vga.v"

    /* temp signal */
    reg [9:0]hor_cnt;
    reg [9:0]ver_cnt;

    /* output */
    assign hor_active_cnt = (hor_cnt >= `HOR_SYNC + `HOR_BACK) && (hor_cnt < `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE) ?
                                hor_cnt - `HOR_SYNC - `HOR_BACK : 'd0;
    assign ver_active_cnt = (ver_cnt >= `VER_SYNC + `VER_BACK) && (ver_cnt < `VER_SYNC + `VER_BACK + `VER_ACTIVE) ?
                                ver_cnt - `VER_SYNC - `VER_BACK : 'd0;

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
    always@(posedge pixel_clk or negedge rst_n) begin
        if(!rst_n)
            hs <= 1'b1;
        else if((hor_cnt >= 'd0) && (hor_cnt < `HOR_SYNC))
            hs <= 1'b0;
        else
            hs <= 1'b1;
    end

    //vs
    always@(posedge pixel_clk or negedge rst_n) begin
        if(!rst_n)
            vs <= 1'b1;
        else if((ver_cnt >= 'd0) && (ver_cnt < `VER_SYNC))
            vs <= 1'b0;
        else
            vs <= 1'b1;
    end

    //de
    always@(posedge pixel_clk or negedge rst_n) begin
        if(!rst_n)
            de <= 1'b0;
        else if((hor_cnt >= `HOR_SYNC + `HOR_BACK) && (hor_cnt < `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE) && (ver_cnt >= `VER_SYNC + `VER_BACK) && (ver_cnt <= `VER_SYNC + `VER_BACK + `VER_ACTIVE))
            de <= 1'b1;
        else
            de <= 1'b0;
    end

endmodule
