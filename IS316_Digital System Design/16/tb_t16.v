
`timescale 10ns / 1ns
//`include "t16_moore.v"
`include "mealy.v"

module top();
  wire flag;
  reg seq,clk,rst;
  reg [19:0] data;
  
 mealy mymealy(.flag(flag), .seq(seq), .clk(clk), .rst(rst));
 // moore mymoore(.flag(flag), .din(din), .clk(clk), .rst(rst));
  
  initial
  begin
    clk = 0;
    rst = 0;
    forever
		#5 clk = ~clk;
end

initial 
begin
  data = 20'b0101_1011_0110_1011_0100;
  seq = 0;
  repeat(20)
  begin
    #10 seq = data & 1;
    data = data >> 1;
  end
  #10 $stop;
end

initial
begin
$monitor($time, "seq=%b, rst=%b, flag=%b", seq, rst, flag);
end
endmodule
  
  