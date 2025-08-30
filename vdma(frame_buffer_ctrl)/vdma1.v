`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//0726：写到帧缓存读指针哪里，还剩读指针(应该写完了) 可读区域数 以及读ddraxi逻辑 
//////////////////////////////////////////////////////////////////////////////////


module vdma1 #(
		parameter C_M_AXI_BURST_LEN	        = 256,
		parameter C_M_AXI_ID_WIDTH	        = 1,
		parameter C_M_AXI_ADDR_WIDTH	    = 32,
		parameter C_M_AXI_DATA_WIDTH	    = 32,
		parameter C_M_AXI_AWUSER_WIDTH	    = 0,
		parameter C_M_AXI_ARUSER_WIDTH	    = 0,
		parameter C_M_AXI_WUSER_WIDTH	    = 0,
		parameter C_M_AXI_RUSER_WIDTH	    = 0,
		parameter C_M_AXI_BUSER_WIDTH	    = 0,
        
		parameter FRAME_0_BASE_ADDR	        = 32'h10000000,
        parameter FRAME_1_BASE_ADDR	        = 32'h11000000,
        parameter FRAME_2_BASE_ADDR	        = 32'h12000000,
        parameter IMG_H_ACTIVE              = 1280,
        parameter IMG_V_ACTIVE              = 720
)(
    input                               rst_n,

    input                               ov_pclk,
    input                               show_pclk,
    input                               M_AXI_ACLK,// axi主时钟

    // from ov5640
    input [15:0]                        ov_rgb565,
    input                               ov_vld,    
    input                               ov_frame_vld,

    // with vga_show
    input                               show_ren,
    output                              show_vld,
    output [23:0]                       show_rgb888,

    //aw
    output [C_M_AXI_ID_WIDTH-1:0]       M_AXI_AWID,
	output [C_M_AXI_ADDR_WIDTH-1:0]     M_AXI_AWADDR,
    output [7:0]                        M_AXI_AWLEN,
    output [2:0]                        M_AXI_AWSIZE,
    output [1:0]                        M_AXI_AWBURST,
    output [1:0]                        M_AXI_AWLOCK,   // ignore
    output [3:0]                        M_AXI_AWCACHE,   // ignore
    output [2:0]                        M_AXI_AWPROT,   // ignore
    output [3:0]                        M_AXI_AWQOS,   // ignore
    // output [C_M_AXI_AWUSER_WIDTH-1:0]   M_AXI_AWUSER,
	output                              M_AXI_AWVALID,
	input                               M_AXI_AWREADY,

    //w
	output [C_M_AXI_DATA_WIDTH-1:0]     M_AXI_WDATA,
    output [C_M_AXI_DATA_WIDTH/8-1:0]   M_AXI_WSTRB,
	output                              M_AXI_WLAST,
    // output [C_M_AXI_WUSER_WIDTH-1:0]    M_AXI_WUSER,
	output                              M_AXI_WVALID,
	input                               M_AXI_WREADY,

    //b
    input [C_M_AXI_ID_WIDTH-1:0]        M_AXI_BID,
    input [1:0]                         M_AXI_BRESP,
    // input [C_M_AXI_BUSER_WIDTH-1:0]     M_AXI_BUSER,
	input                               M_AXI_BVALID,
	output                              M_AXI_BREADY,

    //ar
    output [C_M_AXI_ID_WIDTH-1:0]       M_AXI_ARID,
	output [C_M_AXI_ADDR_WIDTH-1:0]     M_AXI_ARADDR,
    output [7:0]                        M_AXI_ARLEN,
    output [2:0]                        M_AXI_ARSIZE,
    output [1:0]                        M_AXI_ARBURST,
    output                              M_AXI_ARLOCK,
    output [3:0]                        M_AXI_ARCACHE,
    output [2:0]                        M_AXI_ARPROT,
    output [3:0]                        M_AXI_ARQOS,
    // output [C_M_AXI_ARUSER_WIDTH-1:0]   M_AXI_ARUSER,
	output                              M_AXI_ARVALID,
	input                               M_AXI_ARREADY,
    
    //r
    input [C_M_AXI_ID_WIDTH-1:0]        M_AXI_RID,
	input [C_M_AXI_DATA_WIDTH-1:0]      M_AXI_RDATA,
	input [1:0]                         M_AXI_RRESP,
	input                               M_AXI_RLAST,
    // input [C_M_AXI_RUSER_WIDTH-1:0]     M_AXI_RUSER,
	input                               M_AXI_RVALID,
	output                              M_AXI_RREADY

);
    // maxi
    assign M_AXI_AWID = 1'b0;
    assign M_AXI_AWLOCK = 2'd0;
    assign M_AXI_AWCACHE = 4'b0011;
    assign M_AXI_AWPROT = 3'b000;
    assign M_AXI_AWQOS = 4'd0;
    assign M_AXI_ARID = 1'b0;
    assign M_AXI_ARLOCK = 2'd0;
    assign M_AXI_ARCACHE = 4'b0011;
    assign M_AXI_ARPROT = 3'b000;
    assign M_AXI_ARQOS = 4'd0;
    assign M_AXI_RID = 1'b0;

    assign M_AXI_AWLEN = C_M_AXI_BURST_LEN - 1;
    assign M_AXI_AWSIZE = clogb2(C_M_AXI_DATA_WIDTH/8);
    assign M_AXI_AWBURST = 2'b01;

    assign M_AXI_WSTRB = {(C_M_AXI_DATA_WIDTH/8){1'b1}};
    assign M_AXI_BRESP = 2'b00;

    assign M_AXI_ARLEN = C_M_AXI_BURST_LEN - 1;
    assign M_AXI_ARSIZE = clogb2(C_M_AXI_DATA_WIDTH/8);
    assign M_AXI_ARBURST = 2'b01;

    reg [C_M_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg axi_awvalid;

    reg [C_M_AXI_DATA_WIDTH-1:0] axi_wdata;
    reg axi_wlast;
    reg axi_wvalid;

    reg axi_bready;

    reg [C_M_AXI_ADDR_WIDTH-1:0]axi_araddr;
    reg axi_arvalid;
    reg axi_rready;

    assign M_AXI_AWADDR = axi_awaddr;
    assign M_AXI_AWVALID = axi_awvalid;
    assign M_AXI_WDATA = axi_wdata;
    assign M_AXI_WLAST = axi_wlast;
    assign M_AXI_WVALID = axi_wvalid;
    assign M_AXI_BREADY = axi_bready;
    assign M_AXI_ARADDR = axi_araddr;
    assign M_AXI_ARVALID = axi_arvalid;
    assign M_AXI_RREADY = axi_rready;

    // 缓存ov数据
    wire        fifo_ov_full;
    wire        fifo_ov_empty;
    wire [9:0]  fifo_ov_rd_num;
    wire [10:0] fifo_ov_wr_num;
    wire [15:0] fifo_ov_wdata;
    wire        fifo_ov_wen;
    wire [31:0] fifo_ov_rdata;
    wire         fifo_ov_ren;
    async_fifo_16b_2048 u_fifo_ovdata (
        .rst            (~rst_n),                      // input wire rst
        .wr_clk         (ov_pclk),                // input wire wr_clk
        .rd_clk         (M_AXI_ACLK),                // input wire rd_clk
        .din            (fifo_ov_wdata),                      // input wire [15 : 0] din
        .wr_en          (fifo_ov_wen),                  // input wire wr_en
        .rd_en          (fifo_ov_ren),                  // input wire rd_en
        .dout           (fifo_ov_rdata),                    // output wire [15 : 0] dout
        .full           (fifo_ov_full),                    // output wire full
        .empty          (fifo_ov_empty),                  // output wire empty
        .rd_data_count  (fifo_ov_rd_num),  // output wire [9 : 0] rd_data_count
        .wr_data_count  (fifo_ov_wr_num)   // output wire [9 : 0] wr_data_count
    );

    assign fifo_ov_wdata = ov_rgb565;
    assign fifo_ov_wen = ov_vld & (~fifo_ov_full);
    assign fifo_ov_ren = axi_wvalid & M_AXI_WREADY;


    // 帧缓存读写指针
	reg [2:0]frame_buffer_wptr;
	reg [2:0]frame_buffer_rptr;
    wire [C_M_AXI_ADDR_WIDTH-1:0]base_addr_w;
    wire [C_M_AXI_ADDR_WIDTH-1:0]base_addr_r;
    assign base_addr_w = frame_buffer_wptr[1] ? FRAME_1_BASE_ADDR :
                         frame_buffer_wptr[2] ? FRAME_2_BASE_ADDR : FRAME_0_BASE_ADDR;
    assign base_addr_r = frame_buffer_rptr[1] ? FRAME_1_BASE_ADDR :
                         frame_buffer_rptr[2] ? FRAME_2_BASE_ADDR : FRAME_0_BASE_ADDR;

    // frame buffer 
    localparam BURST_NUM_FRAME_END = IMG_H_ACTIVE * IMG_V_ACTIVE * 16 / C_M_AXI_DATA_WIDTH / C_M_AXI_BURST_LEN;
	reg [3:0]waiting_for_read_num; // 用于指示写好的帧超过读取的帧 为0则读指针重复读当前区域

    reg [15:0]wburst_cnt;       // 写突发次数，用于判断写完一帧
	wire wr_next_frame_flag;    // 写完一帧标志
    // assign wr_next_frame_flag = axi_bready & M_AXI_BVALID & (wburst_cnt == BURST_NUM_FRAME_END - 1);
    assign wr_next_frame_flag = axi_wvalid & M_AXI_WREADY & axi_wlast & (wburst_cnt == BURST_NUM_FRAME_END - 1);
    
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            wburst_cnt <= 16'd0;
        else if(wr_next_frame_flag)
            wburst_cnt <= 16'd0;
        else if(axi_wvalid & M_AXI_WREADY & axi_wlast)
            wburst_cnt <= wburst_cnt + 1'b1;
    end
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n) 
            frame_buffer_wptr <= 3'b001;
        else if(wr_next_frame_flag)
            frame_buffer_wptr <= (frame_buffer_wptr[0] & frame_buffer_rptr[1]) ? 3'b100 :
                                 (frame_buffer_wptr[1] & frame_buffer_rptr[2]) ? 3'b001 :
                                 (frame_buffer_wptr[2] & frame_buffer_rptr[0]) ? 3'b010 : {frame_buffer_wptr[1:0],frame_buffer_wptr[2]};
    end

    reg [15:0]rburst_cnt;       // 读突发次数，用于判断是否读完一帧
	wire rd_next_frame_flag;    // 读完一帧标志
    assign rd_next_frame_flag = axi_rready & M_AXI_RVALID & M_AXI_RLAST & (rburst_cnt == BURST_NUM_FRAME_END - 1);

    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            rburst_cnt <= 16'd0;
        else if(rd_next_frame_flag)
            rburst_cnt <= 16'd0;
        else if(axi_rready & M_AXI_RVALID & M_AXI_RLAST)
            rburst_cnt <= rburst_cnt + 1'b1; 
    end

    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            frame_buffer_rptr <= 3'b000;
        else if((~frame_buffer_rptr) && frame_buffer_wptr[1])
            frame_buffer_rptr <= 3'b001;
        else if(rd_next_frame_flag && wr_next_frame_flag)
            frame_buffer_rptr <= frame_buffer_wptr;
        else if(rd_next_frame_flag && waiting_for_read_num)
            frame_buffer_rptr <= (frame_buffer_rptr[0] & frame_buffer_wptr[1]) ? 3'b100 :
                                 (frame_buffer_rptr[1] & frame_buffer_wptr[2]) ? 3'b001 :
                                 (frame_buffer_rptr[2] & frame_buffer_wptr[0]) ? 3'b010 : {frame_buffer_rptr[1:0], frame_buffer_rptr[2]};
    end

    // waiting for read num
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            waiting_for_read_num <= 4'd0;
        else if(wr_next_frame_flag & (~rd_next_frame_flag) & (waiting_for_read_num < 15))
            waiting_for_read_num <= waiting_for_read_num + 1'b1;
        else if((~wr_next_frame_flag) & rd_next_frame_flag & ( waiting_for_read_num > 0))
            waiting_for_read_num <= waiting_for_read_num - 1'b1;
    end

    // 写地址切换标志位
	reg awaddr_shift_flag;
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            awaddr_shift_flag <= 1'b0;
        else if(axi_awvalid & M_AXI_AWREADY)
            awaddr_shift_flag <= 1'b0;
        else if(wr_next_frame_flag)
            awaddr_shift_flag <= 1'b1; 
    end

    
    localparam WIDLE = 2'd0;
    localparam WADDR = 2'd1;
    localparam WDATA = 2'd2;
    localparam WRESP = 2'd3;

    reg [1:0]cs_w;
    reg [1:0]ns_w;

    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            cs_w <= WIDLE;
        else
            cs_w <= ns_w; 
    end

    always@(*) begin
        case (cs_w)
            WIDLE: ns_w = (fifo_ov_rd_num >= C_M_AXI_BURST_LEN) ? WADDR : WIDLE;
            WADDR: ns_w = (axi_awvalid & M_AXI_AWREADY) ? WDATA : WADDR;
            WDATA: ns_w = (axi_wvalid & M_AXI_WREADY & axi_wlast) ? WRESP : WDATA;
            WRESP: ns_w = (axi_bready & M_AXI_BVALID) ? WIDLE : WRESP;
            default: ns_w = WIDLE;
        endcase 
    end
    // aw
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n) begin
            axi_awaddr <= FRAME_0_BASE_ADDR;
            axi_awvalid <= 1'b0;
        end
        else begin
            case (cs_w)
                WIDLE : begin
                    axi_awaddr <= awaddr_shift_flag ? base_addr_w : axi_awaddr;
                    axi_awvalid <= 1'b0;
                end 
                WADDR : begin
                    axi_awvalid <= ~(axi_awvalid & M_AXI_AWREADY);
                end
                WRESP : begin
                    // axi_awaddr <= (M_AXI_BVALID & axi_bready) ? axi_awaddr + C_M_AXI_BURST_LEN * C_M_AXI_DATA_WIDTH / 8 : axi_awaddr; 
                    axi_awaddr <= (M_AXI_BVALID & axi_bready & wburst_cnt == 0) ? base_addr_w : 
                                  (M_AXI_BVALID & axi_bready) ? axi_awaddr + C_M_AXI_BURST_LEN * C_M_AXI_DATA_WIDTH / 8 : axi_awaddr;
                end
            endcase 
        end
    end

    // w
    reg [7:0]wr_cnt;        // 一次写突发中写的次数
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n) begin
            axi_wdata <= {C_M_AXI_DATA_WIDTH{1'b0}};
            axi_wlast <= 1'b0;
            axi_wvalid <= 1'b0;
            wr_cnt <= 8'd0;
        end 
        else begin
            case (cs_w)
                WIDLE : begin
                    axi_wdata <= {C_M_AXI_DATA_WIDTH{1'b0}};
                    axi_wlast <= 1'b0;
                    axi_wvalid <= 1'b0; 
                    wr_cnt <= 8'd0;
                end 
                WDATA : begin
                    axi_wdata <= fifo_ov_rdata; 
                    axi_wlast <= wr_cnt == C_M_AXI_BURST_LEN - 2;
                    axi_wvalid <= ~(axi_wvalid & M_AXI_WREADY & axi_wlast);
                    wr_cnt <= wr_cnt + (axi_wvalid & M_AXI_WREADY);
                end
                WRESP : begin
                    wr_cnt <= 8'd0; 
                end
            endcase 
        end
    end

    // b
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n) 
            axi_bready <= 1'b0;
        else
            case (cs_w)
                WIDLE : axi_bready <= 1'b0;
                WRESP : axi_bready <= ~(axi_bready & M_AXI_BVALID); 
            endcase
    end

    /* ******************************************************* */
    
    
    // 缓存视频流数据
    wire [31:0]fifo_show_wdata;
    wire fifo_show_wen;
    wire fifo_show_ren;
    wire [15:0]fifo_show_rdata;
    wire fifo_show_full;
    wire fifo_show_empty;
    wire [10:0]fifo_show_rd_num;
	wire [9:0]fifo_show_wr_num;

    async_fifo_32b_1024 u_fifo_show (
        .rst            (~rst_n),                    // input wire srst
        .wr_clk         (M_AXI_ACLK),
        .rd_clk         (show_pclk),
        .din            (fifo_show_wdata),                      // input wire [31 : 0] din
        .wr_en          (fifo_show_wen),                  // input wire wr_en
        .rd_en          (fifo_show_ren),                  // input wire rd_en
        .dout           (fifo_show_rdata),                    // output wire [15 : 0] dout
        .full           (fifo_show_full),                    // output wire full
        .empty          (fifo_show_empty),                  // output wire empty
        .rd_data_count  (fifo_show_rd_num),  // output wire [10 : 0] rd_data_count
        .wr_data_count  (fifo_show_wr_num)  // output wire [9 : 0] wr_data_count
    );

    // 都地址切换标志位
    reg araddr_shift_flag;
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            araddr_shift_flag <= 1'b0;
        else if(axi_arvalid & M_AXI_ARREADY)
            araddr_shift_flag <= 1'b0;
        else if(rd_next_frame_flag)
            araddr_shift_flag <= 1'b1; 
    end

    localparam RIDLE = 2'd0;
    localparam RADDR = 2'd1;
    localparam RDATA = 2'd2;

	reg [1:0]cs_r;
    reg [1:0]ns_r;

    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n)
            cs_r <= RIDLE;
        else 
            cs_r <= ns_r; 
    end

    always@(*) begin
        case (cs_r)
            RIDLE : ns_r = (frame_buffer_rptr && (fifo_show_wr_num < C_M_AXI_BURST_LEN)) ? RADDR : RIDLE;
            RADDR : ns_r = (axi_arvalid & M_AXI_ARREADY) ? RDATA : RADDR;
            RDATA : ns_r = (axi_rready & M_AXI_RVALID & M_AXI_RLAST) ? RIDLE : RDATA;
            default: ns_r = RIDLE;
        endcase 
    end

    // ar
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n) begin
            axi_araddr <= FRAME_0_BASE_ADDR;
            axi_arvalid <= 1'b0;
        end 
        else begin
            case (cs_r)
                RIDLE : begin
                    axi_araddr <= araddr_shift_flag ? base_addr_r : axi_araddr;
                    axi_arvalid <= 1'b0; 
                end 
                RADDR : begin
                    axi_arvalid <= (~axi_arvalid & M_AXI_ARREADY); 
                end
                RDATA : begin
                    axi_araddr <= (axi_rready & M_AXI_RVALID & M_AXI_RLAST) ? (axi_araddr + C_M_AXI_BURST_LEN * C_M_AXI_DATA_WIDTH / 8) : axi_araddr; 
                end
            endcase 
        end
    end

    // r
    always@(posedge M_AXI_ACLK or negedge rst_n) begin
        if(~rst_n) 
            axi_rready <= 1'b0; 
        else
            case (cs_r)
                RIDLE : axi_rready <= 1'b0;
                RADDR : axi_rready <= axi_arvalid & M_AXI_ARREADY;
                RDATA : axi_rready <= ~(axi_rready & M_AXI_RVALID & M_AXI_RLAST);
            endcase
    end

    
    assign fifo_show_wdata = M_AXI_RDATA;
    assign fifo_show_wen = axi_rready & M_AXI_RVALID;
    assign fifo_show_ren = show_ren;

    assign show_rgb888 = {fifo_show_rdata[15:11],3'd0, fifo_show_rdata[10:5],2'd0, fifo_show_rdata[4:0],3'd0};
    assign show_vld = (~fifo_show_empty) & ov_frame_vld;


    function integer clogb2(input integer len);
    begin
        if(len ==  0)
            clogb2 = 0;
        else begin
            for(clogb2 = -1; len > 0; clogb2 = clogb2 + 1)
                len  = len >> 1;
        end
    end
    endfunction
endmodule
