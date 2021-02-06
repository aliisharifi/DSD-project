module matrix_multiplier #(parameter log_size) 
(
	input [31:0] a,
	input [31:0] b,
	input in_stb,
	input rst,
	input clk,
	input out_ack,
	output out_stb,
	output in_ack,
	input [log_size - 1 : 0] row,
	input [log_size - 1 : 0] column,
	output [31:0] out_number,
	input output_select
);


	parameter n = 2 ** log_size;
 
	reg [31:0] a_queue [n : 0];
	
	///////////
	wire [31:0] a_wires [n : 0];
	wire [31:0] b_wires [n : 0];
	wire [n : 1] stb_wires;
	wire ack_wires [n : 0];
	wire b_valid_wires [n : 0];
	wire [31:0] c_wires [n-1 : 0];
		
	assign a_wires[0] = a_queue[n];
	assign b_wires[0] = b;
	assign ack_wires[n] = out_ack;
	assign ack_wires[0] = in_ack;
	assign b_valid_wires[0] = in_stb;
	assign out_stb = &stb_wires;
	assign out_number = c_wires[column];

generate
// n ta regiser seri vase a ha
	integer k;
	always @(posedge clk) begin
		if(ack_wires[0])
		begin
			if(rst) a_queue[0] <= 32'd0;
			else a_queue[0] <= a;
			for(k=0; k<n; k = k+1)
			begin
				if(rst) a_queue[k+1] <= 32'd0;
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
			.addr(row),
			.mem_select(output_select),
			.c(c_wires[i]),
			.output_b(b_wires[i+1]), 
			.output_a(a_wires[i+1]),
			.output_stb(stb_wires[i+1])
			);
	end

endgenerate

endmodule

module matrix_multiplier_tb;

	parameter n = 4;
	parameter log_size = 2;

	reg [31:0] a;
	reg [31:0] b;
	reg stb;
	reg rst;
	reg clk;
	reg ack;
	wire out_stb;
	wire in_ack;
	reg [log_size - 1 : 0] row;
	reg [log_size - 1 : 0] column;
	wire [31:0] out_number;
	reg output_select;
	
	
	
	reg [32:0] a_matrix [n**2 - 1:0];
	reg [32:0] b_matrix [n**2 - 1:0];
	
	
	matrix_multiplier #(log_size) mm
	(
	.a(a),
	.b(b),
	.in_stb(stb),
	.rst(rst),
	.clk(clk),
	.out_ack(ack),
	.out_stb(out_stb),
	.in_ack(in_ack),
	.row(row),
	.column(column),
	.out_number(out_number),
	.output_select(output_select)
	);
	
	initial
	begin
		   $readmemh("sample_inputs/a_matrix_1.txt", a_matrix, 0, n**2 - 1); //filling memory matrix with file content
		   $readmemh("sample_inputs/b_matrix_1.txt", b_matrix, 0, n**2 - 1); //filling memory matrix with file content
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
		#50 
		rst <= 0;
		stb <= 1;
		for(i = 0; i < n**2 ; i = i + 1)
		begin
			#40
			//if (in_ack)
			begin
				a <= a_matrix[i];
				b <= b_matrix[i];
			end
			//else i = i - 1;
		end
		
	end
	
	integer j;
	integer k;
	integer fout;
	
	initial
	begin
		fout = $fopen("output.txt", "w");
		//wait (out_stb);
		#2000
		for(j = 0; j < n; j = j + 1)
		begin
			row <= j[log_size - 1 : 0] ;
			for(k = 0; k < n; k = k + 1)
			begin
				column <= k[log_size - 1 : 0];
				#40
				$fdisplay(fout, "%8h", out_number);
			end
		end
		
		$fclose(fout);
	end

	
	
	
	
	
endmodule