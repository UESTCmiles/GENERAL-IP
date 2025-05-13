`timescale 1ns/1ps
module eth_gmii_top #(
    parameter BOARD_MAC_ADDR = 48'h00_11_22_33_44_55,
    parameter BOARD_IP_ADDR = {8'd192,8'd168,8'd1,8'd10},
    parameter BOARD_UDP_PORT = 16'd1234,
    parameter PC_MAC_ADDR = 48'hff_ff_ff_ff_ff_ff,
    parameter PC_IP_ADDR = {8'd192,8'd168,8'd1,8'd102},
    parameter PC_UDP_PORT = 16'd1234
) (
    input clk,
    input rst_n,

    // ethernet
    input       eth_rxdv,
    input       eth_rxc,
    input [3:0] eth_rxd,

    output      eth_txen,
    output      eth_txc,
    output [3:0]eth_txd,
    
    output      eth_rst_n


);

    wire rec_pkg_done; //以太网单包数据接收完成信号
    (*mark_debug="true"*)
    wire rec_en ; //以太网接收的数据使能信号
    (*mark_debug="true"*)
    wire [31:0] rec_data ; //以太网接收的数据
    wire [15:0] rec_byte_num; //以太网接收的有效字节数 单位:byte
    wire tx_pkg_done ; //以太网发送完成信号
    (*mark_debug="true"*)
    wire tx_req ; //读数据请求信号
    wire tx_start_en ; //以太网开始发送信号
    (*mark_debug="true"*)
    wire [31:0] tx_data ; //以太网待发送数据

//*****************************************************

//** main code

//*****************************************************
    wire idelay_clk;
    // pll
    pll u_pll
   (
    // Clock out ports
    .clk_out1(idelay_clk),     // output clk_out1
    // Status and control signals
    .reset(~rst_n), // input reset
    .locked(),       // output locked
   // Clock in ports
    .clk_in1(clk));

    wire eth_rx_clk;
    //UDP模块
    udp #(
        .BOARD_MAC_ADDR(BOARD_MAC_ADDR),
        .BOARD_IP_ADDR(BOARD_IP_ADDR)
    ) u_udp(
        .rst_n(rst_n),
        .idelay_clk(idelay_clk),

        // ethernet
        .eth_rxdv(eth_rxdv),
        .eth_rxc(eth_rxc),
        .eth_rxd(eth_rxd),
        .eth_rxer(1'b0),

        .eth_txen(eth_txen),
        .eth_txc(eth_txc),
        .eth_txd(eth_txd),
        .eth_txer(),
        
        .eth_rst_n(eth_rst_n),

        // udp
        .tx_start_en(tx_start_en),
        .tx_data(tx_data),
        .tx_byte_num(rec_byte_num),
        .tx_pkg_done(tx_pkg_done),
        .tx_req(tx_req),
        .pc_mac_addr(PC_MAC_ADDR),
        .pc_ip_addr(PC_IP_ADDR),
        .pc_udp_port(PC_UDP_PORT),
        
        .rx_pkg_done(rec_pkg_done),
        .rx_en(rec_en),
        .rx_data(rec_data),
        .rx_byte_num(rec_byte_num),
        .eth_rx_clk(eth_rx_clk)

    );
    //脉冲信号同步处理模块
    /* pulse_sync u_pulse_sync(
        .clka (eth_rx_clk),
        .rst_n (rst_n),
        .pulsea (rec_pkg_done),
        .clkb (eth_txc),
        .pulseb (tx_start_en)
    );  */
    assign tx_start_en = rec_pkg_done;
 

    //fifo模块，用于缓存单包数据
    fifo u_fifo (
        .rst(~rst_n),        // input wire rst
        .wr_clk(eth_rx_clk),  // input wire wr_clk
        .rd_clk(eth_txc),  // input wire rd_clk
        .din(rec_data),        // input wire [31 : 0] din
        .wr_en(rec_en),    // input wire wr_en
        .rd_en(tx_req),    // input wire rd_en
        .dout(tx_data),      // output wire [31 : 0] dout
        .full(),      // output wire full
        .empty()    // output wire empty
    );
    
endmodule