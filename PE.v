module #(parameter log_size = 8, parameter index = 0) PE(
	input [31:0] input_a,
	input input_a_stb,
	output input_a_ack,
	input [31:0] input_b,
	input input_b_stb,
	output input_b_ack,
	input clk, 
	input rst,
	output [31:0] output_a,
	output output_a_stb,
	input output_a_ack;
	output [31:0] output_b,
	output output_b_stb,
	input output_b_ack;
	input [log_size-1:0] address,
	output [31:0] output_c,
	input shift
);
	reg m_rest;
	wire [31:0] m_output_z;
	wire m_output_z_stb, m_output_z_ack;

	multiplier m(
        .input_a(BA),
        .input_b(zero ? 0 : BL),
        .input_a_stb(1),
        .input_b_stb(1),
        .output_z_ack(m_output_z_ack),
        .clk(clk),
        .rst(m_rest),
        .output_z(m_output_z),
        .output_z_stb(m_output_z_stb)
	);
	
	
	reg a_output_z_ack;
	reg a_reset;
	wire [31:0] a_output_z;
	wire a_output_z_stb;
	adder a (
        .input_a(m_output_z),
        .input_b(valid_data[counter] ? MEM[counter] : 0),
        .input_a_stb(m_output_z_stb),
        .input_b_stb(1),
        .output_z_ack(a_output_z_ack),
        .clk(clk),
        .rst(a_reset),
        .output_z(a_output_z),
        .output_z_stb(a_output_z_stb),
		.input_a_ack(m_output_z_ack)
	);

	reg [31:0] BU, BM, BL;
	reg [31:0] BA;
	reg [31:0] MEM [2**log_size-1:0];
	reg [log_size - 1:0] counter;
	reg [2**log_size-1:0] valid_data ;
	reg BU_flag, BM_flag, BL_flag;
	reg zero;
	reg [31:0] mem_output;
	
	reg [] state;
	
	reg s_input_a_ack;
	reg s_input_b_ack;
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			counter <= 0;
			valid_data <= 0;
			state <= get_a;
			BU_flag <= 0;
			BM_flag <= 0;
			BL_flag <= 0;
			m_rest <= 1;
			a_reset <= 1;
			valid_data <= 0;
		end
		case(state)
			get_a:
			begin
				s_input_b_ack <= 1:
				if(s_input_b_ack && input_b_stb)
				begin
					BA <= input_a;
					s_input_a_ack <= 0;
					state <= get_b;
				end
				a_output_z_ack  <= 0;
			end
			get_b:
			begin
				s_input_b_ack <= 1:
				if(s_input_b_ack && input_b_stb)
				begin
					BU <= input_b;
					BU_flag <= 1;
					if(shift)
					begin
						BL <= BM;
						BM <= BU;
						BL_flag <= BM_flag;
						BM_flag <= BU_flag;
					end
					s_input_b_ack <= 0;
					state <= reset_m;
				end
			end
			reset_m:
			begin
				m_rest <= 1;
				state <= reset_m;
				if(m_rest)
				begin
					m_rest <= 0;
					state <= wait_m;
				end
			end
			
			wait_m:
			begin
				if(m_output_z_stb)
				begin
					state <= reset_a;
				end
				else begin
					zero <= BL_flag ? 0 : 1;
					state <= wait_m;
				end
			end
			
			reset_a:
			begin
				a_reset <= 1;
				state <= reset_a;
				if(a_reset)
				begin
					a_reset <= 0;
					state <= wait_a;
				end
			end
			wait_a:
			begin
				state <= wait_a;
				if(a_output_z_stb)
				begin
					state <= write_mem;
				end
			end
			write_mem:
			begin
				a_output_z_ack <= 1;
				MEM[counter] <= a_output_z;
				counter <= counter + 1;
				state <= get_a;
			end
		endcase
		mem_output <= MEM[address]
	end
	assing output_c = mem_output;
	assing input_a_ack = s_input_a_ack;
	assing input_b_ack = s_input_b_ack;
endmodule