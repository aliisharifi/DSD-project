`define WAIT 3'b000
`define SWAP 3'b001
`define SHIFT 3'b010
`define ADD 3'b011
`define NORMALIZE 3'b100
`define READY 3'b101
`define exp_part_of_denormalized (expWidth + mantissaWidth)-: expWidth
`define mantissa_part_of_denormalized (mantissaWidth)-: mantissaWidth + 1
`define sign_bit_of_denormalized mantissaWidth + expWidth + 1
`define NAN -1
module adder(a, b, s, clk, start, ready, reset);
	parameter expWidth = 7;
	parameter mantissaWidth = 24;
	input [expWidth + mantissaWidth : 0] a, b;
	output reg [expWidth + mantissaWidth : 0] s;
	input clk, start, reset;
	output reg ready;
	reg [2:0] current_state, next_state;
	reg [expWidth + mantissaWidth + 1 : 0] denormalized_operand1, denormalized_operand2, denormalized_sum;
	reg shift_end_flag, normalize_end_flag;
	always @(posedge clk, negedge reset) begin
		if(!reset) begin
			current_state <= `WAIT;
			denormalized_operand1 <= 0;
			denormalized_operand2<= 0;
			s <= 0;
			ready <= 0;
			shift_end_flag <= 0;
			normalize_end_flag <= 0;
			denormalized_sum <= 0;
		end
		else begin
			case (current_state)
				`WAIT: if(start) begin
					denormalized_operand1 <= denormalized(a);
					denormalized_operand2 <= denormalized(b);
					shift_end_flag <= 0;
					normalize_end_flag <= 0;
				end
				`SWAP: if(!compare(denormalized_operand1, denormalized_operand2)) begin
					denormalized_operand1 <= denormalized_operand2;
					denormalized_operand2 <= denormalized_operand1;
				end
				`SHIFT: begin
					if(denormalized_operand1[`exp_part_of_denormalized] == denormalized_operand2[`exp_part_of_denormalized]) shift_end_flag = 1;
					else begin
						denormalized_operand2[`exp_part_of_denormalized] <= denormalized_operand2[`exp_part_of_denormalized] + 1;
						denormalized_operand2[`mantissa_part_of_denormalized] <= denormalized_operand2[`mantissa_part_of_denormalized] >> 1;
					end
				end
				`ADD: begin
					denormalized_sum[`sign_bit_of_denormalized] <= denormalized_operand1[`sign_bit_of_denormalized];
					denormalized_sum[`exp_part_of_denormalized] <= denormalized_operand1[`exp_part_of_denormalized];
					denormalized_sum[`mantissa_part_of_denormalized] <= (denormalized_operand1[`sign_bit_of_denormalized] == denormalized_operand2[`sign_bit_of_denormalized]) ?
					denormalized_operand1[`mantissa_part_of_denormalized] + denormalized_operand2[`mantissa_part_of_denormalized] :
					denormalized_operand1[`mantissa_part_of_denormalized] - denormalized_operand2[`mantissa_part_of_denormalized];
				end
				`NORMALIZE: begin
					if(denormalized_sum[`mantissa_part_of_denormalized] == 0) begin
						denormalized_sum <= 0;
						normalize_end_flag <= 1;
					end
					if(!denormalized_sum[mantissaWidth] && denormalized_sum[`exp_part_of_denormalized] != 0) begin
						denormalized_sum[`mantissa_part_of_denormalized] <= denormalized_sum[`mantissa_part_of_denormalized] << 1;
						denormalized_sum[`exp_part_of_denormalized] <= denormalized_sum[`exp_part_of_denormalized] - 1;
					end
					else normalize_end_flag <= 1;
				end
				`READY: begin
					s[(expWidth + mantissaWidth)-: expWidth + 1] <= denormalized_sum[(mantissaWidth + expWidth + 1)-: expWidth + 1];
					s[mantissaWidth - 1: 0] <= denormalized_sum[(mantissaWidth - 1)-: mantissaWidth];
					ready <= 1;
				end
				default:  s <= `NAN;
			endcase
			current_state <= next_state;
		end
	end
	
	
	always @(current_state, start, shift_end_flag, normalize_end_flag) begin
		case (current_state)
			`WAIT: if(start) next_state = `SWAP; else next_state = `WAIT;
			`SWAP: next_state = `SHIFT;
			`SHIFT: if(shift_end_flag) next_state = `ADD; else next_state = `SHIFT;
			`ADD: next_state = `NORMALIZE;
			`NORMALIZE: if(normalize_end_flag) next_state = `READY; else next_state = `NORMALIZE;
			`READY: next_state = `WAIT;
			default: next_state = `WAIT;
		endcase
	end
	function automatic [expWidth + mantissaWidth + 1: 0] denormalized(input [mantissaWidth + expWidth : 0] X);
		begin
			denormalized[(expWidth + mantissaWidth + 1)-: 1 + expWidth] = X[(expWidth + mantissaWidth)-: 1 + expWidth];
			denormalized[mantissaWidth] = (X[(mantissaWidth + expWidth - 1)-: expWidth] == 0) ? 0 : 1;
			denormalized[(mantissaWidth - 1)-: mantissaWidth] = X[(mantissaWidth - 1)-: mantissaWidth];
		end
	endfunction
	
	function compare (input [mantissaWidth + expWidth + 1 : 0] X, Y) ;
		begin
			if(X[`exp_part_of_denormalized] > Y[`exp_part_of_denormalized])
				compare = 1;
			else if(X[`exp_part_of_denormalized] == Y[`exp_part_of_denormalized] && X[`mantissa_part_of_denormalized] >= Y[`mantissa_part_of_denormalized])
				compare = 1;
			else
				compare = 0;
		end
	endfunction
endmodule
