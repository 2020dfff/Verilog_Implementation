`timescale 10ns / 1ns
`include "t4_structure.v"
`include "t4_dataflow.v"
`include "t4_behavior.v"
`include "t4_prim.v"
module testbench_comb;

reg A, B, C, D;
wire str,dataflow,behavior,prim;
comb_str a(str,A,B,C,D);
comb_dataflow b(dataflow,A,B,C,D);
comb_behavior c(behavior,A,B,C,D);
comb_prim d(prim,A,B,C,D);

initial fork
{A,B,C,D}=4'b0;
forever #1 A=~A;
forever #2 B=~B;
forever #4 C=~C;
forever #8 D=~D;

join

initial begin
	$monitor("At time = %0t, A=%1b, B=%1b, C=%1b,D=%1b, str=%1b, dataflow=%1b, behavior=%1b, prim=%1b",$time, A,B,C,D,str,dataflow,behavior,prim);
end
endmodule