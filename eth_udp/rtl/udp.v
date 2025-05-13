module udp #(
    parameter BOARD_MAC_ADDR = 48'h00_11_22_33_44_55,
    parameter BOARD_IP_ADDR = {8'd192,8'd168,8'd1,8'd123}
) (
    input rst_n,
    input idelay_clk,

    // ethernet
    input       eth_rxdv,
    input       eth_rxc,
    input [3:0] eth_rxd,
    input       eth_rxer,
    
    output      eth_txen,
    output      eth_txc,
    
    output [3:0]eth_txd,
    output      eth_txer,
    
    output      eth_rst_n,

    // udp
    input       tx_start_en,
    input [31:0]tx_data,
    input [15:0]tx_byte_num,
    output      tx_pkg_done,
    output      tx_req,
    input [47:0]pc_mac_addr,
    input [31:0]pc_ip_addr,
    input [15:0]pc_udp_port,
    
    output      rx_pkg_done,
    output      rx_en,
    output [31:0]rx_data,
    output [15:0]rx_byte_num,
    output eth_rx_clk

);

    assign eth_txc = eth_rx_clk;

    wire [31:0]crc_data;
    wire [31:0]crc_current;
    wire crc_en;
    wire crc_clr;
    (*mark_debug="true"*)
    wire [7:0]rx_databyte;
    (*mark_debug="true"*)
    wire rx_databyte_en;


    /* rgmii2byte u_rgmii2byte(
        .rst_n          (rst_n),
        .eth_rxc        (eth_rxc),
        .eth_rxdv       (eth_rxdv),
        .eth_rxd        (eth_rxd),

        .rx_databyte    (rx_databyte),
        .rx_databyte_en (rx_databyte_en)
    ); */
    rgmii_rx u_rgmii2byte(
        .idelay_clk     (idelay_clk)  , //200Mhz时钟，IDELAY时钟
        
        //以太网RGMII接口
        .rgmii_rxc      (eth_rxc)   , //RGMII接收时钟
        .rgmii_rx_ctl   (eth_rxdv), //RGMII接收数据控制信号
        .rgmii_rxd      (eth_rxd)   , //RGMII接收数据    

        //以太网GMII接口
        .gmii_rx_clk    (eth_rx_clk) , //GMII接收时钟
        .gmii_rx_dv     (rx_databyte_en)  , //GMII接收数据有效信号
        .gmii_rxd       (rx_databyte)      //GMII接收数据   
    );

    udp_recv #(
        .BOARD_MAC_ADDR(BOARD_MAC_ADDR),
        .BOARD_IP_ADDR(BOARD_IP_ADDR),
        .SRC_ADDR_IGNORE(1)   // 是否忽略源地址对比
    ) u_rx(
        .rst_n      (rst_n),
        .eth_rxc    (eth_rx_clk),
        .eth_rxdv   (eth_rxdv),
        
        .rx_databyte(rx_databyte),
        .rx_databyte_en(rx_databyte_en),

        .pc_mac_addr(pc_mac_addr),
        .pc_ip_addr (pc_ip_addr),

        .rx_pkg_done(rx_pkg_done),
        .rx_en      (rx_en),
        .rx_data    (rx_data),
        .rx_byte_num(rx_byte_num)
    );
    (*mark_debug="true"*)
    wire [7:0]tx_databyte;
    (*mark_debug="true"*)
    wire tx_databyte_en;
    udp_send #(
        . BOARD_MAC_ADDR(BOARD_MAC_ADDR),
        . BOARD_IP_ADDR(BOARD_IP_ADDR),
        . BOARD_UDP_PORT(16'd1234)
    ) u_tx(
        .rst_n  (rst_n),

        .eth_txc(eth_txc),
        .eth_txd_tmp(tx_databyte),
        .eth_txen_tmp(tx_databyte_en),

        .tx_start(tx_start_en),
        .tx_data(tx_data),
        .tx_req(tx_req),
        .tx_pkg_done(tx_pkg_done),

        .tx_byte_num(tx_byte_num),
        .dest_mac_addr(pc_mac_addr),
        .dest_ip_addr(pc_ip_addr),
        .dest_udp_port(pc_udp_port),

        .crc_data(crc_data),
        .crc_current(crc_current[31:24]),
        .crc_en(crc_en),
        .crc_clr(crc_clr)
    );
    
    crc32_d8 u_crc(
        .rst_n(rst_n),
        .clk(eth_txc),

        .data_in(tx_databyte),

        .crc_en(crc_en),
        .crc_clr(crc_clr),

        .crc_data(crc_data),
        .crc_data_c(crc_current)
    );

    byte2rgmii u_byte2rgmii(
        .rst_n          (rst_n),
        .eth_txc        (eth_txc),
        .tx_databyte    (tx_databyte),
        .tx_databyte_en (tx_databyte_en),

        .eth_txen       (eth_txen),
        .eth_txd        (eth_txd)
    );

    assign eth_txer = 1'b0;
    assign eth_rst_n = rst_n;
endmodule