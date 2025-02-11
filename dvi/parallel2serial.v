`timescale 1ns/1ps
/*  *描述：并行10bit转串行 
    *使用到了xilinx原语:OSERDESE2用于双边采样，可降低时钟频率
    *如有移植需求，请更换原语例化，否则只能使用10倍频时钟*/

module parallel2serial(
    input pix_clk,
    input pix_clk_5x,
    input rst_n,

    input [9:0]parallel_data,
    output serial_data
);  
    wire [1:0]cascade;
    
    OSERDESE2#(
        .DATA_RATE_OQ       ("DDR"),
        .DATA_RATE_TQ       ("SDR"),
        .DATA_WIDTH         (10),
        .SERDES_MODE        ("MASTER"),
        .TBYTE_CTL          ("FALSE"),
        .TBYTE_SRC          ("FALSE"),
        .TRISTATE_WIDTH     (1)
    )u_master(
        .CLK                (pix_clk_5x),
        .CLKDIV             (pix_clk),
        .RST                (~rst_n),
        .OCE                (1'b1),

        .OQ                 (serial_data),

        .D1                 (parallel_data[0]),
        .D2                 (parallel_data[1]),
        .D3                 (parallel_data[2]),
        .D4                 (parallel_data[3]),
        .D5                 (parallel_data[4]),
        .D6                 (parallel_data[5]),
        .D7                 (parallel_data[6]),
        .D8                 (parallel_data[7]),

        .SHIFTIN1           (cascade[0]),
        .SHIFTIN2           (cascade[1]),
        .SHIFTOUT1          (),
        .SHIFTOUT2          (),

        .OFB                (),
        .T1                 (0),
        .T2                 (0),
        .T3                 (0),
        .T4                 (0),
        .TBYTEIN            (0),
        .TCE                (0),
        .TBYTEOUT           (),
        .TFB                (),
        .TQ                 ()
    );

    OSERDESE2#(
        .DATA_RATE_OQ       ("DDR"),
        .DATA_RATE_TQ       ("SDR"),
        .DATA_WIDTH         (10),
        .SERDES_MODE        ("SLAVE"),
        .TBYTE_CTL          ("FALSE"),
        .TBYTE_SRC          ("FALSE"),
        .TRISTATE_WIDTH     (1)
    )u_slave(
        .CLK                (pix_clk_5x),
        .CLKDIV             (pix_clk),
        .RST                (~rst_n),
        .OCE                (1'b1),

        .OQ                 (),

        .D1                 (1'b0),
        .D2                 (1'b0),
        .D3                 (parallel_data[8]),
        .D4                 (parallel_data[9]),
        .D5                 (1'b0),
        .D6                 (1'b0),
        .D7                 (1'b0),
        .D8                 (1'b0),

        .SHIFTIN1           (),
        .SHIFTIN2           (),
        .SHIFTOUT1          (cascade[0]),
        .SHIFTOUT2          (cascade[1]),

        .OFB                (),
        .T1                 (0),
        .T2                 (0),
        .T3                 (0),
        .T4                 (0),
        .TBYTEIN            (0),
        .TCE                (0),
        .TBYTEOUT           (),
        .TFB                (),
        .TQ                 ()
    );


endmodule
