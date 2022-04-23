`timescale 1ns / 1ps

module LCD_Stopwatch( 	   output SF_CE0,	// 当 SF_CE0 = 1 时, 禁用 StrataFlash 存储器, 
				   output LCD_RW,	// 读写控制
								// 0: 写，一般均为此状态，写数据给lcd
								// 1: 读
					
				   output LCD_RS,	// 寄存器选择
								// 0: 指令寄存器 
								// 1: 数据寄存器
					
				   output [3:0] SF_D,	//lcd接口
					
				   output LCD_E,		// 0: lcd不能读写, 1: 可进行读写操作											
					
				   input clock,		// 连接时钟
				   input reset,		// 使用按键sw3做为复位键
					input restart
				  );

	//fenpin
	reg clk_10Hz;
	parameter PULSESCOUNT = 25'd2500000,
	          RESETZERO = 25'd0;

	reg [25:0] counter; // 计数器, 25 bits (1_0111_1101_0111_1000_0100_0000)
	                    // 用于对系统时钟脉冲进行计数, 以产生 1Hz 输出时钟信号
	
    always @(posedge clock) begin //由 clock 信号的上升沿触发
	    if (counter < PULSESCOUNT)
	        counter <= counter + 1'b1;
	    else begin
            clk_10Hz <= ~clk_10Hz;
            counter <= RESETZERO;
		end
	end
	
	//  LCD 初始化&显示配置状态变量，具体见本文档4.5.1节上电初?	
	parameter 		INIT_IDLE		= 4'h1,
				WAITING_READY 	= 4'h2,
				WR_ENABLE_1	= 4'h3,
				WAITING_1		= 4'h4,
				WR_ENABLE_2	= 4'h5,
				WAITING_2		= 4'h6,
				WR_ENABLE_3	= 4'h7,
				WAITING_3		= 4'h8,
				WR_ENABLE_4	= 4'h9,
				WAITING_4		= 4'hA,		
				INIT_DONE		= 4'hB;

	// 保存 LCD 初始化状态变量: 位宽 3 bits
	reg [3:0] init_state;
	reg [3:0]  minute_h, second_h;
	reg [3:0]  minute_l, second_l, msec;
	// 时序控制计数器 750,000 (dec) = 1011_0111_0001_1011_0000(bin) 需要 20 bits
	reg [19:0] cnt_init;
	
	// 初始化状态标志	0: 跏蓟赐瓿?1: 初始化已完成
	reg init_done;		
	parameter		DISPLAY_INIT	= 4'h1,
				FUNCTION_SET	= 4'h2,
				ENTRY_MODE_SET	= 4'h3,
				DISPLAY_ON_OFF	= 4'h4,
				DISPLAY_CLEAR	= 4'h5,
				CLEAR_EXECUTION	= 4'h6,
				IDLE_2SEC 		= 4'h7,
				SET_DD_RAM_ADDR	= 4'h8,
				LCD_LINE_1		= 4'h9,
				SET_NEWLINE	= 4'hA,
				LCD_LINE_2		= 4'hB,
				DISPLAY_DONE     = 4'hC;
	// 保存 LCD 显示配置状态变量: 位宽 3 bits
	reg [3:0] ctrl_state;	
	// 时序控制计数器	82,000 (dec) = 1_0100_0000_0101_0000 (bin) 需要 17 bits
	reg [16:0] cnt_delay;	
	// 控制初始化标志	 1: 启动传输过程	 0: 停止传输?	
	reg init_exec;
	// 复位后, 等待 2 sec, 运性?50 MHz 时钟频率
	// 等待 100,000,000(dec) = 101_1111_0101_1110_0001_0000_0000 (bin) (27 bits) 时钟周期
	reg [26:0] cnt_2sec;

	// 控制传输标志	1: 启动传输过程		0: 停止传输过程
	reg tx_ctrl;
	// 传输序列状态
	parameter 		TX_IDLE		= 8'H01,
				UPPER_SETUP	= 8'H02,
				UPPER_HOLD		= 8'H04,
				ONE_US		= 8'H08,
				LOWER_SETUP	= 8'H10,
				LOWER_HOLD		= 8'H20,
				FORTY_US		= 8'H40;

	// 保存传输序列状态: 位宽 7 bits
	reg [6:0] tx_state;		
	// 传输控制时序计数器		2000 (dec ) = 111_1101_0000 (bin) 需要 11 bits
	reg [10:0] cnt_tx;	
	// 寄存器选择
	reg select;
	// The upper nibble is transferred first, followed by the lower nibble.
	reg [3:0] nibble; 
	reg [3:0] DB_init; 	// 用于初始化
	// Read/Write Enable Pulse, 0: Disabled, 1: Read/Write operation enabled
	reg enable;
	reg en_init;        	// 用于初始化
	reg mux;			// 标志初始化过程，传输命令/数据
					// 0: 初始化
					// 1: 传输命令/数据
	
	// 向 LCD 传输的数据字节: 位宽 8 bits
	reg [7:0] tx_byte;
	// 保存第 1 行显示输出的字符数据
	reg [7:0] tx_Line1;
	// 保存第 2 行显示输出的字符数据
	reg [7:0] tx_Line2;
	// 显示字符计数器
	reg [3:0] cnt_1 = 4'b0;	// For Line 1
	reg [3:0] cnt_2 = 4'b0;	// For Line 2

	// 禁用 Intel strataflash 存储器, 将 Read/Write 控制设置为 Write, 即: LCD 接收数据
	assign SF_CE0 	= 1'b1; 	// Disable intel strataflash
	assign LCD_RW 	= 1'b0;		// Write only 
	assign LCD_RS 	= select;
	assign SF_D 	= ( mux ) ? nibble : DB_init;	
	assign LCD_E 	= ( mux ) ? enable : en_init;
	
	always @(*)
	begin
		case ( ctrl_state )
			DISPLAY_INIT:		mux = 1'b0;	// power on initialization sequence
			FUNCTION_SET,
			ENTRY_MODE_SET,
			DISPLAY_ON_OFF,
			DISPLAY_CLEAR,
			IDLE_2SEC,
			CLEAR_EXECUTION,
			SET_DD_RAM_ADDR,
			LCD_LINE_1,
			SET_NEWLINE,
			LCD_LINE_2:			mux = 1'b1;
			default:				mux = 1'b0;
		endcase
	end
	////////////////////////////////////////////////////////////////////////////////
	
	//reg counter;
	always @(posedge clk_10Hz)
	begin
	if(restart)
	begin
	  //counter <= 1'b0;
	  minute_h <= 1'b0;
	  minute_l <= 1'b0;
	  second_h <= 1'b0;
	  second_l <= 1'b0;
	  msec <= 1'b0;
	end
	else
	begin
	   //if(counter < msec)
		//begin
		 // counter <= counter + 1'b1;
		//end
		//else
		begin
		   //counter <= 1'b0;
			if(msec < 9)
			 msec <= msec + 1'b1;
			else
			begin
			  msec <= 1'b0;
			  if(second_l <9)
			    second_l <= second_l + 1'b1;
			  else
			  begin
			    second_l <= 1'b0;
				 if(second_h < 5)
				   second_h <= second_h +1'b1;
				 else
				 begin
				    second_h <= 1'b0;
					 if(minute_l < 9)
					  minute_l <= minute_l + 1'b1;
                else
                begin
					   minute_l <= 1'b0;
						if(minute_h < 5)
						  minute_h <= minute_h + 1'b1;
						else
						begin
						  minute_h <= 1'b0;
						end
                end					 
				 end
			  end
			end
		end	
	end
	end
	
	
	always @( * ) begin
		case ( ctrl_state )
			FUNCTION_SET:		begin
									tx_byte = 8'b0010_1000;
									select = 1'b0;
								end
			ENTRY_MODE_SET:		begin
									tx_byte = 8'b0000_0110;
									select = 1'b0;
								end
			DISPLAY_ON_OFF:		begin
									tx_byte = 8'b0000_1100;
									select = 1'b0;
								end
			DISPLAY_CLEAR:		begin
									tx_byte = 8'b0000_0001;
									select = 1'b0;
								end
			SET_DD_RAM_ADDR:	begin
									tx_byte = 8'b1000_0000;
									select = 1'b0;
								end
			///////////////////////////////////////////////////
			LCD_LINE_1:			begin
									tx_byte = tx_Line1;
									select = 1'b1;
								end
			SET_NEWLINE:		begin
									tx_byte = 8'b1100_0000;
									select = 1'b0;
								end			
			///////////////////////////////////////////////////
			LCD_LINE_2:			begin
									tx_byte = tx_Line2;
									select = 1'b1;
								end
			
			default: 			begin
									tx_byte = 8'b0;
									select = 1'b0;
								end
		endcase
	end
	
	always @(*)
	begin
		case ( cnt_1 )
		0: tx_Line1 = 8'b0101_0011; //S
      1: tx_Line1 = 8'b0111_0100; //t
      2: tx_Line1 = 8'b0110_1111; //o
      3: tx_Line1 = 8'b0111_0000; //p
      4: tx_Line1 = 8'b0111_0111; //w
      5: tx_Line1 = 8'b0110_0001; //a
      6: tx_Line1 = 8'b0111_0100; //t
      7: tx_Line1 = 8'b0110_0011; //c
      8: tx_Line1 = 8'b0110_1000; //h
		default:tx_Line1 	= 8'b0;				// NONE
		endcase
	end
		
	always @(*)
	begin
		case ( cnt_2 )
      0: tx_Line2 = 8'b0101_0100; //T
      1: tx_Line2 = 8'b0110_1001; //i 
      2: tx_Line2 = 8'b0110_1101; //m
      3: tx_Line2 = 8'b0110_0101; //e
      4: tx_Line2 = 8'b0011_1010; //:
      5: tx_Line2 = conversion(minute_h); //
      6: tx_Line2 = conversion(minute_l); //
      7: tx_Line2 = 8'b0011_1010; //:
      8: tx_Line2 = conversion(second_h); //
	  9: tx_Line2 = conversion(second_l); //
	  10: tx_Line2 = 8'b0011_1010; //:
	  11: tx_Line2 = conversion(msec); //
	  default:tx_Line2 	= 8'b0;				// NONE
	  endcase
	end
	function [7:0]conversion;
	input [3:0] num;
	begin
	case(num)
	4'b0000: conversion = 8'b0011_0000;
	4'b0001: conversion = 8'b0011_0001;
	4'b0010: conversion = 8'b0011_0010;
	4'b0011:	conversion = 8'b0011_0011;
	4'b0100: conversion = 8'b0011_0100;
	4'b0101: conversion = 8'b0011_0101;
	4'b0110: conversion = 8'b0011_0110;
	4'b0111: conversion = 8'b0011_0111;
	4'b1000: conversion = 8'b0011_1000;
	4'b1001: conversion = 8'b0011_1001;
	default: conversion = 8'b0011_0000;
	endcase
	end
	endfunction
//		上电后 LCD 初始化过程
		
	always @( posedge clock )
	begin
		if( reset ) begin
			init_state <= INIT_IDLE;
			
			DB_init <= 4'b0;
			en_init <= 0;
			
			cnt_init <= 0;
			
			init_done <= 0;
		end

		else begin
			case ( init_state )
				// power on initialization sequence
				INIT_IDLE:			begin
										en_init <= 0;
										
										if ( init_exec  )
											init_state <= WAITING_READY;
										else
											init_state <= INIT_IDLE;
									end
				
				WAITING_READY:		begin	
										en_init <= 0;
										
										if ( cnt_init <= 750000 ) begin
											DB_init <= 4'h0;

											cnt_init <= cnt_init + 1;
											
											init_state <= WAITING_READY;
										end
										else begin
											cnt_init <= 0;
											
											init_state <= WR_ENABLE_1;
										end
									end
										
				WR_ENABLE_1:		begin
										DB_init <= 4'h3;			
										
										en_init <= 1'b1;		
										
										if ( cnt_init < 12 ) begin	 
											cnt_init <= cnt_init + 1;
											
											init_state <= WR_ENABLE_1;
										end
										else begin
											cnt_init <= 0;
											
											init_state <= WAITING_1;
										end
									end

				WAITING_1:			begin
										en_init <= 1'b0;			
										
										if ( cnt_init <= 205000 ) begin	 
											
											cnt_init <= cnt_init + 1;
											
											init_state <= WAITING_1;
									end
									else begin
											cnt_init <= 0;
											
											init_state <= WR_ENABLE_2;
										end
									end
				WR_ENABLE_2:		begin
										DB_init <= 4'h3;			
										en_init <= 1'b1;			
										
										if ( cnt_init < 12 ) begin	 
																						
											cnt_init <= cnt_init + 1;
											
											init_state <= WR_ENABLE_2;
									end
									else begin
											cnt_init <= 0;
											
											init_state <= WAITING_2;
										end
									end
									
				WAITING_2:			begin
										en_init <= 1'b0;
											
										if ( cnt_init <= 5000 ) begin	 
											
											cnt_init <= cnt_init + 1;
											
											init_state <= WAITING_2;
										end
										else begin
											cnt_init <= 0;
											
											init_state <= WR_ENABLE_3;
										end
									end
					
				WR_ENABLE_3:		begin	
										DB_init <= 4'h3;			
										en_init <= 1'b1;			
										
										if ( cnt_init < 12 ) begin	 
																						
											cnt_init <= cnt_init + 1;
											
											init_state <= WR_ENABLE_3;
									end
									else begin
											cnt_init <= 0;
											
											init_state <= WAITING_3;
										end
									end

				WAITING_3:			begin
										en_init <= 1'b0;	
										
										if ( cnt_init <= 2000 ) begin	 
											
											cnt_init <= cnt_init + 1;
											
											init_state <= WAITING_3;
									end
									else begin
											cnt_init <= 0;
											
											init_state <= WR_ENABLE_4;
										end
									end

				WR_ENABLE_4:		begin
										DB_init <= 4'h2;		
										en_init <= 1'b1;			
										
										if ( cnt_init < 12 ) begin	 
																						
											cnt_init <= cnt_init + 1;
											
											init_state <= WR_ENABLE_4;
									end
									else begin
											cnt_init <= 0;
											
											init_state <= WAITING_4;
										end
									end

				WAITING_4:			begin	
										en_init <= 1'b0;										
										
										if ( cnt_init <= 2000 ) begin
											cnt_init <= cnt_init + 1;
											
											init_state <= WAITING_4;
										end
										else begin
											DB_init <= 4'h0;		
											cnt_init <= 0;
											
											cnt_init <= 0;
											
											init_done <= 1'b1;
											init_state <= INIT_DONE;
										end
									end

				INIT_DONE:			begin
										init_state <= INIT_DONE;
										
										DB_init <= 4'h0;
										en_init <= 1'b0;
										
										cnt_init <= 0;
										
										init_done <= 1'b1;
									end
				default:			begin
										init_state <= INIT_IDLE;
			
										DB_init <= 4'b0;
										en_init <= 0;
			
										cnt_init <= 0;
			
										init_done <= 0;
									end
			endcase
		end
	end
	
	
	always @( * )
	begin
		case ( ctrl_state )
			DISPLAY_INIT:		tx_ctrl = 1'b0;
			FUNCTION_SET,
			ENTRY_MODE_SET,
			DISPLAY_ON_OFF,
			DISPLAY_CLEAR:		tx_ctrl = 1'b1;
			CLEAR_EXECUTION:	tx_ctrl = 1'b0;
			SET_DD_RAM_ADDR,
			LCD_LINE_1,
			SET_NEWLINE,
			LCD_LINE_2:		tx_ctrl = 1'b1;
			DISPLAY_DONE:		tx_ctrl = 1'b0;
			default:			tx_ctrl = 1'b0;
		endcase
	end		
	

	always @( posedge clock )
	begin
		if( reset ) begin
			ctrl_state <= DISPLAY_INIT;
			
			cnt_delay <= 0;
			cnt_1 <= 0;
			cnt_2 <= 0;
			
			cnt_2sec <= 0;
		end

		else begin
			case ( ctrl_state )
				// power on initialization sequence
				DISPLAY_INIT:		begin	// (0 )等待 15 ms 或更长, LCD 准备显示
										init_exec <= 1;
										
										if ( init_done ) begin
											ctrl_state <= FUNCTION_SET;
											cnt_1 <= 0;
											cnt_2 <= 0;
										end
										else begin
											ctrl_state <= DISPLAY_INIT;
										end
									end

				FUNCTION_SET:		begin
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= FUNCTION_SET;
										end
										else begin
											ctrl_state <= ENTRY_MODE_SET;
										end		
									end
				
				ENTRY_MODE_SET:		begin
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= ENTRY_MODE_SET;
										end
										else begin
											ctrl_state <= DISPLAY_ON_OFF;
										end
									end
				
				DISPLAY_ON_OFF:		begin
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= DISPLAY_ON_OFF;
										end
										else begin
											ctrl_state <= DISPLAY_CLEAR;
										end
									end
									
				DISPLAY_CLEAR:		begin 
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= DISPLAY_CLEAR;
										end
										else begin
											ctrl_state <= CLEAR_EXECUTION;
											
											cnt_delay <= 0;
										end
									end
				
				CLEAR_EXECUTION:	begin 
										if ( cnt_delay <= 82000 ) begin
											ctrl_state <= CLEAR_EXECUTION;
											
											cnt_delay <= cnt_delay + 1;
										end
										else begin
											ctrl_state <= IDLE_2SEC;
											cnt_delay <= 0;
											
											cnt_2sec <= 0;
										end
									end
				
				IDLE_2SEC:			begin 
										if ( cnt_2sec < 27'd100000000 ) begin  
											ctrl_state <= IDLE_2SEC;
											cnt_2sec <= cnt_2sec + 1;
										end
										else begin
											ctrl_state <= SET_DD_RAM_ADDR;
											
											cnt_delay <= 0;
										end										
									end

				SET_DD_RAM_ADDR:	begin   
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= SET_DD_RAM_ADDR;
										end
										else begin
											ctrl_state <= LCD_LINE_1;
											cnt_1 <= 0;
										end
									end

				LCD_LINE_1:			begin
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= LCD_LINE_1;
										end
										else if ( cnt_1 < 8 ) begin
												ctrl_state <= LCD_LINE_1;
												
												cnt_1 <= cnt_1 + 1;
											end
											else begin	
												ctrl_state <= SET_NEWLINE;
												
												cnt_1 <= 0;
											end
									end
													
				SET_NEWLINE:		begin
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= SET_NEWLINE;
										end
										else begin
											ctrl_state <= LCD_LINE_2;
											
											cnt_2 <= 0;
										end
									end	
									
				LCD_LINE_2:			begin
										// Wait 40 us or longer
										if ( cnt_tx <= 2000 ) begin
											ctrl_state <= LCD_LINE_2;
										end
										else if ( cnt_2 < 11 ) begin
												ctrl_state <= LCD_LINE_2;
												
												cnt_2 <= cnt_2 + 1;
											end
											else begin	
												ctrl_state <= SET_NEWLINE;
												
												cnt_2 <= 0;
											end
									end
				
				DISPLAY_DONE:		begin
										ctrl_state <= DISPLAY_DONE;
									end
				default:			begin
										ctrl_state <= DISPLAY_INIT;
			
										cnt_delay <= 0;
										cnt_1 <= 0;
										cnt_2 <= 0;
										
										cnt_2sec <= 0;
									end
			endcase
		end
	end	
	// specified by datasheet, transmit process
		// specified by datasheet, transmit process
	always @( posedge clock )
	begin
		if ( reset ) begin
			enable <= 1'b0;
			nibble <= 4'b0;

			tx_state <= TX_IDLE;
			cnt_tx <= 0;
		end
		else  begin
			case ( tx_state )
				TX_IDLE:			begin
										enable <= 1'b0;
										nibble <= 4'b0;
										cnt_tx <= 0;

										if ( tx_ctrl ) begin
											tx_state <= UPPER_SETUP;
										end
										else begin
											tx_state <= TX_IDLE;
										end
									end
				// Setup time ( time for the outputs to stabilize ) is 40ns, which is 2 clock cycles
				UPPER_SETUP:		begin	
										nibble <= tx_byte[7:4];
										
										if ( cnt_tx < 2 ) begin
											enable <= 1'b0;
											
											tx_state <= UPPER_SETUP;
										
											cnt_tx <= cnt_tx + 1;
										end
										else begin
											enable <= 1'b1;
										
											tx_state <= UPPER_HOLD;
											cnt_tx <= 0;
										end
									end
				UPPER_HOLD:			begin
										nibble <= tx_byte[7:4];
										
										if ( cnt_tx < 12 ) begin
											enable <= 1'b1;
											tx_state <= UPPER_HOLD;
											cnt_tx <= cnt_tx + 1;
										end
										else begin
											enable <= 1'b0;
											tx_state <= ONE_US;
											cnt_tx <= 0;
										end
									end
				ONE_US:				begin
										enable <= 1'b0;
									
										if ( cnt_tx <= 50 ) begin
											tx_state <= ONE_US;
											cnt_tx <= cnt_tx + 1;
										end
										else begin
											tx_state <= LOWER_SETUP;
											cnt_tx <= 0;
										end
									end
				LOWER_SETUP:		begin	
										nibble <= tx_byte[3:0];
										
										if ( cnt_tx < 2 ) begin
											enable <= 1'b0;
										
											tx_state <= LOWER_SETUP;
											cnt_tx <= cnt_tx + 1;
										end
										else begin
											enable <= 1'b1;
											
											tx_state <= LOWER_HOLD;
											cnt_tx <= 0;
										end
									end
								
				// Hold time ( time to assert the LCD_E pin ) is 230ns, which translates to roughly 12 clock cycles
				LOWER_HOLD:			begin
										nibble <= tx_byte[3:0];
										
										if ( cnt_tx < 12 ) begin
											enable <= 1'b1;
											tx_state <= LOWER_HOLD;
											cnt_tx <= cnt_tx + 1;
										end
										else begin
											enable <= 1'b0;
											tx_state <= FORTY_US;
											cnt_tx <= 0;
										end
									end
 
				FORTY_US:			begin
										enable <= 1'b0;
								
										if ( cnt_tx <= 2000 ) begin
											tx_state <= FORTY_US;
											cnt_tx <= cnt_tx + 1;
										end
										else begin
											tx_state <= TX_IDLE;
											cnt_tx <= 0;
										end
									end
				default:			begin
											enable <= 1'b0;
											nibble <= 4'b0;
											
											tx_state <= TX_IDLE;
											cnt_tx <= 0;
									end
			endcase
		end
	end
endmodule

