
`timescale 10ns/1ns

module mealy(output reg flag, input din, clk, rst);
  reg[2:0] current;
  reg[2:0] next;
  
  parameter A=0;
  parameter B=1;
  parameter C=2;
  parameter D=3;
  parameter E=4; 
  parameter F=5;
  parameter G=6;
  parameter H=7;
  
  always @(posedge clk or posedge rst)
  begin 
    if(rst)
      current<=A;
    else
      current<=next;
  end
  
  always @(*)
  begin
  case (current)
  A: next = din ? A : B;
  B: next = din ? C : B;  
  C: next = din ? A : D;  
  D: next = din ? E : B;  
  E: next = din ? A : F;  
  F: next = din ? G : B;  
  G: next = din ? A : H;  
  H: next = din ? G : B;  
  default : next = A;
endcase
end

always @(posedge clk or posedge rst)
begin
  if(rst)
    flag <=0;
  else if(current == H && din==1)
    flag<=1;
  else
    flag<=0;
end
  
endmodule

    