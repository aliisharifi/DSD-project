module matrix_multiplier #(parameter log_size) 
(
	input [31:0] a,
	input [31:0] b,
	input in_stb,
	input rst,
	input clk,
	input out_ack,
	output out_stb,
	output in_ack);


	parameter n = 2 ** log_size;
 
	reg [31:0] a_queue [n : 1];
	
	///////////
	wire [31:0] a_wires [n : 0];
	wire [31:0] b_wires [n : 0];
	wire stb_wires [n : 0];
	wire ack_wires [n : 0];
	wire b_valid_wires [n : 0];
	wire [31:0] c_wires [n : 0];
		
	
	//for(i = 0; i < n; i = i + 1)
	//begin
	//	assign stb_wires[i] = 1;
	//end

	assign a_wires[0] = a_queue[n];
	assign b_wires[0] = b;
	assign stb_wires[0] = in_stb;
	assign stb_wires[n] = out_stb;
	assign ack_wires[n] = out_ack;
	assign ack_wires[0] = in_ack;
	assign b_valid_wires[0] = in_stb;

/*
generate
always @(posedge clk)
begin
	if(~rst) begin
		for(j=0; j<n; j = j+1)
		begin
			a_queue[j+1] <= 32'd0;
		end
	end
	end

endgenerate
*/

generate
// n ta regiser seri vase a ha
	integer k;
	always @(posedge clk) begin
		if(ack_wires[0])
		begin
			if(~rst) a_queue[1] <= 32'd0;
			else a_queue[1] <= a;
			for(k=1; k<n; k = k+1)
			begin
				if(~rst) a_queue[k+1] <= 32'd0;
				else a_queue[k+1] <= a_queue[k];
			end
		end
	end	
endgenerate	
	
genvar i;
generate
	for(i = 0; i < n; i = i + 1)
	begin
		PE #(log_size, i+1) pe
			(
			.a(a_wires[i]),
			.b(b_wires[i]),
			.stb(1'b1),
			.rst(rst),
			.clk(clk),
			.next_PE_ack(ack_wires[i+1]),
			.input_ack(ack_wires[i]),
			.input_b_valid(b_valid_wires[i]),
			.output_b_valid(b_valid_wires[i+1]),
			//input [log_size-1:0] addr,
			//input mem_select,
			.c(c_wires[i]),
			.output_b(b_wires[i+1]), 
			.output_a(a_wires[i+1]),
			.output_stb(stb_wires[i+1])
			);
	end

endgenerate

endmodule

module matrix_multiplier_tb;

	reg [31:0] a;
	reg [31:0] b;
	reg stb;
	reg rst;
	reg clk;
	reg ack;
	wire out_stb;
	wire in_ack;
	
	parameter n = 2;
	
	reg [32:0] a_matrix [n**2 - 1:0];
	reg [32:0] b_matrix [n**2 - 1:0];
	
	
	matrix_multiplier #(1) mm
	(
	.a(a),
	.b(b),
	.in_stb(stb),
	.rst(rst),
	.clk(clk),
	.out_ack(ack),
	.out_stb(out_stb),
	.in_ack(in_ack)
	);
	
	initial
	begin
		   $readmemh("a_matrix.txt", a_matrix, 0, n**2 - 1); //filling memory matrix with file content
		   $readmemh("b_matrix.txt", b_matrix, 0, n**2 - 1); //filling memory matrix with file content
	end
	
	
	initial
	begin
	  clk = 0;
	  forever clk = #(10)  ~clk;
	end


	integer i;

	initial
	begin
		rst <= 1;
		#15 
		rst <= 0;
		
		for(i = 0; i < n**2 ; i = i + 1)
		begin
			#20
			//if (in_ack)
			begin
				a <= a_matrix[i];
				b <= b_matrix[i];
			end
			//else i = i - 1;
		end
		
	end
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
endmodule