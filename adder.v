`timescale 1ns/1ps
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
module adder #(parameter expWidth = 7, mantissaWidth = 24)(a, b, s, clk, start, ready, reset);
	input [expWidth + mantissaWidth : 0] a, b;
	output reg [expWidth + mantissaWidth : 0] s;
	input clk, start, reset;
	output reg ready;
	reg [2:0] state;
	reg [expWidth + mantissaWidth + 1 : 0] denormalized_operand1, denormalized_operand2, denormalized_sum;
	always @(posedge clk, negedge reset) begin
		if(!reset) begin
			state <= `WAIT;
			denormalized_operand1 <= 0;
			denormalized_operand2<= 0;
			s <= 0;
			ready <= 0;
			denormalized_sum <= 0;
		end
		else begin
			case (state)
				`WAIT: begin
					if(start) begin
						denormalized_operand1 <= denormalized(a);
						denormalized_operand2 <= denormalized(b);
						state <= `SWAP;
					end
					else state <= `WAIT;
				end
				`SWAP: begin 
					if(!compare(denormalized_operand1, denormalized_operand2)) 
					begin
						denormalized_operand1 <= denormalized_operand2;
						denormalized_operand2 <= denormalized_operand1;
					end
					state <= `SHIFT;
				end
				`SHIFT: begin
					if(denormalized_operand1[`exp_part_of_denormalized] == denormalized_operand2[`exp_part_of_denormalized]) state = `ADD;
					else begin
						denormalized_operand2[`exp_part_of_denormalized] <= denormalized_operand2[`exp_part_of_denormalized] + 1;
						denormalized_operand2[`mantissa_part_of_denormalized] <= denormalized_operand2[`mantissa_part_of_denormalized] >> 1;
						state <= `SHIFT;
					end
				end
				`ADD: begin
					denormalized_sum[`sign_bit_of_denormalized] <= denormalized_operand1[`sign_bit_of_denormalized];
					denormalized_sum[`exp_part_of_denormalized] <= denormalized_operand1[`exp_part_of_denormalized];
					denormalized_sum[`mantissa_part_of_denormalized] <= (denormalized_operand1[`sign_bit_of_denormalized] == denormalized_operand2[`sign_bit_of_denormalized]) ?
					denormalized_operand1[`mantissa_part_of_denormalized] + denormalized_operand2[`mantissa_part_of_denormalized] :
					denormalized_operand1[`mantissa_part_of_denormalized] - denormalized_operand2[`mantissa_part_of_denormalized];
					state <= `NORMALIZE;
				end
				`NORMALIZE: begin
					if(denormalized_sum[`mantissa_part_of_denormalized] == 0) begin
						denormalized_sum <= 0;
						state <= `READY;
					end
					if(!denormalized_sum[mantissaWidth] && denormalized_sum[`exp_part_of_denormalized] != 0) begin
						denormalized_sum[`mantissa_part_of_denormalized] <= denormalized_sum[`mantissa_part_of_denormalized] << 1;
						denormalized_sum[`exp_part_of_denormalized] <= denormalized_sum[`exp_part_of_denormalized] - 1;
						state <= `NORMALIZE;
					end
					else state <= `READY;
				end
				`READY: begin
					s[(expWidth + mantissaWidth)-: expWidth + 1] <= denormalized_sum[(mantissaWidth + expWidth + 1)-: expWidth + 1];
					s[mantissaWidth - 1: 0] <= denormalized_sum[(mantissaWidth - 1)-: mantissaWidth];
					ready <= 1;
					state <= `WAIT;
				end
				default:  s <= `NAN;
			endcase
		end
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
