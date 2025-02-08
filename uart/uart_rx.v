`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/19 14:11:03
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
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
    input rx,
    output reg[7:0]rx_data,
    output reg rx_valid
);
    /* temp signal */
    localparam BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE;
    reg [15:0]baud_cnt;
    reg [2:0]bit_cnt;

    reg [7:0]tmp_data;
    reg tmp_valid;

    reg rx_d0;
    reg rx_d1;
    wire rx_falling;
    reg work_en;

    /* 状态机 */
    localparam IDLE = 3'd0;
    localparam START= 3'd1;
    localparam DATA = 3'd2;
    localparam CHECK = 3'd3;
    localparam STOP = 3'd4;
    reg [2:0]current_state;
    reg [2:0]next_state;

    /* logic */
    //work_en使能
    always@(posedge clk) begin
        rx_d0 <= rx;
        rx_d1 <= rx_d0;
    end

    assign rx_falling = (~rx_d0) & rx_d1;
    always@(posedge clk or posedge rst) begin
        if(rst)
            work_en <= 1'b0;
        else if(rx_falling)
            work_en <= 1'b1;
        else if(current_state == DATA)
            work_en <= 1'b0;
        else
            work_en <= work_en;
    end

    //状态机
    //1
    always@(posedge clk or posedge rst) begin
        if(rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //2
    always@(*) begin
        if(rst) begin
            next_state = IDLE;
        end
        else begin
            case (current_state)
                IDLE:begin
                    if(work_en) begin
                        next_state = START;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end 
                START:begin
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        next_state = DATA;
                    end
                    else begin
                        next_state = START;
                    end
                end
                DATA:begin
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        if(bit_cnt == DATA_BIT - 1) begin
                            if(CHECK_BIT == 'd0)
                                next_state = STOP;
                            else
                                next_state = CHECK;
                        end
                        else begin
                            next_state = DATA;
                        end
                    end
                    else begin
                        next_state = DATA;
                    end
                end
                CHECK:begin
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        next_state = STOP;
                    end                   
                    else begin
                        next_state = CHECK;
                    end
                end
                STOP:begin
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        if(bit_cnt == STOP_BIT - 1) begin
                            if(work_en)
                                next_state = START;
                            else
                                next_state = IDLE;
                        end
                        else begin
                            next_state = STOP;
                        end
                    end
                    else begin
                        next_state = STOP;
                    end

                end
                default:begin
                end 
            endcase
        end
    end

    //3
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            tmp_data <= 8'd0;
            tmp_valid <= 1'b0;
            baud_cnt <= 'd0;
            bit_cnt <= 'd0;
        end
        else begin
            case (current_state)
                IDLE:begin
                    tmp_data <= tmp_data;
                    tmp_valid <= 1'b0;
                    baud_cnt <= 'd0;
                    bit_cnt <= 'd0;
                end 
                START:begin
                    tmp_data <= 8'd0;
                    tmp_valid <= 1'b0;
                    bit_cnt <= 'd0;
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end
                DATA:begin
                    if(baud_cnt == BAUD_CNT_MAX / 2 ) begin
                        tmp_valid <= 1'b0;
                        tmp_data <= {rx_d0,tmp_data[7:1]};
                        baud_cnt <= baud_cnt + 1'b1;
                        bit_cnt <= bit_cnt;
                    end
                    else if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                        if(bit_cnt == DATA_BIT - 1) begin
                            bit_cnt <= 3'd0;
                            tmp_data <= tmp_data;
                            if(CHECK_BIT == 'd0)
                                tmp_valid <= 1'b1;
                            else
                                tmp_valid <= 1'b0;
                        end
                        else begin
                            tmp_valid <= 1'b0;
                            bit_cnt <= bit_cnt + 1'b1;
                            tmp_data <= tmp_data;
                        end
                    end
                    else begin
                        tmp_valid <= 1'b0;
                        baud_cnt <= baud_cnt + 1'b1;
                        tmp_data <= tmp_data;
                        bit_cnt <= bit_cnt;
                    end
                end
                CHECK:begin
                    bit_cnt <= 'd0;
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                        tmp_valid <= tmp_valid;
                        tmp_data <= tmp_data;
                    end                   
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                        if(baud_cnt == BAUD_CNT_MAX / 2)
                            if(CHECK_MODE == "EVEN")
                                if((^tmp_data) ^ rx_d0 == 0) begin
                                    tmp_valid <= 1'b1;
                                    tmp_data <= tmp_data;
                                end
                                else begin
                                    tmp_valid <= 1'b0;
                                    tmp_data <= 8'd0;
                                end
                            else
                                if((^tmp_data) ^ rx_d0 == 1) begin
                                    tmp_valid <= 1'b1;
                                    tmp_data <= tmp_data;
                                end
                                else begin
                                    tmp_valid <= 1'b0;
                                    tmp_data <= 8'd0;
                                end
                        else begin
                            tmp_valid <= tmp_valid;
                            tmp_data <= tmp_data;
                        end
                    end
                end
                STOP:begin
                    tmp_valid <= tmp_valid;
                    tmp_data <= tmp_data;
                    if(baud_cnt == BAUD_CNT_MAX - 1) begin
                        baud_cnt <= 'd0;
                        if(bit_cnt == STOP_BIT - 1) begin
                            bit_cnt <= 3'd0;
                        end
                        else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                        bit_cnt <= bit_cnt;
                    end

                end
                default:begin
                end 
            endcase
        end
    end
    
    //rx_valid
    always@(posedge clk or posedge rst) begin
        if(rst)
            rx_valid <= 1'b0;
        else
            rx_valid <= tmp_valid;
    end

    //rx_data
    always@(posedge clk or posedge rst) begin
        if(rst)
            rx_data <= 'd0;
        else if(tmp_valid)
            rx_data <= tmp_data;
        else
            rx_data <= rx_data;
    end
    // assign rx_data = tmp_data;
    // assign rx_valid = tmp_valid;

    // /* ila */
    // ila_0 u_ila (
    //     .clk(clk), // input wire clk


    //     .probe0(rx_data), // input wire [7:0]  probe0  
    //     .probe1(current_state), // input wire [2:0]  probe1 
    //     .probe2(bit_cnt), // input wire [2:0]  probe2 
    //     .probe3(rx_d0), // input wire [0:0]  probe3 
    //     .probe4(work_en) // input wire [0:0]  probe4
    // );
endmodule

