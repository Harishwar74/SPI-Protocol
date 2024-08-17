`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2023 15:58:17
// Design Name: 
// Module Name: spi_testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module SPI_loopback_tb();

parameter	CLK_FREQUENCE	= 5_000_000		,
			SPI_FREQUENCE	= 5_000_000			,
			DATA_WIDTH		= 7					,
			DATA_WIDTH_UE =4,
			CPOL			= 0					,
			CPHA			= 0					;

reg							clk			;
reg							rst_n		;
reg		[DATA_WIDTH_UE-1:0]	data_m_in	;
reg		[DATA_WIDTH_UE-1:0]	data_s_in	;
reg							start_m		;
wire						finish_m	;
wire	[DATA_WIDTH-1:0]	data_m_out	;
wire	[DATA_WIDTH-1:0]	data_s_out	;
wire						data_valid_s;
wire em,es;
//the clk generation
initial begin
	clk = 1;
	forever #1 clk = ~clk;
end
//the rst_n generation
initial begin
	rst_n = 1'b0;
	#22 rst_n = 1'b1;
end
//the main block
initial fork
	data_m_in_generate;
	data_s_in_generate;
	start_change;
join
//to generate data_m_in
task data_m_in_generate;
begin
	data_m_in = 'd0;
	@(posedge rst_n)
	data_m_in <= 8'b1011;
	@(posedge finish_m)
	data_m_in <= 8'b0100;
end
endtask
//to generate data_s_in
task data_s_in_generate;
begin
	data_s_in = 'd0;
	@(posedge rst_n)
	data_s_in <= $random;
	@(posedge finish_m)
	data_s_in <= $random;
	@(negedge data_valid_s)
	;
	@(negedge data_valid_s)
	#20 $finish;
end
endtask
//to generate the start signal
task start_change;
begin
	start_m = 1'b0;
	@(posedge rst_n)
	#10 start_m <= 1'b1;
	#10 start_m = 1'b0;
	@(negedge finish_m)
	#10 start_m = 1'b1;
	#10 start_m = 1'b0;
end
endtask
//to generate uart_frame_tx_tb.vcd
initial begin
	$dumpfile("SPI_loopback_tb.vcd");
	$dumpvars();
end
//Debug information
reg	data_valid_1;
reg data_valid_2;
always @(posedge clk or negedge rst_n) begin
	data_valid_1 <= data_valid_s;
	data_valid_2 <= data_valid_1;
end

assign data_valid_pos = ~data_valid_2 & data_valid_1;

always @(posedge clk) begin
	if (data_valid_pos)
		if (data_s_out == data_m_in)
			$display("PASS! data_s_out = %h, data_m_in = %h", data_s_out, data_m_in);
		else
			$display("FAIL! data_s_out = %h, data_m_in = %h", data_s_out, data_m_in);
end

always @(posedge clk) begin
	if (data_valid_pos)
		if (data_m_out == data_s_in)
			$display("PASS! data_m_out = %h, data_s_in = %h", data_m_out, data_s_in);
		else
			$display("FAIL! data_m_out = %h, data_s_in = %h", data_m_out, data_s_in);
end
//DUT
SPI_loopback 
#(
	.CLK_FREQUENCE (CLK_FREQUENCE ),
	.SPI_FREQUENCE (SPI_FREQUENCE ),
	.DATA_WIDTH_UE (DATA_WIDTH_UE),
	.DATA_WIDTH    (DATA_WIDTH    ),
	.CPOL          (CPOL          ),
	.CPHA          (CPHA          )
)
u_SPI_loopback(
	.clk        (clk        ),
	.rst_n      (rst_n      ),
	.data_m_in  (data_m_in  ),
	.data_s_in  (data_s_in  ),
	.start_m    (start_m    ),
	.finish_m   (finish_m   ),
	.data_m_out (data_m_out ),
	.data_s_out (data_s_out ),
	.data_valid_s (data_valid_s )
);

endmodule // SPI_loopback_tb
