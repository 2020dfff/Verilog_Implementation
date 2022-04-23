

`timescale 10ns/1ns
//`include "mealy.v"
`include "moore.v"

module tb_fsm;
	wire p_flag;
	reg p_clk, p_rst, p_s;

	initial begin p_rst = 1'b0; #25 p_rst = 1'b1; end
	initial begin p_clk = 0; forever #10 p_clk = ~p_clk; end

	parameter SIZE = 20;
	reg [SIZE-1 : 0] data = 20'b0101_1011_0110_1011_0100;
	
	initial begin: SERIES
		integer i;
		p_s = 0;
		#30;
		for (i=0;i<SIZE;i=i+1) begin
			p_s = data[SIZE-1];
			data=data<<1;
			#20;
		end
	end

	moore v ( .flag(p_flag), .seq(p_s), .clk(p_clk), .rst(p_rst) );
	//mealy u ( .flag(p_flag), .seq(p_s), .clk(p_clk), .rst(p_rst) );
	
	initial
  begin
  $monitor($time, " rst=%b, flag=%b",  p_rst, p_flag);
  end
endmodule
  