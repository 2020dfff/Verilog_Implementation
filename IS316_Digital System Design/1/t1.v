`timescale 10 ns / 1 ns

module wavegen
  ( );
  reg out;
  initial
  begin
	out = 1'b0;
	#2 out = 1'b1;
	#1 out = 1'b0;
	#9 out = 1'b1;
	#10 out = 1'b0;
	#2 out = 1'b1;
	#3 out = 1'b0;
	#5 out = 1'b1;
end

initial
begin
	$monitor($time, "out = %b", out);
end
endmodule
