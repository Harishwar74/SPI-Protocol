`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2023 15:53:06
// Design Name: 
// Module Name: spi_main
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
module hamming_encoder(
  input [3:0] data_in,
  output [6:0] encoded_data
);

  wire p0 = data_in[0] ^ data_in[2] ^ data_in[3];
  wire p1 = data_in[0] ^ data_in[1] ^ data_in[3];
  wire p2 = data_in[1] ^ data_in[2] ^ data_in[0];

  assign encoded_data = {p0, p1, data_in[3], p2, data_in[2], data_in[1], data_in[0]};

endmodule

module spi_master
#(
	parameter	CLK_FREQUENCE	= 5_000_000	,	//system clk frequence
				SPI_FREQUENCE	= 5_000_000	,	//spi clk frequence
				//DATA_WIDTH_UE		= 8	,	//serial word length
				DATA_WIDTH    = 7,
				CPOL			= 0	,	//SPI mode selection (mode 0 default)
				CPHA			= 0	 //CPOL = clock polarity, CPHA = clock phase
)
(input clk,	//system clk
	input rst_n,
	input [DATA_WIDTH-1:0] data_in,
	input start,
	input miso	,
	output	reg	sclk, //serial clock
	output	reg cs_n,
	output	mosi,
	output	reg	finish,	
	output	reg [DATA_WIDTH-1:0] data_out);
//reg [DATA_WIDTH-1:0] data_in;
//reg [DATA_WIDTH-1:0] data_out;
//reg err;

//hamming_encoder em(data_in_un_encry, data_in);

localparam	FREQUENCE_CNT = CLK_FREQUENCE/SPI_FREQUENCE - 1	,
			SHIFT_WIDTH	= log2(DATA_WIDTH)					,
			CNT_WIDTH = log2(FREQUENCE_CNT)				;

localparam	IDLE = 3'b000,
			LOAD = 3'b001,
			SHIFT =	3'b010,
			DONE = 3'b100;

reg	[2:0] cstate;
reg	[2:0] nstate;	
reg	clk_cnt_en;
reg	sclk_a;	
reg	sclk_b;	
wire sclk_posedge;	
wire sclk_negedge;	
wire shift_en;
wire sampl_en;	
reg	[CNT_WIDTH-1:0] clk_cnt;	
reg	[SHIFT_WIDTH-1:0] shift_cnt;	
reg	[DATA_WIDTH-1:0] data_reg;	
//the counter to generate the sclk
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		clk_cnt <= 'd0;
	else if (clk_cnt_en) 
		if (clk_cnt == FREQUENCE_CNT) 
			clk_cnt <= 'd0;
		else
			clk_cnt <= clk_cnt + 1'b1;
	else
		clk_cnt <= 'd0;
end
//generate the sclk
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sclk <= CPOL;
	else if (clk_cnt_en) 
		if (clk_cnt == FREQUENCE_CNT)  	
			sclk <= ~sclk; 
		else 
			sclk <= sclk;
	else
		sclk <= CPOL;
end

//to capture the edge of sclk
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sclk_a <= CPOL;
		sclk_b <= CPOL;
	end else if (clk_cnt_en) begin
		sclk_a <= sclk;
		sclk_b <= sclk_a;
	end
end

assign sclk_posedge = ~sclk_b & sclk_a;
assign sclk_negedge = ~sclk_a & sclk_b;

//enabling sampling and shifting
generate
	case (CPHA)
		0: assign sampl_en = sclk_posedge;
		1: assign sampl_en = sclk_negedge;
		default: assign sampl_en = sclk_posedge;
	endcase
endgenerate

generate
 	case (CPHA)
		0: assign shift_en = sclk_negedge;
 		1: assign shift_en = sclk_posedge;
		default: assign shift_en = sclk_posedge;
	endcase
endgenerate

// initial states or assigning next state
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		cstate <= IDLE;
	else 
		cstate <= nstate;
end
//choosing next states
always @(*) begin
	case (cstate)
	IDLE	: nstate = start ? LOAD : IDLE;
	LOAD	: nstate = SHIFT;
	SHIFT	: nstate = (shift_cnt == DATA_WIDTH) ? DONE : SHIFT;
	DONE	: nstate = IDLE;
	default: nstate = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		clk_cnt_en	<= 1'b0	;
		data_reg	<= 'd0	;
		cs_n		<= 1'b1	;
		shift_cnt	<= 'd0	;
		finish <= 1'b0	;
	end else begin
		case (nstate)
			IDLE	: begin
			clk_cnt_en	<= 1'b0	;
			data_reg	<= 'd0	;
			cs_n		<= 1'b1	;
			shift_cnt	<= 'd0	;
			finish 		<= 1'b0	;
			end
			LOAD	: begin
			clk_cnt_en	<= 1'b1		;
			data_reg	<= data_in	;
			cs_n		<= 1'b0		;
			shift_cnt	<= 'd0		;
			finish 		<= 1'b0		;
			end
			SHIFT	: begin
			if (shift_en) begin
				shift_cnt	<= shift_cnt + 1'b1 ;
				data_reg	<= {data_reg[DATA_WIDTH-2:0],1'b0};
			end else begin
				shift_cnt	<= shift_cnt	;
				data_reg	<= data_reg		;
			end
				clk_cnt_en	<= 1'b1	;
				cs_n		<= 1'b0	;
				finish 		<= 1'b0	;
			end
			DONE	: begin
				clk_cnt_en	<= 1'b0	;
				data_reg	<= 'd0	;
				cs_n		<= 1'b1	;
				data_reg	<= 'd0	;
				finish 		<= 1'b1	;
			end
			default	: begin
				clk_cnt_en	<= 1'b0	;
				data_reg	<= 'd0	;
				cs_n		<= 1'b1	;
				data_reg	<= 'd0	;
				finish 		<= 1'b0	;
			end
		endcase
	end
end
//mosi output 
assign mosi = data_reg[DATA_WIDTH-1];
//sample data from the miso line
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		data_out <= 'd0;
	else if (sampl_en) 
		data_out <= {data_out[DATA_WIDTH-1:0],miso};
	else
		data_out <= data_out;
end
//the function to get the width of data 
function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

endmodule

//SLAVE
module SPI_Slave
#(parameter	CLK_FREQUENCE = 5_000_000,
				SPI_FREQUENCE = 5_000_000,
				//DATA_WIDTH_UE = 8,
				DATA_WIDTH = 7,				
				CPOL = 1,
				CPHA = 1)
(input clk,	
	input rst_n,
	input [DATA_WIDTH-1:0] data_in,	
	input sclk,
	input cs_n,
	input mosi,
	output miso,
	output data_valid,	
	output reg [DATA_WIDTH-1:0]data_out	);

localparam	SFIFT_NUM = log2(DATA_WIDTH);
//reg [DATA_WIDTH-1:0] data_in;
//reg [DATA_WIDTH-1:0] data_out;
//reg err;

reg	[DATA_WIDTH-1:0] data_reg;
reg	[ SFIFT_NUM-1:0] sampl_num;	
reg sclk_a;
reg	sclk_b;	
wire sclk_posedge;
wire sclk_negedge;
reg	cs_n_a;	
reg	cs_n_b;
wire cs_n_negedge;
wire shift_en;
wire sampl_en;	

//to capture the edge of sclk
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sclk_a <= CPOL;
		sclk_b <= CPOL;
	end else if (!cs_n) begin
		sclk_a <= sclk;
		sclk_b <= sclk_a;
	end
end

assign sclk_posedge = ~sclk_b & sclk_a;
assign sclk_negedge = ~sclk_a & sclk_b;

//to capture the edge of sclk
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cs_n_a	<= 1'b1;
		cs_n_b	<= 1'b1;
	end else begin
		cs_n_a	<= cs_n		;
		cs_n_b	<= cs_n_a	;
	end
end

assign cs_n_negedge = ~cs_n_a & cs_n_b;

//enabling the shifting and sampleing
generate
	case (CPHA)
		0: assign sampl_en = sclk_posedge;
		1: assign sampl_en = sclk_negedge;
		default: assign sampl_en = sclk_posedge;
	endcase
endgenerate

generate
 	case (CPHA)
		0: assign shift_en = sclk_negedge;
 		1: assign shift_en = sclk_posedge;
		default: assign shift_en = sclk_posedge;
	endcase
endgenerate

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		data_reg <= 'd0;
	else if(cs_n_negedge)
		data_reg <= data_in;
	else if (!cs_n & shift_en) 
		data_reg <= {data_reg[DATA_WIDTH-2:0],1'b0};
	else
		data_reg <= data_reg;
end

assign miso = !cs_n ? data_reg[DATA_WIDTH-1] : 1'd0;

//sample data from the mosi line
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		data_out <= 'd0;
	else if (!cs_n & sampl_en) 
		data_out <= {data_out[DATA_WIDTH-2:0],mosi};
	else
		data_out <= data_out;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sampl_num <= 'd0;
	else if (cs_n)
		sampl_num <= 'd0;
	else if (!cs_n & sampl_en) 
		if (sampl_num == DATA_WIDTH)
			sampl_num <= 'd1;
		else
			sampl_num <= sampl_num + 1'b1;
	else
		sampl_num <= sampl_num;
end
//data validstion
assign data_valid = sampl_num == DATA_WIDTH;


function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

endmodule

module SPI_loopback
#(parameter	CLK_FREQUENCE = 5_000_000,	
SPI_FREQUENCE = 5_000_000,	//spi clk frequence
DATA_WIDTH_UE = 4,	
DATA_WIDTH = 7,
CPOL = 0,	
CPHA = 0)
(input clk,
	input rst_n,
	input [DATA_WIDTH_UE-1:0] data_m_in	,
	input [DATA_WIDTH_UE-1:0] data_s_in	,
	input start_m,
	output finish_m	,
	output [DATA_WIDTH-1:0]	data_m_out,
	output [DATA_WIDTH-1:0]	data_s_out,  
	output data_valid_s);

wire miso;
wire mosi;
wire cs_n;
wire sclk;

wire [14:0]data_m_in_e;
wire [14:0]data_s_in_e;
//wire [14:0]data_m_out_e;
//wire [14:0]data_s_out_e;

hamming_encoder em1(data_m_in, data_m_in_e);
hamming_encoder es1(data_s_in, data_s_in_e);

spi_master 
#(.CLK_FREQUENCE (CLK_FREQUENCE ),.SPI_FREQUENCE (SPI_FREQUENCE ),.DATA_WIDTH(DATA_WIDTH),.CPOL(CPOL),.CPHA(CPHA))
u_spi_master(.clk(clk),.rst_n(rst_n),.data_in(data_m_in_e),.start(start_m),.miso(miso),.sclk(sclk),.cs_n(cs_n),.mosi(mosi),.finish(finish_m),.data_out(data_m_out ));

SPI_Slave 
#(.CLK_FREQUENCE (CLK_FREQUENCE ),
.SPI_FREQUENCE (SPI_FREQUENCE ),
.DATA_WIDTH (DATA_WIDTH),
.CPOL (CPOL),
.CPHA (CPHA))

u_SPI_Slave(.clk(clk),.rst_n(rst_n),.data_in(data_s_in_e),
.sclk(sclk),.cs_n(cs_n),.mosi(mosi),.miso(miso),.data_valid (data_valid_s ),.data_out(data_s_out));

always@(negedge data_valid_s); begin
//hamming_decoder hm(data_out_m, data_m_out_ue);
//hamming_decoder hs(data_out_s, data_s_out_ue);
end

endmodule

