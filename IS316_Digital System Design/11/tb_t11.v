
`timescale 10 ns / 1 ns
`include "t11.v"

module tb_counter8b_updown();

reg clk;
reg rst;
reg dir;
wire [7:0] count;

counter8b_updown counter(.count(count), .clk(clk), .reset(rst), .dir(dir));

initial 
begin
	clk = 1'b0;
	forever
		#2 clk = ~clk;
end

initial
begin
  rst = 1;
  #10 rst = 0;
end

initial 
begin
	dir = 1'b0;
	#30 dir = 1;
	#70 dir = 0;
	#30 dir = 1;
	#50 dir = 0;
	#20 dir = 1;
	#50 $stop;
end


initial
	$monitor($time, "\tcount = %8b\t%d", count, count);

endmodule
