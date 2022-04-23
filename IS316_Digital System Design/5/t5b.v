
`timescale 10 ns / 1 ns

module comb_Y2(output Y, input A, B, C, D);

assign Y = (~A & B & ~C & ~D)|(~A & B & ~C & D)|(~A & B & C & ~D)|(~A & B & C & D)|(A & ~B & C & D)|(A & B & ~C & ~D)|(A & B & ~C & D);

endmodule
