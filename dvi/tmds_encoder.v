`timescale 1ns/1ps

module tmds_encoder(
    input           pix_clk,
    input           rst_n,
    input [7:0]     din,
    input           c0,
    input           c1,
    input           vde,
    output reg [9:0]dout
);

    reg [3:0]n1d;
    reg [7:0]din_d;
    always@(posedge pix_clk) begin
        n1d <= din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];
        din_d <= din; 
    end

    /* stage 1:8b->9b */
    wire flag_1;
    assign flag_1 = (n1d > 4) | ((n1d == 4) & (din_d[0] == 1'b0));

    wire [8:0]q_m;
    assign q_m[0] = din_d[0];
    assign q_m[1] = flag_1 ? (q_m[0] ^~ din_d[1]) : (q_m[0] ^ din_d[1]);
    assign q_m[2] = flag_1 ? (q_m[1] ^~ din_d[2]) : (q_m[1] ^ din_d[2]);
    assign q_m[3] = flag_1 ? (q_m[2] ^~ din_d[3]) : (q_m[2] ^ din_d[3]);
    assign q_m[4] = flag_1 ? (q_m[3] ^~ din_d[4]) : (q_m[3] ^ din_d[4]);
    assign q_m[5] = flag_1 ? (q_m[4] ^~ din_d[5]) : (q_m[4] ^ din_d[5]);
    assign q_m[6] = flag_1 ? (q_m[5] ^~ din_d[6]) : (q_m[5] ^ din_d[6]);
    assign q_m[7] = flag_1 ? (q_m[6] ^~ din_d[7]) : (q_m[6] ^ din_d[7]);
    assign q_m[8] = ~flag_1;

    /* stage 2:9b -> 10b */
    reg [3:0]n1q_0_7,n0q_0_7;
    always@(posedge pix_clk) begin
        n1q_0_7 <= q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        n0q_0_7 <= 4'd8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
    end


    localparam CTRLTOKEN0 = 10'b1101010100;
    localparam CTRLTOKEN1 = 10'b0010101011;
    localparam CTRLTOKEN2 = 10'b0101010100;
    localparam CTRLTOKEN3 = 10'b1010101011;

    reg[4:0]cnt;            //signed
    wire cnt_bgt_0,cnt_lst_0;
    assign cnt_bgt_0 = (~cnt[4]) & (|cnt[3:0]);
    assign cnt_lst_0 = cnt[4];

    wire flag_2;
    wire flag_3;
    assign flag_2 = (cnt == 0) | (n1q_0_7 == n0q_0_7);
    assign flag_3 = (cnt_bgt_0 && (n1q_0_7 > n0q_0_7)) | (cnt_lst_0 && n0q_0_7 > n1q_0_7);

    reg vde_d0,vde_d1;
    reg c0_d0,c0_d1;
    reg c1_d0,c1_d1;
    reg[8:0]q_m_d;

    always@(posedge pix_clk) begin
        vde_d0  <= vde;
        vde_d1  <= vde_d0;

        c0_d0   <= c0;
        c0_d1   <= c0_d0;
        c1_d0   <= c1;
        c1_d1   <= c1_d0;

        q_m_d   <= q_m;
    end


    /* dout */
    always@(posedge pix_clk or negedge rst_n) begin
        if(!rst_n) begin
            dout    <= 10'd0;
            cnt     <= 5'd0;
        end
        else begin
            if(vde_d1) begin
                if(flag_2) begin
                    dout[9]     <= ~q_m_d[8];
                    dout[8]     <= q_m_d[8];
                    dout[7:0]   <= q_m_d[8] ? q_m_d[7:0] : ~q_m_d[7:0];

                    cnt         <= q_m_d[8] ? (cnt + n1q_0_7 - n0q_0_7) : (cnt + n0q_0_7 - n1q_0_7);
                end
                else begin
                    if(flag_3) begin
                        dout[9]     <= 1'b1;
                        dout[8]     <= q_m_d[8];
                        dout[7:0]   <= ~q_m_d[7:0];

                        cnt         <= cnt + {q_m_d[8],1'b0} + n0q_0_7 - n1q_0_7;
                    end
                    else begin
                        dout[9]     <= 1'b0;
                        dout[8]     <= q_m_d[8];
                        dout[7:0]   <= q_m_d[7:0];

                        cnt         <= cnt - {~q_m_d[8],1'b0} + n1q_0_7 - n0q_0_7;
                    end
                end
            end
            else begin
                cnt <= 5'd0;
                case ({c1_d1,c0_d1})
                    2'b00:  dout <= CTRLTOKEN0;
                    2'b01:  dout <= CTRLTOKEN1;
                    2'b10:  dout <= CTRLTOKEN2;
                    2'b11:  dout <= CTRLTOKEN3;
                    default:dout <= 10'd0;
                endcase
            end
        end
    end


endmodule
