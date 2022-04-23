
`timescale 10 ns / 1 ns
`include "t15.v"

module tb_seq_detect();

wire flag;
reg clk;
reg rst_n;
integer i;
reg [31:0] buffer = 32'b0110_1101_1011_0100_1011_0010_0101_0101;
reg din;

initial begin
	clk = 1'b0;
	forever
		#5 clk = ~clk;
end

initial begin
	rst_n = 1'b1;
	#2 rst_n = 1'b0;
	#10 rst_n = 1'b1;
end

initial 
begin
  din=0;
  #8 for(i=0;i<31;i=i+1)
  begin
	#4 din = buffer[31];
	buffer = buffer << 1;
end
end

seq_detect dectect(.flag(flag), .din(din), .clk(clk), .rst_n(rst_n));

initial
$monitor($time, "\tclk= %b, rst_n = %b, flag = %b",clk, rst_n, flag);
//$monitor($time, "\taddr = %d, wr = %b, rd = %b, din = %8b, dout = %8b", addr, wr, rd, din, dout);

endmodule
