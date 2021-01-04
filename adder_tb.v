module adder_tb();
	reg[7:0] a, b;
	reg start, reset, clk;
	wire[7:0] s;
	wire ready;
	adder #(.expWidth(3), .mantissaWidth(4)) ADDER (a, b, s, clk, start, ready, reset);
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	initial begin
		reset = 0;
		#5 reset = 1;
		a = 8'b0_010_1111;
		b = 8'b1_001_0101;
		start = 1;
		#200 $stop;
	end
endmodule