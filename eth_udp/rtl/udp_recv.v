`timescale 1ns/1ps
/* 
*2025.4.18 太多组合逻辑，感觉不对
*2025.4.23 添加数据层转byte模块，此模块即可兼容所有接口

 */
module udp_recv #(
    parameter BOARD_MAC_ADDR = 48'hff_ff_ff_ff_ff_ff,
    parameter BOARD_IP_ADDR = {8'd192,8'd168,8'd1,8'd102},
    parameter PROTOCOL = 8'd17,        // ICMP:1 TCP:6 UDP:17
    parameter SRC_ADDR_IGNORE = 1   // 是否忽略源地址对比
) (
    input rst_n,
    input eth_rxc,
    input eth_rxdv,
    
    input [7:0]rx_databyte,
    input rx_databyte_en,

    input [47:0]pc_mac_addr,
    input [31:0]pc_ip_addr,

    output rx_pkg_done,
    output rx_en,
    output [31:0]rx_data,
    output [15:0]rx_byte_num
);

    reg eth_rxdv_d;
    always@(posedge eth_rxc) eth_rxdv_d <= eth_rxdv;

    localparam IDLE = 4'd0;
    localparam PREAMBLE = 4'd1;
    localparam ETH_HEAD = 4'd2;
    localparam IP_HEAD = 4'd3;
    localparam UDP_HEAD = 4'd4;
    localparam RECV_DATA = 4'd5;
    localparam STOP = 4'd6;

    reg [3:0]cstate;
    reg [3:0]nstate;

    wire skip_en;
    wire err_en;
    reg [15:0]cnt;

    reg [47:0]recv_dest_mac_addr;
    reg dest_mac_addr_en;
    reg [47:0]recv_src_mac_addr;
    reg src_mac_addr_en;
    reg [15:0]recv_len_type;

    // ip
    reg [3:0]ip_version;
    reg [3:0]ip_head_len;
    reg [15:0]total_len;
    reg [15:0]cur_id;// ignore
    reg [7:0]recv_prot;          // should be 17
    reg [31:0]recv_dest_ip_addr;
    reg [31:0]recv_src_ip_addr;

    // udp
    reg [15:0]recv_src_udp_id;
    reg [15:0]recv_dest_udp_id;
    reg [15:0]udp_len;

    wire [5:0]ip_head_num;
    assign ip_head_num = ({ip_head_len,2'b00} > 6'd20) ? {ip_head_len,2'b00} : 6'd20;

    // data
    reg [31:0]rxdata_r;
    reg rxen_r;


    always@(posedge eth_rxc or negedge rst_n) begin
        if(~rst_n)
            cstate <= IDLE;
        else
            cstate <= nstate;
    end   

    always@(*) begin
        case (cstate)
            IDLE : nstate = skip_en ? PREAMBLE : IDLE;
            PREAMBLE: nstate = err_en ? STOP : (skip_en ? ETH_HEAD : PREAMBLE);
            ETH_HEAD: nstate = err_en ? STOP : (skip_en ? IP_HEAD : ETH_HEAD);
            IP_HEAD: nstate = err_en ? STOP : (skip_en ? UDP_HEAD : IP_HEAD);
            UDP_HEAD: nstate = err_en ? STOP : (skip_en ? RECV_DATA : UDP_HEAD);
            RECV_DATA: nstate = err_en ? STOP : (skip_en ? STOP : RECV_DATA);
            STOP: nstate = skip_en ? IDLE : STOP;
            default: nstate = IDLE;
        endcase 
    end

    always@(posedge eth_rxc or negedge rst_n) begin
        if(~rst_n)
            cnt <= 16'd0;
        else
            case (cstate)
                IDLE: begin
                    if(rx_databyte_en) begin
                        if(rx_databyte == 8'h55) begin
                            cnt <= cnt + 1'b1;
                        end
                        else begin
                            cnt <= 1'b0;
                        end
                    end
                    else begin
                        cnt <= 16'd0;
                    end
                end 
                PREAMBLE: begin
                    if(rx_databyte_en) 
                        if(cnt == 7) 
                            cnt <= 16'd0;
                        else
                            cnt <= cnt + 1'b1;
                    else
                        cnt <= 16'd0;
                end
                ETH_HEAD: begin
                    if(rx_databyte_en)
                        if(cnt == 13)
                            cnt <= 16'd0;
                        else
                            cnt <= cnt + 1'b1;
                    else
                        cnt <= 16'd0;
                end
                IP_HEAD: begin
                    if(rx_databyte_en)
                        if(cnt == ip_head_num - 1'b1)
                            cnt <= 16'd0;
                        else
                            cnt <= cnt + 1'b1;
                    else
                        cnt <= 16'd0; 
                end
                UDP_HEAD: begin
                    if(rx_databyte_en)
                        if(cnt == 7)
                            cnt <= 16'd0;
                        else 
                            cnt <= cnt + 1'b1;
                    else
                        cnt <= 16'd0; 
                end
                RECV_DATA: begin
                    if(rx_databyte_en)
                        if(cnt == rx_byte_num - 1'b1)
                            cnt <= 16'd0;
                        else
                            cnt <= cnt + 1'b1;
                    else
                        cnt <= 16'd0; 
                end
                default: begin
                    cnt <= 16'd0;   
                end
            endcase 
    end 

    // eth_head_decoder
    always@(posedge eth_rxc or negedge rst_n) begin
        if(~rst_n) begin
            recv_dest_mac_addr <= 48'd0;
            recv_src_mac_addr <= 48'd0; 

            dest_mac_addr_en <= 1'b0;
            src_mac_addr_en <= 1'b0;

            recv_len_type <= 16'd0;
        end 
        else begin
            if(cstate == ETH_HEAD && rx_databyte_en) begin
                if(cnt >= 0 && cnt < 6) begin
                    recv_dest_mac_addr[47-cnt*8-:8] <= rx_databyte;
                    recv_src_mac_addr <= recv_src_mac_addr; 

                    dest_mac_addr_en <= (cnt == 5);
                    src_mac_addr_en <= src_mac_addr_en;
                    
                    recv_len_type <= recv_len_type;
                end
                else if(cnt >= 6 && cnt < 12) begin
                    recv_dest_mac_addr <= recv_dest_mac_addr;
                    recv_src_mac_addr[47-(cnt-6)*8-:8] <= rx_databyte;

                    dest_mac_addr_en <= dest_mac_addr_en;
                    src_mac_addr_en <= (cnt == 11);

                    recv_len_type <= recv_len_type;
                end
                else begin
                    recv_dest_mac_addr <= recv_dest_mac_addr;
                    recv_src_mac_addr <= recv_src_mac_addr; 

                    dest_mac_addr_en <= dest_mac_addr_en;
                    src_mac_addr_en <= src_mac_addr_en;

                    recv_len_type[15-(cnt-12)*8-:8] <= rx_databyte;
                end
            end 
            else begin
                recv_dest_mac_addr <= recv_dest_mac_addr;
                recv_src_mac_addr <= recv_src_mac_addr; 

                dest_mac_addr_en <= 1'b0;
                src_mac_addr_en <= 1'b0;

                recv_len_type <= recv_len_type;
            end
        end
    end

    // ip_head_decoder
    always@(posedge eth_rxc or negedge rst_n) begin
        if(~rst_n) begin
            ip_head_len <= 4'd0;
            total_len <= 16'd0;
            cur_id <= 16'd0;
            recv_prot <= 8'd0;
            recv_src_ip_addr <= 32'd0;
            recv_dest_ip_addr <= 32'd0;
        end 
        else if(cstate == IP_HEAD && rx_databyte_en) begin
            if(cnt == 0)
                ip_head_len <= rx_databyte[3:0];
            else if((cnt >= 2) && (cnt < 4))
                total_len <= {total_len[7:0],rx_databyte};
            else if((cnt >= 4) && (cnt < 6))
                cur_id <= {cur_id[7:0],rx_databyte};
            else if(cnt == 9)
                recv_prot <= rx_databyte;
            else if((cnt >= 12) && (cnt < 16))
                recv_src_ip_addr <= {recv_src_ip_addr[23:0],rx_databyte};
            else if((cnt >= 16) && (cnt < 20))
                recv_dest_ip_addr <= {recv_dest_ip_addr[23:0],rx_databyte};
        end
    end

    // udp_decoder
    always@(posedge eth_rxc or negedge rst_n) begin
        if(~rst_n) begin
            recv_src_udp_id <= 16'd0;
            recv_dest_udp_id <= 16'd0;
            udp_len <= 16'd0; 
        end 
        else if(cstate == UDP_HEAD && rx_databyte_en)
            if((cnt >= 0) && (cnt < 2))
                recv_src_udp_id <= {recv_src_udp_id[7:0],rx_databyte};
            else if((cnt >= 2) && (cnt < 4))
                recv_dest_udp_id <= {recv_dest_udp_id[7:0],rx_databyte};
            else if((cnt >= 4) && (cnt < 6))
                udp_len <= {udp_len[7:0],rx_databyte};
    end

    // data decoder
    always@(posedge eth_rxc or negedge rst_n) begin
        if(~rst_n) begin
            rxdata_r <= 32'd0;
            rxen_r <= 1'b0; 
        end 
        else if(cstate == RECV_DATA && rx_databyte_en) begin
            rxen_r <= ((cnt[1:0] == 2'b11 ) || (cnt == rx_byte_num - 1'b1)); 
            case (cnt[1:0])
                2'd0:rxdata_r[31:24] <= rx_databyte;
                2'd1:rxdata_r[23:16] <= rx_databyte;
                2'd2:rxdata_r[15:8] <= rx_databyte;
                2'd3:rxdata_r[7:0] <= rx_databyte; 
            endcase
        end
        else begin
            rxdata_r <= 32'd0;
            rxen_r <= 1'b0; 
        end
    end

    // skip_en
    assign skip_en =    (cstate == IDLE) ? (rx_databyte_en && rx_databyte == 8'h55) : 
                        (cstate == PREAMBLE) ? (rx_databyte_en && cnt == 16'd7) :
                        (cstate == ETH_HEAD) ? (rx_databyte_en && cnt == 16'd13) : 
                        (cstate == IP_HEAD) ? (rx_databyte_en && cnt == ip_head_num - 1'b1) : 
                        (cstate == UDP_HEAD) ? (rx_databyte_en && cnt == 16'd7) : 
                        (cstate == RECV_DATA) ? (rx_databyte_en && cnt == rx_byte_num - 1'b1) :
                        (cstate == STOP) ? (~eth_rxdv_d) : 1'b0;

    assign err_en =     (cstate == PREAMBLE) ? (~eth_rxdv_d || (rx_databyte_en && (cnt < 7) && (rx_databyte != 8'h55)) || 
                                (rx_databyte_en && (cnt == 7) && (rx_databyte != 8'hd5))):
                        (cstate == ETH_HEAD) ? (~eth_rxdv_d || (dest_mac_addr_en && (recv_dest_mac_addr != BOARD_MAC_ADDR) && 
                                (recv_dest_mac_addr != 48'hff_ff_ff_ff_ff_ff)) || 
                                (src_mac_addr_en && (recv_src_mac_addr != pc_mac_addr) && (!SRC_ADDR_IGNORE))) : 
                        (cstate == IP_HEAD) ? (~eth_rxdv_d || ((cnt > 9) && (recv_prot != PROTOCOL)) ||
                                ((cnt > 15) && (recv_src_ip_addr != pc_ip_addr) && (!SRC_ADDR_IGNORE)) || 
                                (rx_databyte_en && (cnt == 19) && ((recv_dest_ip_addr[23:0] != BOARD_IP_ADDR[31:8]) || (rx_databyte != BOARD_IP_ADDR[7:0])))) :
                        1'b0;
        
    assign rx_byte_num = udp_len - 16'd8;

    assign rx_en = rxen_r;
    assign rx_data = rxdata_r;
    assign rx_pkg_done = (cstate == STOP) && (~eth_rxdv_d);

    
endmodule