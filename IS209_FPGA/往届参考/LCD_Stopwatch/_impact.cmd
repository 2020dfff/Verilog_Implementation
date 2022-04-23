setMode -bs
setMode -bs
setCable -port auto
Identify 
identifyMPM 
assignFile -p 1 -file "C:/FPGA/LCD_Stopwatch/LCD_Stopwatch/lcd_stopwatch.bit"
ReadIdcode -p 1 
Program -p 1 
setMode -bs
deleteDevice -position 3
deleteDevice -position 2
deleteDevice -position 1
setMode -bs
setMode -bs
setCable -port auto
Identify 
identifyMPM 
assignFile -p 1 -file "C:/FPGA/LCD_Display/LCD_Display/lcd_display.bit"
Program -p 1 
setMode -bs
deleteDevice -position 3
deleteDevice -position 2
deleteDevice -position 1
setMode -bs
setMode -bs
setCable -port auto
setCable -port auto
setCable -port auto
Identify 
identifyMPM 
assignFile -p 1 -file "C:/FPGA/LCD_Stopwatch/LCD_Stopwatch/lcd_stopwatch.bit"
Program -p 1 
assignFile -p 1 -file "C:/FPGA/LCD_Stopwatch/LCD_Stopwatch/lcd_stopwatch.bit"
Program -p 1 
assignFile -p 1 -file "C:/FPGA/LCD_Stopwatch/LCD_Stopwatch/lcd_stopwatch.bit"
Program -p 1 
assignFile -p 1 -file "C:/FPGA/LCD_Stopwatch/LCD_Stopwatch/lcd_stopwatch.bit"
setCable -port auto
Program -p 1 
Program -p 1 
assignFile -p 1 -file "C:/FPGA/LCD_Stopwatch/LCD_Stopwatch/lcd_stopwatch.bit"
Program -p 1 
setMode -bs
deleteDevice -position 1
deleteDevice -position 1
deleteDevice -position 1
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
