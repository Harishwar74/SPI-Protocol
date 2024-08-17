`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2023 09:34:18
// Design Name: 
// Module Name: hamming_code_decoder_test
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


module test_de();
reg [6:0]di;
wire [3:0]do;
wire e;
hamming_decoder uut(di,do,e);
initial begin
di=0; #10
di=7'b0011001;
end
endmodule
