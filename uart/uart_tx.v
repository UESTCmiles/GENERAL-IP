`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/19 14:11:03
// Design Name: 
// Module Name: uart_tx
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


module uart_tx#(
    parameter CLK_FREQ = 'd100_000_000,
    parameter BAUD_RATE = 'd9600,
    parameter DATA_BIT = 'd8,
    parameter STOP_BIT = 'd1,
    parameter CHECK_BIT = 'd0,
    parameter CHECK_MODE = "EVEN"
)
(
    input clk,
    input rst,
    input [7:0]tx_data,
    input tx_valid,
    output reg tx
);

    /* temp signal */
    localparam BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE;
    reg [15:0]baud_cnt;
    reg [2:0]bit_cnt;

    /* ×´Ì¬»ú */
    reg [2:0]current_state;
    reg [2:0]next_state;
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam DATA = 3'd2;
    localparam CHECK = 3'd3;
    localparam STOP = 3'd4;

    /* logic */
    // ×´Ì¬»ú
    // 1
    always@(posedge clk or posedge rst) begin
        if(rst)
            current_state <= IDLE;
        else
            current_state <= next_state;      
    end

    // 2
    always@(*) begin
        if(rst)
            next_state = IDLE;
        else begin
            case (current_state)
                IDLE: begin
                    if(tx_valid)
                        next_state = START;
                    else
                        next_state = IDLE;
                end
                START: begin
                    if(baud_cnt == BAUD_CNT_MAX - 1)
                        next_state = DATA;
                    else
                        next_state = START;
                end
                DATA: begin
                    if(baud_cnt == BAUD_CNT_MAX - 1)
                        if(bit_cnt == DATA_BIT - 1)
                            if(CHECK_BIT == 'd0)
                                next_state = STOP;
                            else
                                next_state = CHECK;
                        else
                            next_state = DATA;
                    else
                        next_state = DATA;
                end
                CHECK: begin
                    if(baud_cnt == BAUD_CNT_MAX - 1)
                        next_state = STOP;
                    else
                        next_state = CHECK;
                end
                STOP: begin
                    if(baud_cnt == BAUD_CNT_MAX - 1)
                        if(bit_cnt == STOP_BIT - 1)
                            next_state = IDLE;
                        else
                            next_state = STOP;
                    else
                        next_state = STOP;
                end
                default: begin
                end
            endcase
        end
    end

    // 3
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            bit_cnt <= 'd0;
            baud_cnt <= 'd0;
            tx <= 1'b1;
        end
        else begin
            case (current_state)
                IDLE: begin
                    bit_cnt <= 'd0;
                    baud_cnt <= 'd0;
                    tx <= 1'b1;
                end 
                START: begin
                    bit_cnt <= 'd0;
                    tx <= 1'b0;
                    if(baud_cnt == BAUD_CNT_MAX - 1)
                        baud_cnt <= 'd0;
                    else
                        baud_cnt <= baud_cnt + 1'b1;
                end
                DATA: begin
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                        tx <= tx;
                        if(bit_cnt == DATA_BIT - 1)
                            bit_cnt <= 'd0;
                        else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                        bit_cnt <= bit_cnt;
                        tx <= tx_data[bit_cnt];
                    end
                end
                CHECK: begin
                    bit_cnt <= 'd0;
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                        tx <= tx;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                        if(CHECK_MODE == "EVEN")
                            if(^tx_data)
                                tx <= 1'b1;
                            else
                                tx <= 1'b0;
                        else
                            if(^tx_data)
                                tx <= 1'b0;
                            else
                                tx <= 1'b1;
                    end
                end
                STOP: begin
                    tx <= 1'b1;
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                        if(bit_cnt == STOP_BIT - 1)
                            bit_cnt <= 'd0;
                        else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                        bit_cnt <= bit_cnt;
                    end
                end
                default: begin
                end
            endcase
        end
    end
    
endmodule
