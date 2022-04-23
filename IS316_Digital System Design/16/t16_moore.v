
`timescale 10 ns / 1 ns

module moore(
	output reg flag,
	input din, clk, rst
);

reg [3:0] state;
reg [3:0] next;

parameter A = 0;
parameter B = 1;
parameter C = 2;
parameter D = 3;
parameter E = 4;
parameter F = 5;
parameter G = 6;
parameter H = 7;
parameter I = 8;


 always @(posedge clk or posedge rst)
  begin 
    if(rst)
      state <= A;
    else
      state<=next;
  end
  
always @(*) 
begin
	 	case (state)
			A: next <= din ? A : B;
			B: next <= din ? C : B;
			C: next <= din ? A : D;
		  D: next <= din ? E : B;
			E: next <= din ? A : F;
			F: next <= din ? G : B;
			G: next <= din ? A : H;
			H: next <= din ? I : B;
			I: next <= din ? A : H;
			default: next = A;
		endcase
end


always @(posedge clk or posedge rst)
begin
  if(rst)
    flag <= 0;
  else if(state == I)
    flag<=1;
  else
    flag<=0;
  end
  
endmodule
