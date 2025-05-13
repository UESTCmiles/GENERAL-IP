`timescale 1ns/1ps
module udp_send #(
    parameter BOARD_MAC_ADDR = 48'h00_11_22_33_44_55,
    parameter BOARD_IP_ADDR = {8'd192,8'd168,8'd1,8'd123},
    parameter BOARD_UDP_PORT = 16'd1234,
    parameter IP_VERSION = 4'd4,
    parameter IP_HEAD_LEN = 4'd5,
    parameter PROTOCOL = 8'd17,
    parameter IP_TTL = 8'h40,
    parameter IP_FLAGS = 3'h2
) (
    input rst_n,

    input eth_txc,
    output [7:0]eth_txd_tmp,
    output eth_txen_tmp,

    input tx_start,
    input [31:0]tx_data,
    output tx_req,
    output tx_pkg_done,

    input [15:0]tx_byte_num,
    input [47:0]dest_mac_addr,
    input [31:0]dest_ip_addr,
    input [15:0]dest_udp_port,

    input [31:0]crc_data,
    input [7:0]crc_current,
    output crc_en,
    output crc_clr
);

    reg [7:0]tx_databyte;
    reg tx_databyte_en;
    assign eth_txd_tmp = tx_databyte;
    assign eth_txen_tmp = tx_databyte_en;

    localparam IDLE = 3'd0;
    localparam CHECKSUM = 3'd1;
    localparam PREAMBLE = 3'd2;
    localparam ETH_HEAD = 3'd3;
    localparam IP_UDP_HEAD = 3'd4;
    localparam SEND_DATA = 3'd5;
    localparam CRC = 3'd6;

    reg [2:0]cstate;
    reg [2:0]nstate;


    wire skip_en;

    reg [15:0]identification;   // 每发送一次报文+1
    reg [31:0]ip_checksum;

    reg [10:0]cnt;
    wire [15:0]ip_tot_len = tx_byte_num + 16'd28;
    wire [15:0]udp_tot_len = tx_byte_num + 16'd8;

    reg tx_req_r;
    reg crc_en_r;
    reg tx_pkg_done_r;

    wire [1:0]cnt_data_byte;

    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n)
            cstate <= IDLE;
        else
            cstate <= nstate; 
    end

    always@(*) begin
        case (cstate)
            IDLE: nstate = skip_en ? CHECKSUM : IDLE;
            CHECKSUM: nstate = skip_en ? PREAMBLE : CHECKSUM;
            PREAMBLE: nstate = skip_en ? ETH_HEAD : PREAMBLE;
            ETH_HEAD: nstate = skip_en ? IP_UDP_HEAD : ETH_HEAD;
            IP_UDP_HEAD: nstate = skip_en ? SEND_DATA : IP_UDP_HEAD;
            SEND_DATA: nstate = skip_en ? CRC : SEND_DATA;
            CRC: nstate = skip_en ? IDLE : CRC;
            default: nstate = IDLE;
        endcase 
    end

    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n) 
            cnt <= 11'd0;
        else
            case (cstate)
                IDLE: cnt <= 11'd0; 
                CHECKSUM: cnt <= (cnt == 11'd3) ? 11'd0 : (cnt + 1'b1);
                PREAMBLE: cnt <= (cnt == 11'd7) ? 11'd0 : (cnt + 1'b1);
                ETH_HEAD: cnt <= (cnt == 11'd13) ? 11'd0 : (cnt + 1'b1);
                IP_UDP_HEAD: cnt <= (cnt == 11'd27) ? 11'd0 : (cnt + 1'b1);
                SEND_DATA: cnt <= (cnt == tx_byte_num - 1) ? 11'd0 : (cnt + 1'b1);
                CRC: cnt <= (cnt == 11'd3) ? 11'd0 : (cnt + 1'b1);
                default: cnt <= 11'd0;
            endcase
    end

    assign cnt_data_byte = (cstate == SEND_DATA) ? cnt[1:0] : 2'd0;

    
    // identification
    always @(posedge eth_txc or negedge rst_n) begin
        if(~rst_n)
            identification <= 16'd0; 
        else if(tx_pkg_done)
            identification <= identification + 1'b1;
        else
            identification <= identification;
    end

    //checksum
    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n) 
            ip_checksum <= 32'd0;
        else if(cstate == CHECKSUM)     
            case (cnt)
                11'd0: ip_checksum <= {IP_VERSION,IP_HEAD_LEN,8'd0} + ip_tot_len + identification + 
                                        {IP_FLAGS,13'd0} + {IP_TTL,PROTOCOL} + BOARD_IP_ADDR[31:16] + 
                                        BOARD_IP_ADDR[15:0] + dest_ip_addr[31:16] + dest_ip_addr[15:0];
                11'd1,11'd2: ip_checksum <= {16'd0,ip_checksum[31:16]} + {16'd0,ip_checksum[15:0]};
                11'd3: ip_checksum[15:0] <= ~ip_checksum[15:0];
                default: ip_checksum <= ip_checksum;
            endcase
        else
            ip_checksum <= ip_checksum;
    end

    //tx_databyte
    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n) begin
            tx_databyte <= 8'd0;
            tx_databyte_en <= 1'b0; 
            tx_req_r <= 1'b0;
            crc_en_r <= 1'b0;
        end
        else begin
            case (cstate)
                PREAMBLE: begin
                    tx_databyte_en <= 1'b1;
                    tx_databyte <= (cnt == 11'd7) ? 8'hd5 : 8'h55;
                    tx_req_r <= 1'b0;
                    crc_en_r <= 1'b0;
                end 
                ETH_HEAD: begin
                    tx_databyte_en <= 1'b1;
                    tx_databyte <= (cnt >= 11'd0 && cnt < 11'd6) ? dest_mac_addr[47-cnt*8-:8] :
                                (cnt >= 11'd6 && cnt < 11'd12) ? BOARD_MAC_ADDR[95-cnt*8-:8] : 
                                (cnt == 11'd12) ? 8'h08 : 8'h00;
                    tx_req_r <= 1'b0;
                    crc_en_r <= 1'b1;
                end
                IP_UDP_HEAD: begin
                    tx_databyte_en <= 1'b1;
                    tx_databyte <= (cnt == 11'd0) ? {IP_VERSION,4'd5} :
                                    (cnt == 11'd1) ? 8'd00 :
                                    (cnt == 11'd2) ? ip_tot_len[15:8] : 
                                    (cnt == 11'd3) ? ip_tot_len[7:0] : 
                                    (cnt == 11'd4) ? identification[15:8] :
                                    (cnt == 11'd5) ? identification[7:0] :
                                    (cnt == 11'd6) ? {3'd2,5'd0} : 
                                    (cnt == 11'd7) ? 8'd0 :
                                    (cnt == 11'd8) ? IP_TTL :
                                    (cnt == 11'd9) ? PROTOCOL :
                                    (cnt == 11'd10) ? ip_checksum[15:8] :
                                    (cnt == 11'd11) ? ip_checksum[7:0] : 
                                    (cnt >= 11'd12 && cnt < 11'd16) ? BOARD_IP_ADDR[31-(cnt-12)*8-:8] :
                                    (cnt >= 11'd16 && cnt < 11'd20) ? dest_ip_addr[31-(cnt-16)*8-:8] : 
                                    (cnt == 11'd20) ? BOARD_UDP_PORT[15:8] :
                                    (cnt == 11'd21) ? BOARD_UDP_PORT[7:0] :
                                    (cnt == 11'd22) ? dest_udp_port[15:8] :
                                    (cnt == 11'd23) ? dest_udp_port[7:0] :
                                    (cnt == 11'd24) ? udp_tot_len[15:8] :
                                    (cnt == 11'd25) ? udp_tot_len[7:0] : 8'd0;
                    tx_req_r <= 1'b0;
                    crc_en_r <= 1'b1;
                end 
                SEND_DATA: begin
                    tx_databyte_en <= 1'b1;
                    tx_databyte <= tx_data[31-cnt_data_byte*8-:8];
                    tx_req_r <= (cnt_data_byte == 2'b10);
                    crc_en_r <= 1'b1;
                end
                CRC: begin
                    tx_databyte_en <= 1'b1;
                    tx_databyte <= (cnt == 11'd0) ? {~crc_current[0],~crc_current[1],~crc_current[2],~crc_current[3],
                                                        ~crc_current[4],~crc_current[5],~crc_current[6],~crc_current[7]} :
                                    (cnt == 11'd1) ? {~crc_data[16],~crc_data[17],~crc_data[18],~crc_data[19],
                                                        ~crc_data[20],~crc_data[21],~crc_data[22],~crc_data[23]} :
                                    (cnt == 11'd2) ? {~crc_data[8],~crc_data[9],~crc_data[10],~crc_data[11],
                                                        ~crc_data[12],~crc_data[13],~crc_data[14],~crc_data[15]} : 
                                    (cnt == 11'd3) ? {~crc_data[0],~crc_data[1],~crc_data[2],~crc_data[3],
                                                        ~crc_data[4],~crc_data[5],~crc_data[6],~crc_data[7]} : 8'd0;
                    tx_req_r <= 1'b0;
                    crc_en_r <= 1'b0;
                end
                default: begin
                    tx_databyte_en <= 1'b0;
                    tx_databyte <= 8'd0; 
                    tx_req_r <= 1'b0;
                    crc_en_r <= 1'b0;
                end
            endcase 
        end
    end

    // tx pkg done
    always @(posedge eth_txc or negedge rst_n) begin
        if(~rst_n)
            tx_pkg_done_r <= 1'b0;
        else if(cstate == CRC && cnt == 11'd3)
            tx_pkg_done_r <= 1'b1;
        else
            tx_pkg_done_r <= 1'b0;
    end
    assign skip_en =    (cstate == IDLE) ? tx_start : 
                        (cstate == CHECKSUM) ? (cnt == 11'd3) : 
                        (cstate == PREAMBLE) ? (cnt == 11'd7) : 
                        (cstate == ETH_HEAD) ? (cnt == 11'd13) :
                        (cstate == IP_UDP_HEAD) ? (cnt == 11'd27) : 
                        (cstate == SEND_DATA) ? (cnt == tx_byte_num - 1) :
                        (cstate == CRC) ? (cnt == 11'd3) : 1'b0;


    assign tx_req = tx_req_r;
    assign crc_en = crc_en_r;
    assign tx_pkg_done = tx_pkg_done_r;
    assign crc_clr = tx_pkg_done_r;
endmodule