
`timescale 10ns / 1ns
module comb_str(output y,input sel, A, B, C, D);

wire in0, in1, y0, y1, sel_bar;
nand nand0(in0,A,B);
nand nand1(in1,C,D);

not notsel(sel_bar,sel);
and and0(y0,sel_bar,in0);
and and1(y1,sel,in1);
or result(y,y0,y1);

endmodule