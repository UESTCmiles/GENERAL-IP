`timescale 1ns/1ps

/*  *描述: dvi信号
    *使用了xilinx原语OBUFDS：单端信号转为差分信号
    *如有移植需求，请更换原语例化*/

module vga2dvi(
    input       pix_clk,
    input       pix_clk_5x,

    input       rst_n,

    input [23:0]rgb_data,
    input       hs,
    input       vs,
    input       de,

    output      tmds_clk_p,
    output      tmds_clk_n,
    output [2:0]tmds_data_p,
    output [2:0]tmds_data_n,
    output      tmds_oen
);

    assign tmds_oen = 1'b1;

    wire [9:0]clk_10bit = 10'b1111100000;
    wire [9:0]r_10bit;
    wire [9:0]g_10bit;
    wire [9:0]b_10bit;

    wire clk_ser;
    wire r_ser;
    wire g_ser;
    wire b_ser;

    // tmds编码
    tmds_encoder u_tmds_r(
        .pix_clk    (pix_clk),
        .rst_n      (rst_n),
        .din        (rgb_data[23:16]),
        .c0         (1'b0),
        .c1         (1'b0),
        .vde        (de),
        .dout       (r_10bit)
    );
    tmds_encoder u_tmds_g(
        .pix_clk    (pix_clk),
        .rst_n      (rst_n),
        .din        (rgb_data[15:8]),
        .c0         (1'b0),
        .c1         (1'b0),
        .vde        (de),
        .dout       (g_10bit)
    );  
    tmds_encoder u_tmds_b(
        .pix_clk    (pix_clk),
        .rst_n      (rst_n),
        .din        (rgb_data[7:0]),
        .c0         (hs),
        .c1         (vs),
        .vde        (de),
        .dout       (b_10bit)
    );

    // 并行转
    parallel2serial u_p2s_clk(
        .pix_clk        (pix_clk),
        .pix_clk_5x     (pix_clk_5x),
        .rst_n          (rst_n),

        .parallel_data  (clk_10bit),
        .serial_data    (clk_ser)   
    );  
    parallel2serial u_p2s_r(
        .pix_clk        (pix_clk),
        .pix_clk_5x     (pix_clk_5x),
        .rst_n          (rst_n),

        .parallel_data  (r_10bit),
        .serial_data    (r_ser)   
    );  
    parallel2serial u_p2s_g(
        .pix_clk        (pix_clk),
        .pix_clk_5x     (pix_clk_5x),
        .rst_n          (rst_n),

        .parallel_data  (g_10bit),
        .serial_data    (g_ser)   
    );  
    parallel2serial u_p2s_b(
        .pix_clk        (pix_clk),
        .pix_clk_5x     (pix_clk_5x),
        .rst_n          (rst_n),

        .parallel_data  (b_10bit),
        .serial_data    (b_ser)   
    );  

    //转差分信号
    OBUFDS #(
		.IOSTANDARD("TMDS_33")
    ) u_obufds_clk (
        .O(tmds_clk_p),            // 1-bit output: Diff_p output (connect directly to top-level port)
        .OB(tmds_clk_n),          // 1-bit output: Diff_n output (connect directly to top-level port)
        .I(clk_ser)             // 1-bit input: Buffer input
    );
    OBUFDS #(
		.IOSTANDARD("TMDS_33")
    ) u_obufds_r (
        .O(tmds_data_p[2]),            // 1-bit output: Diff_p output (connect directly to top-level port)
        .OB(tmds_data_n[2]),          // 1-bit output: Diff_n output (connect directly to top-level port)
        .I(r_ser)             // 1-bit input: Buffer input
    );
    OBUFDS #(
		.IOSTANDARD("TMDS_33")
    ) u_obufds_g (
        .O(tmds_data_p[1]),            // 1-bit output: Diff_p output (connect directly to top-level port)
        .OB(tmds_data_n[1]),          // 1-bit output: Diff_n output (connect directly to top-level port)
        .I(g_ser)             // 1-bit input: Buffer input
    );
    OBUFDS #(
		.IOSTANDARD("TMDS_33")
    ) u_obufds_b (
        .O(tmds_data_p[0]),            // 1-bit output: Diff_p output (connect directly to top-level port)
        .OB(tmds_data_n[0]),          // 1-bit output: Diff_n output (connect directly to top-level port)
        .I(b_ser)             // 1-bit input: Buffer input
    );



endmodule