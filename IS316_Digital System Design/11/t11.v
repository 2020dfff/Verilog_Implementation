
`timescale 10 ns / 1 ns

module counter8b_updown(output reg [7:0] count, input clk, reset, dir);

always @(posedge clk or negedge reset) 
begin
  if(reset)
		count <= 4'b0;
	else if (dir)
			count <= count + 1;
	else
			count <= count - 1;
	end

endmodule
