`timescale 1ns/1ps
module test_bench();
	reg [31:0] a, b;
	wire [31:0] c, output_a, output_b;
	reg stb, rst, clk, next_PE_ack, input_b_valid, mem_select;
	wire input_ack, output_b_valid, output_stb;
	reg [1:0] addr;
	PE #(2, 1) pe
	(
		.a(a),
		.b(b),
		.stb(stb),
		.rst(rst),
		.clk(clk),
		.next_PE_ack(next_PE_ack),
		.input_ack(input_ack),
		.input_b_valid(input_b_valid),
		.output_b_valid(output_b_valid),
		.addr(addr),
		.mem_select(mem_select),
		.c(c),
		.output_b(output_b), 
		.output_a(output_a),
		.output_stb(output_stb)
	);
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
		rst = 1;
		#15 rst = 0;
		stb = 1;
		next_PE_ack = 1;
		input_b_valid = 1;
		mem_select = 0;
		addr = 2'b0;
		a = 32'b0_01111111_00000000000000000000000;
		b = 32'b0_01111111_00000000000000000000000;
	end
endmodule
