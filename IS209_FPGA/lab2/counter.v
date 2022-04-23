
`timescale 1ns/1ps;
//`include "clock_div.v"

module eight_bit_counter(
  input SW3, // rst
  input SW0, // enable
  input clk,
  output reg [7:0] LEDOut
);


//reg clk_10=1'b0;
reg [3:0] one_ten = 4'b0000;//100ms=1s
//reg[21:0]k;


//creating new clock
//always @(posedge clk)
//begin
//if (k>=2500000) //è®¡æ¶
//begin
//clk_10<=~clk_10; //状态转换，从高电平跳到低电平，或从低电平跳到高电平
//k<=0;
//end
//else
//k<=k+1;
//end


always @(posedge clk or negedge SW3)
  begin
    
    //SW3 == 0, stop
    if(!SW3) begin
        //initial parameter
	      LEDOut <= 8'b0;
 	      //one_ten <= 1'd0;
	   end
	   
    //SW3 == 1, run
    else begin
      
        //SW0 == 0
        if(!SW0) begin
                  if (one_ten < 4'b1001) begin one_ten <= one_ten+4'b0001; end
                  else begin
                    one_ten <= 4'b0000;
                      if(LEDOut>=8'b0111_1111) begin LEDOut <= 8'b0; end
                      else begin LEDOut <= LEDOut+8'b0000_0001; end
                  end
                 end
                 
        //SW0 == 1
        else begin
                if (LEDOut [3:0] < 4'b1001) begin LEDOut [3:0] <= LEDOut [3:0] +4'b0001; end
                else begin LEDOut [3:0] <= 4'b0000; end
                  
                if(one_ten < 4'b1001) begin one_ten <= one_ten+4'b0001; end
                else begin
                    one_ten <=4'b0000;
                      if(LEDOut [7:4] >= 4'b1001) begin LEDOut [7:4] <= 4'b0000; end
                      else begin LEDOut [7:4] <= LEDOut [7:4] + 4'b0001; end
                        
                    end
                end
          end
  end
  
endmodule
        
                    
          
                

