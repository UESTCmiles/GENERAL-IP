/* 
功能：带反压的单精度浮点乘法器，4级流水线
版本：2.0 
*/
module float_mult #(
    parameter en_round_in_frac_mul_res = "true"//四舍五入
) (
    input clk,
    input rst_n,

    input s_axi_last,
    output m_axi_last,

    input valid_i,
    output valid_o,

    input ready_i,
    output ready_o,

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

    reg valid_r1;
    wire ready_r1;   
    assign ready_o = (~valid_r1) | ready_r1;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            valid_r1 <= 1'b0;
        else if(ready_o)
            valid_r1 <= valid_i;
        else
            valid_r1 <= valid_r1;
    end

    reg axi_last_r1;

    reg 		A_sign_r1;
	reg [7:0]	A_exp_r1;
	reg [23:0]	A_frac_r1;
	reg 		B_sign_r1;
	reg [7:0]	B_exp_r1;
	reg [23:0]	B_frac_r1;

    always@(posedge clk) begin
        if(valid_i && ready_o) begin
            axi_last_r1 <= s_axi_last;

            A_sign_r1   <= A_sign;
            B_sign_r1   <= B_sign;

            A_exp_r1    <= A_exp;
            B_exp_r1    <= B_exp;

            A_frac_r1   <= A_frac;
            B_frac_r1   <= B_frac;
        end
    end

    /* **********stage2*********** */

	wire 		    C_sign;
	wire signed[9:0]C_exp_tmp;
	wire [47:0]     C_frac_tmp;
	
	assign C_sign 		= A_sign_r1 ^ B_sign_r1;
	assign C_exp_tmp 	= A_exp_r1 + B_exp_r1 - 8'sd127;
	assign C_frac_tmp	= A_frac_r1 * B_frac_r1;

    reg valid_r2;
    wire ready_r2;
    assign ready_r1 = (~valid_r2) | ready_r2;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            valid_r2 <= 1'b0;
        else if(ready_r1)
            valid_r2 <= valid_r1;
        else
            valid_r2 <= valid_r2;
    end

    reg axi_last_r2;

    reg 		A_sign_r2;
	reg [7:0]	A_exp_r2;
	reg [23:0]	A_frac_r2;
	reg 		B_sign_r2;
	reg [7:0]	B_exp_r2;
	reg [23:0]	B_frac_r2;
    reg 		    C_sign_r2;
	reg signed[9:0]C_exp_tmp_r2;
    reg [47:0]     C_frac_tmp_r2;
    
    always@(posedge clk) begin
        if(valid_r1 && ready_r1) begin
            axi_last_r2     <= axi_last_r1;

            A_sign_r2       <= A_sign_r1;
            B_sign_r2       <= B_sign_r1;
            C_sign_r2       <= C_sign;

            A_exp_r2        <= A_exp_r1;
            B_exp_r2        <= B_exp_r1;
            C_exp_tmp_r2    <= C_exp_tmp;

            A_frac_r2       <= A_frac_r1;
            B_frac_r2       <= B_frac_r1;
            C_frac_tmp_r2   <= C_frac_tmp;
        end 
    end

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

    reg valid_r3;
    wire ready_r3;
    assign ready_r2 = (~valid_r3) | ready_i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            valid_r3 <= 1'b0; 
        else if(ready_r2)
            valid_r3 <= valid_r2;
        else
            valid_r3 <= valid_r3;
    end

    reg axi_last_r3;

    reg 		A_sign_r3;
	reg [7:0]	A_exp_r3;
	reg [23:0]	A_frac_r3;
	reg 		B_sign_r3;
	reg [7:0]	B_exp_r3;
	reg [23:0]	B_frac_r3;
    reg 		    C_sign_r3;
	reg signed[9:0]C_exp_r3;
    reg [22:0]     C_frac_r3;
    always@(posedge clk) begin
        if(valid_r2 && ready_r2) begin
            axi_last_r3 <= axi_last_r2;

            A_sign_r3   <= A_sign_r2;
            B_sign_r3   <= B_sign_r2;
            C_sign_r3   <= C_sign_r2;

            A_exp_r3    <= A_exp_r2;
            B_exp_r3    <= B_exp_r2;
            C_exp_r3    <= C_exp;

            A_frac_r3   <= A_frac_r2;
            B_frac_r3   <= B_frac_r2;
            C_frac_r3   <= C_frac;

        end 
    end


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

    assign m_axi_last = axi_last_r3;
    assign valid_o = valid_r3;
endmodule