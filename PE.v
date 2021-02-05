module PE #(parameter log_size, parameter index)
(
	input [31:0] a,
	input [31:0] b,
	input stb,
	input rst,
	input clk,
	input next_PE_ack,
	output input_ack,
	input input_b_valid,
	output output_b_valid,
	input [log_size-1:0] addr,
	input mem_select,
	output [31:0] c,
	output [31:0] output_b, 
	output [31:0] output_a,
	output output_stb
);

	reg [31:0] a_buffer;
	reg [31:0] bu_buffer, bm_buffer, bl_buffer;
	reg [31:0] bc;
	reg [31:0] mem [log_size-1:0];
	reg [log_size:0] counter1, counter2;

	wire adder_stb;
	wire [31:0] adder_result;
	wire mul_stb;
	wire [31:0] mul_result;
	reg counter1_rst, counter2_rst, shift, load_bc, rst_m, ack_m, rst_a, ack_a, add_nzero, r_nw, sel1, sel2, sel3, m_s, a_enb, b_enb, count1_enb, count2_enb;
	wire c1_i = counter1 >= index;
	wire bc_sel = counter2 != 0;
	wire [log_size-1:0] controll_addr;
	parameter state1 = 4'd1, state2 = 4'd2, state3 = 4'd3, state4 = 4'd4, state5 = 4'd5, state6 = 4'd6, state7 = 4'd7, rst_mem = 4'd0, finish = 4'd8;
	reg [31:0] mbr;
	reg [3:0] state;
	reg r_input_ack, r_output_stb, r_input_b_valid;
	
	
	//CU
	always @(posedge clk) begin
		if(rst) begin
			r_input_b_valid <= 0;
			counter1_rst <= 1;
			counter2_rst <= 0;
			r_output_stb <= 0;
			r_input_ack <= 0;
			shift <= 0;
			load_bc <= 0;
			rst_m <= 0;
			ack_m <= 0;
			rst_a <= 0;
			ack_a <= 0;
			add_nzero <= 0;
			r_nw <= 0;
			sel1 <= 0;
			sel2 <= 0;
			sel3 <= 0;
			m_s <= 0;
			a_enb <= 0;
			b_enb <= 0;
			count1_enb <= 0;
			count2_enb <= 0;
			
			state <= rst_mem;
		end
		case(state)
			rst_mem:
			begin
				counter1_rst <= 0;
				sel1 <= 1;
				sel2 <= 1;
				sel3 <= 1;
				r_nw <= 0;
				m_s <= 1;
				add_nzero <= 0;
				count1_enb <= 1;
				state <= rst_mem;
				// check it !
				if(&counter1[log_size-1:0]) begin
					state <= state1;
					count1_enb <= 0;
				end
			end
			
			state1:
			begin
				counter1_rst <= 1;
				counter2_rst <= 1;
				
				
				sel1 <= 0;
				sel2 <= 0;
				sel3 <= 0;
				r_nw <= 0;
				m_s <= 0;
				
				state <= state2;
			end
			
			state2:
			begin
				count1_enb <= 0;
				count2_enb <= 0;
				counter1_rst <= 0;
				counter2_rst <= 0;
				
				state <= state2;
				
				r_input_ack <= 1;
				if(stb && !next_PE_ack) begin
					a_enb <= 1;
					b_enb <= 1;
					r_input_b_valid <= input_b_valid;
					r_input_ack <= 0;
					state <= state3;
				end
			end
			
			state3:
			begin
				shift <= counter1 == index;
				state <= state4;
			end
			
			state4:
			begin
				shift <= 0;
				load_bc <= 1;
				rst_m <= 1;
				state <= state5;
			end
			
			state5:
			begin
				load_bc <= 0;
				rst_m <= 0;
				
				sel1 <= 1;
				sel2 <= 1;
				sel3 <= 1;
				r_nw <= 1;
				m_s <= 1;
				
				state <= state5;
				if(mul_stb) begin
					state <= state6;
					rst_a <= 1;
				end
			end
			
			state6:
			begin
				rst_a <= 0;
				
				state <= state6;
				if(adder_stb) begin
					sel1 <= 1;
					sel2 <= 1;
					sel3 <= 1;
					r_nw <= 0;
					m_s <= 1;
					add_nzero <= 1;
					ack_a <= 1;
					ack_m <= 1;
					state <= state7;
				end
			end
			
			state7:
			begin
				sel1 <= 0;
				sel2 <= 0;
				sel3 <= 0;
				r_nw <= 0;
				m_s <= 0;
				add_nzero <= 0;
				
				ack_a <= 0;
				ack_m <= 0;
				if(r_input_b_valid)
					count1_enb <= 1;
				if(counter1[log_size]) begin
					count2_enb <= 1;
				end
				if(counter2[log_size]) begin
					state <= finish;
				end
				else begin
					state <= state2;
				end
			end
			
			finish:
			begin
				count1_enb <= 0;
				count2_enb <= 0;
				r_output_stb <= 1;
				state <= finish;
			end
			
		endcase
	end
	
	
	wire mem_sel = sel3 ? m_s : mem_select;
	wire mem_addr = sel2 ? controll_addr : addr;
	wire mem_r_nw = sel1 ? r_nw : 1;
	
	
	//datapath
	always @(posedge clk) begin
		if(load_bc)
			bc <= bc_sel ? (c1_i ? bl_buffer : bm_buffer) : 0;
		if(count1_enb)
			counter1 <= counter1[log_size] ? 1 : counter1 + 1;
		if(count2_enb)
			counter2 <= counter2 + 1;
		if(a_enb)
			a_buffer <= a;
		if(b_enb)
			bu_buffer <= b;
		if(counter1_rst)
			counter1 <= 1;
		if(counter2_rst)
			counter2 <= 0;
		if(shift) begin
			bl_buffer <= bm_buffer;
			bm_buffer <= bu_buffer;
		end
		if(mem_sel) begin
			if(mem_r_nw) begin
				mbr <= mem[mem_addr];
			end
			else begin
				mem[mem_addr] <= add_nzero ? adder_result : 0;
			end
		end
	end
	
	assign output_b = bu_buffer;
	assign output_a = a_buffer;
	assign output_b_valid = r_input_b_valid;
	assign controll_addr = counter1[log_size-1:0];
	assign input_ack = r_input_ack;
	assign c = mbr;
	assign output_stb = r_output_stb;
	
	adder ADDER(
        .input_a(mul_result),
        .input_b(mbr),
        .input_a_stb(1'b1),
        .input_b_stb(1'b1),
        .output_z_ack(ack_a),
        .clk(clk),
        .rst(rst_a),
        .output_z(adder_result),
        .output_z_stb(adder_stb)
        );
	multiplier MULTIPLIER(
        .input_a(a_buffer),
        .input_b(bc),
        .input_a_stb(1'b1),
        .input_b_stb(1'b1),
        .output_z_ack(ack_m),
        .clk(clk),
        .rst(rst_m),
        .output_z(mul_result),
        .output_z_stb(mul_stb));
	
endmodule
