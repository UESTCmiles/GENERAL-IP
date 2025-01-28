`timescale 1ns / 1ps
/********************************************************************
本模块: 全流水的单精度浮点乘法器

描述:

注意：

协议:
AXIS MASTER/SLAVE

作者: 景绿川
日期: 2025/01/24
********************************************************************/


module axis_float_mul #(
	parameter en_round_in_frac_mul_res = "true", // 是否对尾数相乘结果进行四舍五入
	parameter real simulation_delay = 1 // 仿真延时
)(
    // 时钟和复位
	input wire clk,
	input wire rst_n,
	
	// 浮点乘法器输入AXIS从机
	input wire[63:0] s_axis_data, // {操作数A(32bit), 操作数B(32bit)}
	input wire s_axis_last,
	input wire s_axis_valid,
	output wire s_axis_ready,
	
	// 浮点乘法器输出
	output wire[31:0] m_axis_data, // {计算结果(32bit)}
	output wire[1:0] m_axis_user, // {上溢标志(1bit), 下溢标志(1bit)}
	output wire m_axis_last,
	output wire m_axis_valid,
	input wire m_axis_ready
);
	wire 		s_axis_ready_r;
	wire [31:0]	m_axis_data_r;
	wire [1:0]	m_axis_user_r;
	wire 		m_axis_last_r;
	wire 		m_axis_valid_r;
	
	assign s_axis_ready = s_axis_ready_r;
	assign m_axis_data = m_axis_data_r;
	assign m_axis_user = m_axis_user_r;
	assign m_axis_last = m_axis_last_r;
	assign m_axis_valid = m_axis_valid_r;

	assign s_axis_ready_r = rst_n;


	float_mult #(
		.en_round_in_frac_mul_res ( en_round_in_frac_mul_res ))
	u_float_mult (
		.clk                     ( clk                ),
		.rst_n                   ( rst_n              ),
		.s_axi_last              ( s_axis_last         ),
		.valid_i                 ( s_axis_valid            ),
		.ready_i                 ( m_axis_ready       ),
		.op_A                    ( s_axis_data[63:32] ),
		.op_B                    ( s_axis_data[31:0] ),

		.m_axi_last              ( m_axis_last_r ),
		.valid_o                 ( m_axis_valid_r ),
		.ready_o                 ( s_axis_ready_r ),
		.op_result               ( m_axis_data_r ),
		.flow                    ( m_axis_user_r )
	);
	
    
endmodule
