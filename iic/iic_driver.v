`timescale 1ns / 1ps
/* 
描述：IIC主机
作者：景绿川
 */


module iic_driver(
    input clk,
    output clk_dri,   // 4倍以上scl频率
    input rst_n,

    input iic_exec,     // 启动iic传输
    input bit_ctrl,     // 字地址 0：8bit 1：16bit
    input [6:0]iic_id,  // 器件地址
    input [1:0]iic_mode,//2'b00:写 2'b10:当前读 2'b11:随机读
    input [7:0]iic_rw_len, // 读写长度
    input [15:0]iic_addr,
    input [7:0]iic_wdata,
    output iic_wbyte_done,  // 写完一个字节标志

    output [7:0]iic_rdata,
    output iic_rbyte_done,  // 读完一个字节标志
    output reg iic_done,

    output iic_err_flag,
    output reg iic_idle,

    output scl,
    inout sda
);
    reg clk_drive;
    reg [4:0]div_cnt;
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            div_cnt <= 5'd0;
        else if(div_cnt == 5'd24)
            div_cnt <= 5'd0;
        else
            div_cnt <= div_cnt + 1'b1;
    end

    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)
            clk_drive <= 1'b0;
        else if(div_cnt == 5'd24)
            clk_drive <= ~clk_drive; 
    end

    assign clk_dri = clk_drive;
    localparam IDLE = 4'd0;
    localparam WR_CRT_RD_STA = 4'd1;
    localparam IIC_ID_W = 4'd2;
    localparam IIC_ADDR_H = 4'd3;
    localparam IIC_ADDR_L = 4'd4;
    localparam WR_DATA = 4'd5;
    localparam RAND_RD_STA = 4'd6;
    localparam IIC_ID_R = 4'd7;
    localparam RD_DATA = 4'd8;
    localparam STOP = 4'd9;
    reg [3:0]c_state;
    reg [3:0]n_state;

    reg sda_out;
    wire sda_in;
    reg sda_dir;    // 1:out 0:in
    reg scl_r;
    assign sda = sda_dir ? sda_out : 1'bz;
    assign sda_in = sda;
    assign scl = scl_r;

    reg err_flag;
    assign iic_err_flag = err_flag;        


    reg tran_done_flag; // 传输完成标志
    reg [7:0]rw_cnt;    // 读写计数
    reg [1:0]iic_clk_cnt;
    reg [3:0]bit_cnt;   // 位计数
    reg [7:0]rdata;
    always@(posedge clk_drive or negedge rst_n) begin
        if(~rst_n)
            c_state <= IDLE;
        else
            c_state <= n_state; 
    end

    always@(*) begin
        case (c_state)
            IDLE:           n_state = iic_exec ? WR_CRT_RD_STA : IDLE;
            WR_CRT_RD_STA:  n_state = tran_done_flag ? ((^iic_mode) ? IIC_ID_R : IIC_ID_W) : WR_CRT_RD_STA;
            IIC_ID_W:       n_state = tran_done_flag ? (bit_ctrl ? IIC_ADDR_H : IIC_ADDR_L) : IIC_ID_W;
            IIC_ADDR_H:     n_state = tran_done_flag ? IIC_ADDR_L : IIC_ADDR_H;
            IIC_ADDR_L:     n_state = tran_done_flag ? (iic_mode[1] ? RAND_RD_STA : WR_DATA) : IIC_ADDR_L;
            WR_DATA:        n_state = tran_done_flag ? (rw_cnt == iic_rw_len ? STOP : WR_DATA) : WR_DATA;
            RAND_RD_STA:    n_state = tran_done_flag ? IIC_ID_R : RAND_RD_STA;
            IIC_ID_R:       n_state = tran_done_flag ? RD_DATA : IIC_ID_R;
            RD_DATA:        n_state = tran_done_flag ? (rw_cnt == iic_rw_len ? STOP : RD_DATA) : RD_DATA;
            STOP:           n_state = tran_done_flag ? IDLE : STOP;
            default:        n_state = IDLE;
        endcase 
    end

    always@(posedge clk_drive or negedge rst_n) begin
        if(~rst_n) begin
            sda_out <= 1'b1;
            sda_dir <= 1'b1; 
            scl_r   <= 1'b1;
            tran_done_flag <= 1'b0;
            rw_cnt <= 8'd0;
            err_flag <= 1'b0;
            rdata <= 8'd0;
            iic_done <= 1'b0;
            iic_idle <= 1'b0;
        end
        else begin
            case (c_state)
                IDLE: begin
                    sda_out <= 1'b1;
                    sda_dir <= 1'b1; 
                    scl_r   <= 1'b1;
                    tran_done_flag <= 1'b0;
                    rw_cnt <= 8'd0;  
                    err_flag <= 1'b0;    
                    rdata <= 8'd0;
                    iic_done <= 1'b0;
                    iic_idle <= 1'b1;
                end
                WR_CRT_RD_STA,RAND_RD_STA: begin
                    iic_idle <= 1'b0;
                    sda_dir <= 1'b1;
                    case (iic_clk_cnt)
                        2'd1: begin
                            sda_out <= 1'b1;
                            scl_r <= 1'b1;
                            tran_done_flag <= 1'b0;
                        end
                        2'd2: begin
                            sda_out <= 1'b0;
                            scl_r <= 1'b1; 
                            tran_done_flag <= 1'b1;
                        end 
                        2'd3: begin
                            sda_out <= 1'b0;
                            scl_r <= 1'b0;
                            tran_done_flag <= 1'b0;
                        end
                        default: begin
                            sda_out <= 1'b1;
                            scl_r <= (c_state == WR_CRT_RD_STA);
                            tran_done_flag <= 1'b0;
                        end
                    endcase
                end
                IIC_ID_W,IIC_ADDR_H,IIC_ADDR_L,WR_DATA,IIC_ID_R: begin
                    if(bit_cnt == 4'd8) begin
                        rw_cnt <= rw_cnt;
                        case (iic_clk_cnt)
                            2'd0: begin
                                sda_dir <= 1'b0;
                                sda_out <= sda_out;
                                scl_r <= 1'b0;
                                
                                tran_done_flag <= 1'b0;

                                err_flag <= 1'b0;
                            end 
                            2'd1: begin
                                sda_dir <= sda_dir;
                                sda_out <= sda_out;
                                scl_r <= 1'b1;

                                tran_done_flag <= 1'b0; 

                                err_flag <= 1'b0;
                            end
                            2'd2: begin
                                sda_dir <= sda_dir;
                                sda_out <= sda_out;
                                scl_r <= 1'b1;

                                tran_done_flag <= 1'b1; 
                                err_flag <= sda_in;
                            end
                            2'd3: begin
                                sda_dir <= sda_dir;
                                sda_out <= sda_out;
                                scl_r <= 1'b0;

                                tran_done_flag <= 1'b0; 
                                err_flag <= 1'b0;
                            end
                        endcase
                    end
                    else begin
                        tran_done_flag <= 1'b0;
                        sda_dir <= 1'b1;
                        err_flag <= 1'b0;
                        case(iic_clk_cnt) 
                            2'd0: begin
                                rw_cnt <= rw_cnt;
                                sda_out <= (c_state == IIC_ADDR_H) ? iic_addr[15 - bit_cnt] : 
                                            (c_state == IIC_ADDR_L) ? iic_addr[7 - bit_cnt] : 
                                            (c_state == WR_DATA) ? iic_wdata[7 - bit_cnt] : 
                                            (bit_cnt == 4'd7) ? (c_state == IIC_ID_R) : iic_id[6 - bit_cnt];
                                scl_r <= 1'b0;
                            end
                            2'd3: begin
                                rw_cnt <= rw_cnt + (c_state == WR_DATA && bit_cnt == 4'd7);
                                sda_out <= sda_out;
                                scl_r <= 1'b0; 
                            end
                            default: begin
                                rw_cnt <= rw_cnt;
                                sda_out <= sda_out;
                                scl_r <= 1'b1;
                            end
                        endcase 
                    end
                end
                RD_DATA: begin
                    if(bit_cnt == 4'd8) begin
                            rw_cnt  <= rw_cnt;
                        case (iic_clk_cnt)
                            2'd0: begin
                                sda_dir <= 1'b1;
                                sda_out <= (rw_cnt == iic_rw_len);
                                scl_r   <= 1'b0;
                                rdata   <= rdata;
                                tran_done_flag <= 1'b0;
                            end 
                            2'd1: begin
                                sda_dir <= 1'b1;
                                sda_out <= sda_out;
                                scl_r   <= 1'b1;
                                rdata   <= rdata; 
                                tran_done_flag <= 1'b0;
                            end
                            2'd2: begin
                                sda_dir <= 1'b1;
                                sda_out <= sda_out;
                                scl_r   <= 1'b1;
                                rdata   <= rdata; 
                                tran_done_flag <= 1'b1;
                            end
                            2'd3: begin
                                sda_dir <= 1'b1;
                                sda_out <= sda_out;
                                scl_r   <= 1'b0;
                                rdata   <= rdata;
                                tran_done_flag <= 1'b0;
                            end
                        endcase 
                    end
                    else begin
                        sda_dir <= 1'b0;
                        sda_out <= sda_out;
                        tran_done_flag <= 1'b0;
                        case (iic_clk_cnt)
                            2'd0: begin
                                rw_cnt  <= rw_cnt;
                                scl_r <= 1'b0;
                                rdata <= rdata;
                            end 
                            2'd3: begin
                                rw_cnt  <= rw_cnt + (bit_cnt == 4'd7);
                                scl_r <= 1'b0;
                                rdata <= rdata; 
                            end
                            default: begin
                                rw_cnt  <= rw_cnt;
                                scl_r <= 1'b1;
                                rdata[7-bit_cnt] <= sda_in; 
                            end
                        endcase 
                    end
                end
                STOP: begin
                    sda_dir <= 1'b1;
                    case (iic_clk_cnt)
                        2'd0: begin
                            tran_done_flag <= 1'b0;
                            sda_out <= 1'b0;
                            scl_r   <= 1'b0;
                        end 
                        2'd1: begin
                            tran_done_flag <= 1'b1;
                            sda_out <= 1'b0;
                            scl_r   <= 1'b1;
                        end
                        default: begin
                            tran_done_flag <= iic_clk_cnt == 2'd2;
                            sda_out <= 1'b1;
                            scl_r   <= 1'b1;
                            iic_done <= iic_clk_cnt == 2'd2;
                        end
                    endcase
                end
                default: begin
                    sda_out <= 1'b1;
                    sda_dir <= 1'b1; 
                    scl_r   <= 1'b1;
                    tran_done_flag <= 1'b0;
                    rw_cnt <= 8'd0;  
                    err_flag <= 1'b0;    
                    rdata <= 8'd0;
                    iic_done <= 1'b0;
                end
            endcase 
        end
    end 

    always@(posedge clk_drive or negedge rst_n) begin
        if(~rst_n) begin
            bit_cnt <= 4'd0; 
            iic_clk_cnt <= 2'd0; 
        end 
        else begin
            case (c_state)
                IDLE : begin
                    bit_cnt <= 4'd0;
                    iic_clk_cnt <= 2'd0; 
                end
                WR_CRT_RD_STA,RAND_RD_STA,STOP: begin
                    bit_cnt <= 4'd0;
                    if(iic_clk_cnt == 2'd3)
                        iic_clk_cnt <= 2'd0;
                    else
                        iic_clk_cnt <= iic_clk_cnt + 1'b1;
                end    
                IIC_ID_W,IIC_ADDR_H,IIC_ADDR_L,WR_DATA,IIC_ID_R,RD_DATA: begin
                    if(iic_clk_cnt == 2'd3) begin
                        iic_clk_cnt <= 2'd0;
                        if(bit_cnt == 4'd8)
                            bit_cnt <= 4'd0;
                        else
                            bit_cnt <= bit_cnt + 1'b1;
                    end 
                    else begin
                        iic_clk_cnt <= iic_clk_cnt + 1'b1;
                        bit_cnt <= bit_cnt; 
                    end
                end
            endcase 
        end
    end

    assign iic_rdata = rdata;
    assign iic_wbyte_done = (c_state == WR_DATA) & tran_done_flag;
    assign iic_rbyte_done = (c_state == RD_DATA) & tran_done_flag;
endmodule
