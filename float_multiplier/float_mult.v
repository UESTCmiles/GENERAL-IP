/* 
功能；单精度浮点乘法器，不带反压
版本：1.0

 */
module float_mult #(
    parameter en_round_in_frac_mul_res = "true"//四舍五入
) (
    input clk,
    input rst_n,

    input s_axi_last,
    output m_axi_last,

    input s_axi_valid,
    output m_axi_valid,

    input [31:0]op_A,
    input [31:0]op_B,
    output [31:0]op_result,
    output [1:0]flow            // 1:上溢出 0：下溢出
);  
    /* ********stage1********* */
    wire 		A_sign;
	wire [7:0]	A_exp;
	wire [23:0]	A_frac;
	wire 		B_sign;
	wire [7:0]	B_exp;
	wire [23:0]	B_frac;

	assign {A_sign, A_exp} 	= op_A[31:23];
	assign A_frac			= {1'b1, op_A[22:0]};
	assign {B_sign, B_exp} 	= op_B[31:23];
	assign B_frac			= {1'b1, op_B[22:0]};

    wire axi_valid_r1;
    wire axi_last_r1;
    dff_rn #(1) u_1_valid(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(s_axi_valid), .data_o(axi_valid_r1));
    dff_rn #(1) u_1_last(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(s_axi_last), .data_o(axi_last_r1));

    wire 		A_sign_r1;
	wire [7:0]	A_exp_r1;
	wire [23:0]	A_frac_r1;
	wire 		B_sign_r1;
	wire [7:0]	B_exp_r1;
	wire [23:0]	B_frac_r1;
    dff_rn #(1) u_1_as(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_sign), .data_o(A_sign_r1));
    dff_rn #(1) u_1_bs(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_sign), .data_o(B_sign_r1));
    dff_rn #(8) u_1_ae(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_exp), .data_o(A_exp_r1));
    dff_rn #(8) u_1_be(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_exp), .data_o(B_exp_r1));
    dff_rn #(24) u_1_af(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_frac), .data_o(A_frac_r1));
    dff_rn #(24) u_1_bf(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_frac), .data_o(B_frac_r1));

    /* **********stage2*********** */

	wire 		    C_sign;
	wire signed[9:0]C_exp_tmp;
	wire [47:0]     C_frac_tmp;
	
	assign C_sign 		= A_sign_r1 ^ B_sign_r1;
	assign C_exp_tmp 	= A_exp_r1 + B_exp_r1 - 8'sd127;
	assign C_frac_tmp	= A_frac_r1 * B_frac_r1;

    wire axi_valid_r2;
    wire axi_last_r2;
    dff_rn #(1) u_2_valid(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(axi_valid_r1), .data_o(axi_valid_r2));
    dff_rn #(1) u_2_last(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(axi_last_r1), .data_o(axi_last_r2));

    wire 		A_sign_r2;
	wire [7:0]	A_exp_r2;
	wire [23:0]	A_frac_r2;
	wire 		B_sign_r2;
	wire [7:0]	B_exp_r2;
	wire [23:0]	B_frac_r2;
    wire 		    C_sign_r2;
	wire signed[9:0]C_exp_tmp_r2;
    wire [47:0]     C_frac_tmp_r2;
    dff_rn #(1) u_2_as(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_sign_r1), .data_o(A_sign_r2));
    dff_rn #(1) u_2_bs(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_sign_r1), .data_o(B_sign_r2));
    dff_rn #(8) u_2_ae(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_exp_r1), .data_o(A_exp_r2));
    dff_rn #(8) u_2_be(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_exp_r1), .data_o(B_exp_r2));
    dff_rn #(24) u_2_af(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_frac_r1), .data_o(A_frac_r2));
    dff_rn #(24) u_2_bf(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_frac_r1), .data_o(B_frac_r2));
    
    dff_rn #(1) u_2_cs(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(C_sign), .data_o(C_sign_r2));
    dff_rn #(10) u_2_ce(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(C_exp_tmp), .data_o(C_exp_tmp_r2));
    dff_rn #(48) u_2_cf(.clk(clk), .rst_n(rst_n), .rst_data(48'd0), .data_i(C_frac_tmp), .data_o(C_frac_tmp_r2));

    /* ***********stage3************ */

	reg signed[9:0]	C_exp;
	reg [22:0] 	    C_frac;
	
	always@(*) begin
		if(C_frac_tmp_r2[47]) begin
			C_frac = C_frac_tmp_r2[46:24] + {22'b0, (en_round_in_frac_mul_res == "true") & C_frac_tmp_r2[23]};// 四舍五入
			C_exp  = C_exp_tmp_r2 + 1'b1;
		end
		else begin
			C_frac = C_frac_tmp_r2[45:23] + {22'b0, (en_round_in_frac_mul_res == "true") & C_frac_tmp_r2[22]};// 四舍五入
			C_exp  = C_exp_tmp_r2;
		end
	end

    wire axi_valid_r3;
    wire axi_last_r3;
    dff_rn #(1) u_3_valid(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(axi_valid_r2), .data_o(axi_valid_r3));
    dff_rn #(1) u_3_last(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(axi_last_r2), .data_o(axi_last_r3));

    wire 		A_sign_r3;
	wire [7:0]	A_exp_r3;
	wire [23:0]	A_frac_r3;
	wire 		B_sign_r3;
	wire [7:0]	B_exp_r3;
	wire [23:0]	B_frac_r3;
    wire 		    C_sign_r3;
	wire signed[9:0]C_exp_r3;
    wire [22:0]     C_frac_r3;
    dff_rn #(1) u_3_as(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_sign_r2), .data_o(A_sign_r3));
    dff_rn #(1) u_3_bs(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_sign_r2), .data_o(B_sign_r3));
    dff_rn #(8) u_3_ae(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_exp_r2), .data_o(A_exp_r3));
    dff_rn #(8) u_3_be(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_exp_r2), .data_o(B_exp_r3));
    dff_rn #(24) u_3_af(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(A_frac_r2), .data_o(A_frac_r3));
    dff_rn #(24) u_3_bf(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(B_frac_r2), .data_o(B_frac_r3));
    
    dff_rn #(1) u_3_cs(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(C_sign_r2), .data_o(C_sign_r3));
    dff_rn #(10) u_3_ce(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(C_exp), .data_o(C_exp_r3));
    dff_rn #(23) u_3_cf(.clk(clk), .rst_n(rst_n), .rst_data(0), .data_i(C_frac), .data_o(C_frac_r3));


    /* *********stage4*********** */
    wire overflow;
    wire underflow;
    assign overflow = (C_exp_r3 >= 9'sd255);
    assign underflow = (C_exp_r3 <= 0);

    assign op_result = (((A_exp_r3 == 8'hff) && (A_frac_r3 != 0)) || ((B_exp_r3 == 8'hff) && (B_frac_r3 != 0))) ?   // 有NAN 则输出NAN
                        {C_sign_r3, 8'hff, C_frac_r3} :                           
                        ((((A_exp_r3 == 8'hff) && (A_frac_r3 == 0)) || ((B_exp_r3 == 8'hff) && (B_frac_r3 == 0))) ?  // 有INF
                            (((A_exp_r3 == 0) || (B_exp_r3 == 0)) ? {C_sign_r3, 8'hff, C_frac_r3} : {C_sign_r3, 8'hff, 23'd0}) : 
                        (((A_exp_r3 == 0) || (B_exp_r3 == 0)) ?                                           // 有ZERO
                            {C_sign_r3, 31'd0} : ( overflow ? 
                                {C_sign_r3, 8'd255, 23'd0} : (underflow ? 
                                    {C_sign_r3 ,31'd0} : {C_sign_r3, C_exp_r3[7:0], C_frac_r3}))));             
	//assign op_result = (C_exp >= 9'sd255) ? {C_sign, 8'd255, 23'd0} : ((C_exp <= 0) ? {C_sign ,31'd0} : {C_sign, C_exp[7:0], C_frac});
	// 上溢出、下溢出、正常
    
    assign flow = 
    (A_exp_r3 != 8'hff) & (B_exp_r3 != 8'hff) & (A_exp_r3 != 0) & (B_exp_r3 != 0) ? (overflow ? 2'b10 : (underflow ? 2'b01 : 2'b00)) : 2'b00;

    assign m_axi_valid = axi_valid_r3;
    assign m_axi_last = axi_last_r3;
endmodule