
`timescale 1ns/1ps;
`include "counter.v"

module tb_counter;

// Inputs
reg clk, SW3, SW0;

// Outputs
wire [7:0] LEDOut;


initial begin SW3 = 1'b0; #100 SW3 = 1'b1; end
//initial begin SW0 = 0; forever #100 SW0 = ~SW0; end


initial begin clk = 0; forever #1 clk=~clk; end


initial begin
  SW0 = 1;
  #500 SW0 = ~SW0;
end

eight_bit_counter uut(
.SW3(SW3), 
.SW0(SW0),
.clk(clk),
.LEDOut(LEDOut)
);

initial
#30000 $stop;

initial
$monitor("time=%d,ledout=%b",$time,LEDOut);
      
endmodule

