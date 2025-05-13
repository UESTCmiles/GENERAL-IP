`timescale 1ns/1ps
/* 
    *描述:异步脉冲同步模块
    *作者:景绿川
 */
module pulse_sync (
    input clka,
    input pulsea,
    
    input clkb,
    output pulseb,

    input rst_n
);

    reg pulse;
    always@(posedge clka or negedge rst_n) begin
        if(~rst_n)
            pulse <= 1'b0;
        else if(pulsea)
            pulse <= ~pulse;
        else
            pulse <= pulse;
    end
    reg pulse_d;
    always@(posedge clkb or negedge rst_n) begin
        if(~rst_n)
            pulse_d <= 1'b0;
        else 
            pulse_d <= pulse; 
    end
    assign pulseb = pulse ^ pulse_d;
    
endmodule