module eth_send_top #(
    parameter BOARD_MAC_ADDR = 48'h00_11_22_33_44_55,
    parameter BOARD_IP_ADDR = {8'd192,8'd168,8'd1,8'd10},
    parameter BOARD_UDP_PORT = 16'd1234,
    parameter PC_MAC_ADDR = 48'hff_ff_ff_ff_ff_ff,
    parameter PC_IP_ADDR = {8'd192,8'd168,8'd1,8'd102},
    parameter PC_UDP_PORT = 16'd1234
) (
    input rst_n,

    // ethernet
    input       eth_rxdv,
    input       eth_rxc,
    input [7:0] eth_rxd,

    output      eth_txen,
    output      eth_txc,
    output [7:0]eth_txd,
    output      eth_txer,
    
    output      eth_rst_n


);
    assign eth_txc = eth_rxc;

    wire tx_start_en;
    wire [31:0]tx_data;
    wire [15:0]tx_byte_num = 16'd50;

    wire tx_pkg_done;
    wire tx_req;

    // 创建发送数据
    reg [31:0]fifo_din;
    reg fifo_wren;
    reg [7:0]cnt;
    reg start_flag;
    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n)
            start_flag <= 1'b0;
        else if(cnt == tx_byte_num - 1)
            start_flag <= 1'b0;
        else if(eth_rxdv == 1'b1 && eth_rxd == 8'h55)
            start_flag <= 1'b1;
        else
            start_flag <= start_flag;
    end

    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n)
            cnt <= 8'd0;
        else if(start_flag == 1'b1)
            if(cnt == tx_byte_num - 1)
                cnt <= 8'd0;
            else
                cnt <= cnt + 1'b1;
        else
            cnt <= cnt; 
    end

    always@(posedge eth_txc or negedge rst_n) begin
        if(~rst_n) begin
            fifo_din <= 32'd0;
            fifo_wren <= 1'b0;
        end 
        else if(start_flag) begin
            fifo_din <= {fifo_din[23:0],cnt};
            fifo_wren <= (cnt[1:0] == 2'b11 || cnt == tx_byte_num - 1);
        end
        else begin
            fifo_din <= 32'd0;
            fifo_wren <= 1'b0; 
        end
    end

    assign tx_start_en = cnt == tx_byte_num - 1;

    wire [7:0]tx_databyte;
    wire tx_databyte_en;

    wire [31:0]crc_data;
    wire [31:0]crc_current;
    wire crc_en;
    wire crc_clr;

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
        .dest_mac_addr(PC_MAC_ADDR),
        .dest_ip_addr(PC_IP_ADDR),
        .dest_udp_port(PC_UDP_PORT),

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

    byte2gmii u_b2g(
        .rst_n          (rst_n),
        .eth_txc        (eth_txc),
        .tx_databyte    (tx_databyte),
        .tx_databyte_en (tx_databyte_en),

        .eth_txen       (eth_txen),
        .eth_txd        (eth_txd)
);
    wire full;
    wire empty;
    fifo u_fifo (
        .rst(~rst_n),        // input wire rst
        .wr_clk(eth_rxc),  // input wire wr_clk
        .rd_clk(eth_txc),  // input wire rd_clk
        .din(fifo_din),        // input wire [31 : 0] din
        .wr_en(fifo_wren),    // input wire wr_en
        .rd_en(tx_req),    // input wire rd_en
        .dout(tx_data),      // output wire [31 : 0] dout
        .full(full),      // output wire full
        .empty(empty)    // output wire empty
    );
    
endmodule