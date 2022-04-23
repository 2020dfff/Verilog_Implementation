
`timescale 10 ns / 1 ns

module seq_detect(
	output flag,
	input din,
	input clk,
	input rst_n
);

reg [8:0] current_state;
reg [8:0] next_state;

parameter idle = 9'b000000001;
parameter S1 = 9'b000000010;
parameter S3 = 9'b000000100;
parameter S5 = 9'b000001000;
parameter S7 = 9'b000010000;
parameter S0 = 9'b000100000;
parameter S2 = 9'b001000000;
parameter S4 = 9'b010000000;
parameter S6 = 9'b100000000;

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)
		current_state <= idle;
	else
		current_state <= next_state;
end

always @(*) 
begin
	case (current_state)
		idle: next_state = din ? S1 : S0;
		S1: next_state = din ? S3 : S0;
		S3: next_state = din ? S3 : S5;
		S5: next_state = din ? S7 : S0;
		S7: next_state = din ? S4 : S0;
		S0: next_state = din ? S2 : S0;
		S2: next_state = din ? S4 : S0;
		S4: next_state = din ? S3 : S6;
		S6: next_state = din ? S7 : S0;
		default: next_state =  idle;
	endcase
end

assign flag = ((current_state == S7)|(current_state == S6))? 1'b1 : 1'b0;

endmodule
